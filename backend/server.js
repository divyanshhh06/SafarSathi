require('dotenv').config();
const express = require('express');
const { Server } = require('socket.io');
const http = require('http');
const fs = require('fs');
const path = require('path');
const { updateBusLocation, getBusLocation } = require('./redisClient');

const app = express();
app.use(express.json());

// Enable CORS for Flutter web / desktop / emulators
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

const PORT = process.env.PORT || 3000;
const DATA_DIR = path.join(__dirname, '..', 'Data');

// Load GTFS stops data for all 17 Punjab districts
const districts = new Map();

function slugify(name) {
  return name
    .toLowerCase()
    .replace(/\(([^)]+)\)/g, '$1')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
}

// Nearest-Neighbor sorting algorithm to form clean sequential highway routes
function sortStopsSequentially(stops) {
  if (!stops || stops.length <= 2) return stops;
  const remaining = [...stops];
  const sorted = [remaining.shift()];

  while (remaining.length > 0) {
    const current = sorted[sorted.length - 1];
    let nearestIdx = 0;
    let minDistance = Infinity;

    for (let i = 0; i < remaining.length; i++) {
      const candidate = remaining[i];
      const dist = Math.hypot(
        candidate.latitude - current.latitude,
        candidate.longitude - current.longitude
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearestIdx = i;
      }
    }

    sorted.push(remaining.splice(nearestIdx, 1)[0]);
  }
  return sorted;
}

function loadAllStops() {
  if (!fs.existsSync(DATA_DIR)) return;
  const folders = fs.readdirSync(DATA_DIR, { withFileTypes: true })
    .filter((entry) => entry.isDirectory());

  for (const folder of folders) {
    const filePath = path.join(DATA_DIR, folder.name, 'stops.json');
    if (!fs.existsSync(filePath)) continue;

    try {
      const raw = fs.readFileSync(filePath, 'utf8');
      const rawStops = JSON.parse(raw);
      
      const parsedStops = rawStops.map((s, idx) => ({
        id: s.id || s.stop_id || `stop_${idx}`,
        name: s.name || s.stop_name || 'Bus Stop',
        latitude: Number(s.latitude || s.lat || 0),
        longitude: Number(s.longitude || s.lng || 0),
        city: folder.name,
        state: 'Punjab',
        shelter: Boolean(s.shelter),
      })).filter(s => s.latitude > 0 && s.longitude > 0);

      // Sort stops into a continuous linear highway path
      const sortedStops = sortStopsSequentially(parsedStops);

      districts.set(slugify(folder.name), {
        slug: slugify(folder.name),
        name: folder.name,
        stops: sortedStops,
      });
    } catch (err) {
      console.error(`Failed to load stops for ${folder.name}:`, err.message);
    }
  }

  console.log(`Loaded GTFS stops for ${districts.size} Punjab districts`);
}

loadAllStops();

// --- REST API Endpoints ---

app.get('/', (req, res) => {
  res.json({
    service: 'SafarSathi BE-1 Tracking & GTFS Engine',
    status: 'running',
    port: PORT,
    districtsLoaded: districts.size,
    endpoints: {
      health: '/health',
      districts: '/api/districts',
      stops: '/api/stops',
      routes: '/api/routes',
    },
    timestamp: new Date().toISOString(),
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', time: new Date() });
});

app.get('/api/districts', (req, res) => {
  const list = Array.from(districts.values()).map(d => ({
    slug: d.slug,
    name: d.name,
    stopCount: d.stops.length,
  }));
  res.json(list);
});

app.get('/api/stops', (req, res) => {
  const allStops = [];
  for (const d of districts.values()) {
    allStops.push(...d.stops);
  }
  res.json(allStops);
});

app.get('/api/stops/:district', (req, res) => {
  const slug = slugify(req.params.district);
  const district = districts.get(slug);
  if (!district) {
    return res.status(404).json({ error: 'District not found' });
  }
  res.json(district.stops);
});

app.get('/api/routes', (req, res) => {
  const routes = [];
  for (const d of districts.values()) {
    routes.push({
      id: `route-${d.slug}`,
      name: `${d.name} Intercity Line`,
      stops: d.stops,
      path: d.stops.map(s => [s.latitude, s.longitude])
    });
  }
  res.json(routes);
});

// --- WebSocket Real-Time Telemetry Engine ---

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

io.on('connection', (socket) => {
  socket.on('join_route', (routeId) => {
    socket.join(`route:${routeId}`);
  });

  socket.on('get_initial_position', async (busId, callback) => {
    const coords = await getBusLocation(busId);
    if (typeof callback === 'function') {
      callback(coords);
    }
  });

  // Driver sends live location
  socket.on('d_up', async (compressedPayload) => {
    if (!Array.isArray(compressedPayload) || compressedPayload.length < 5) return;

    // Unpack compressed array payload: [lat, lng, busId, speed, routeId]
    const [lat, lng, busId, speed, routeId] = compressedPayload;
    console.log(`📡 Driver Ping [${busId}] on route [${routeId}]: (${lat.toFixed(4)}, ${lng.toFixed(4)}) at ${speed} km/h`);

    // 1. Write to spatial cache (non-blocking)
    updateBusLocation(busId, lat, lng).catch(console.error);

    // 2. Broadcast compressed array payload to room & globally
    io.to(`route:${routeId}`).emit('u', compressedPayload);
    io.emit('u', compressedPayload);
  });
});

server.listen(PORT, () => {
  console.log(`Engine running on port ${PORT}`);
});