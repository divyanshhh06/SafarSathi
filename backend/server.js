require('dotenv').config();
const express = require('express');
const { Server } = require('socket.io');
const http = require('http');
const https = require('https');
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

// ─── OSRM Road Geometry Cache ──────────────────────────────────────
const roadGeometryCache = new Map(); // routeId → [[lat,lng],...]

async function fetchOSRMRoadGeometry(waypoints) {
  const coordStr = waypoints.map(([lat, lng]) => `${lng},${lat}`).join(';');
  const url = `https://router.project-osrm.org/route/v1/driving/${coordStr}?overview=full&geometries=geojson`;
  console.log(`🗺️  OSRM fetching ${waypoints.length} waypoints…`);
  return new Promise((resolve) => {
    const req = https.get(url, { timeout: 15000 }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const data = JSON.parse(body);
          if (data.code === 'Ok' && data.routes && data.routes[0]) {
            const coords = data.routes[0].geometry.coordinates.map(c => [c[1], c[0]]);
            console.log(`✅ OSRM returned ${coords.length} road points`);
            return resolve({ success: true, coords, source: 'OSRM' });
          }
        } catch (e) { console.warn('OSRM parse error:', e.message); }
        console.warn('OSRM: no valid route, using fallback');
        resolve({ success: false, coords: waypoints, source: 'FALLBACK' });
      });
    });
    req.on('error', () => resolve({ success: false, coords: waypoints, source: 'FALLBACK' }));
    req.on('timeout', () => { req.destroy(); resolve({ success: false, coords: waypoints, source: 'FALLBACK' }); });
  });
}

const PRESET_ROUTE_STOPS = {
  ROUTE_4B: [[31.6340,74.8723],[31.6312,74.8765],[31.6285,74.8790],[31.6200,74.8765],[31.6215,74.8801],[31.6150,74.8920]],
  ROUTE_101: [[30.9100,75.8510],[30.9030,75.8080],[30.8920,75.8320]],
  ROUTE_202: [[31.3200,75.5800],[31.3260,75.5760],[31.3110,75.6120]]
};

// --- REST API Endpoints ---
const PUBLIC_DIR = fs.existsSync(path.join(__dirname, 'public'))
  ? path.join(__dirname, 'public')
  : path.join(__dirname, '..', 'public');

app.use(express.static(PUBLIC_DIR));

// Load BE-3 Geospatial & ETA Engine
let etaEngine = null;
let db = null;
try {
  etaEngine = require('../src/services/etaEngine');
  db = require('../src/data/db');
  console.log('✅ BE-3 ETA Engine & Database loaded successfully');
} catch (e) {
  console.warn('⚠️ Could not load BE-3 ETA Engine:', e.message);
}

// --- Web Interface Root & REST API Endpoints ---

// GET /api/road-geometry/:routeId → returns OSRM-snapped road coords + stop indices
app.get('/api/road-geometry/:routeId', async (req, res) => {
  const routeId = req.params.routeId;

  if (roadGeometryCache.has(routeId)) {
    return res.json(roadGeometryCache.get(routeId));
  }

  const stops = PRESET_ROUTE_STOPS[routeId];
  if (!stops) {
    return res.status(404).json({ error: 'Route not found' });
  }

  try {
    const result = await fetchOSRMRoadGeometry(stops);
    // Find which coord indices correspond to each stop (snap to nearest point)
    const stopIndices = stops.map(([slat, slng]) => {
      let best = 0, bestDist = Infinity;
      result.coords.forEach(([clat, clng], i) => {
        const d = Math.hypot(clat - slat, clng - slng);
        if (d < bestDist) { bestDist = d; best = i; }
      });
      return best;
    });

    const payload = {
      routeId,
      source: result.source,
      coords: result.coords,         // full road geometry [[lat,lng],...]
      stopIndices,                   // index into coords for each stop
      totalPoints: result.coords.length
    };
    roadGeometryCache.set(routeId, payload);
    res.json(payload);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/', (req, res) => {
  const indexHtml = path.join(PUBLIC_DIR, 'index.html');
  if (fs.existsSync(indexHtml)) {
    return res.sendFile(indexHtml);
  }
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/api/info', (req, res) => {
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
      etaBus: '/api/eta/bus/:busId',
      etaRoute: '/api/eta/route/:routeId'
    },
    timestamp: new Date().toISOString(),
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', time: new Date() });
});

app.get('/api/eta/bus/:busId', (req, res) => {
  if (!etaEngine) return res.status(503).json({ error: 'ETA Engine unavailable' });
  try {
    const etas = etaEngine.calculateBusETAs(req.params.busId);
    res.json({ success: true, data: etas });
  } catch (err) {
    res.status(404).json({ success: false, message: err.message });
  }
});

app.get('/api/eta/route/:routeId', (req, res) => {
  if (!etaEngine) return res.status(503).json({ error: 'ETA Engine unavailable' });
  try {
    const etas = etaEngine.getRouteETAs(req.params.routeId);
    res.json({ success: true, count: etas.length, data: etas });
  } catch (err) {
    res.status(404).json({ success: false, message: err.message });
  }
});

app.post('/api/crowd/report', (req, res) => {
  const { busId, rating } = req.body;
  if (db && typeof db.addCrowdReport === 'function') {
    const report = db.addCrowdReport(busId, rating);
    return res.json({ success: true, report });
  }
  res.json({ success: true, message: 'Report received' });
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
    socket.join(`route_${routeId}`);

    // Send initial ETA update to client if available
    if (etaEngine) {
      try {
        const routeETAs = etaEngine.getRouteETAs(routeId);
        socket.emit('initial_eta_update', {
          routeId,
          buses: routeETAs
        });
      } catch (_) {}
    }
  });

  socket.on('get_initial_position', async (busId, callback) => {
    const coords = await getBusLocation(busId);
    if (typeof callback === 'function') {
      callback(coords);
    }
  });

  // Driver sends live location
  // Web Simulator Driver Stream Handler
  socket.on('driver_ping_compressed', async (compressedData) => {
    if (!Array.isArray(compressedData) || compressedData.length < 5) return;
    const [lat, lng, busId, speed, bearing, timestamp] = compressedData;
    const routeId = 'ROUTE_4B';

    // Derive routeId from db if available, else from busId convention
    let routeId = 'ROUTE_4B';
    if (db) {
      const bus = db.getBusById(busId);
      if (bus && bus.routeId) routeId = bus.routeId;
    }
    // Also accept routeId as 7th element in payload (future use)
    if (compressedData[6]) routeId = compressedData[6];

    if (db) db.updateBusLocation(busId, lat, lng, speed, bearing || 0);
    updateBusLocation(busId, lat, lng).catch(() => {});

    let busETAs = null;
    if (etaEngine) {
      try {
        busETAs = etaEngine.calculateBusETAs(busId);
      } catch (_) {}
    }

    const payloadSizeBytes = Buffer.byteLength(JSON.stringify(compressedData), 'utf8');

    // 1. Broadcast to Web UI (Leaflet Map)
    const broadcastPayload = {
      busId,
      routeId,
      location: { lat, lng, speed, bearing: bearing || 0 },
      etas: busETAs ? busETAs.stops : [],
      bandwidthUsage: {
        bytesReceived: payloadSizeBytes,
        kilobytesReceived: parseFloat((payloadSizeBytes / 1024).toFixed(3)),
        isHyperCompressed: payloadSizeBytes < 1024
      },
      timestamp: timestamp || Date.now()
    };

    io.to(`route_${routeId}`).emit('bus_location_broadcast', broadcastPayload);
    io.emit('bus_location_broadcast', broadcastPayload);

    // 2. Also emit 'u' for Flutter clients
    const flutterPayload = [lat, lng, busId, speed, routeId];
    io.to(`route:${routeId}`).emit('u', flutterPayload);
    io.emit('u', flutterPayload);
  });

  // Flutter Driver Location Update Handler
  socket.on('d_up', async (compressedPayload) => {
    if (!Array.isArray(compressedPayload) || compressedPayload.length < 5) return;

    // Unpack compressed array payload: [lat, lng, busId, speed, routeId]
    const [lat, lng, busId, speed, routeId] = compressedPayload;
    console.log(`📡 Driver Ping [${busId}] on route [${routeId}]: (${lat.toFixed(4)}, ${lng.toFixed(4)}) at ${speed} km/h`);

    // 1. Write to spatial cache (non-blocking)
    if (db) db.updateBusLocation(busId, lat, lng, speed, 0);
    updateBusLocation(busId, lat, lng).catch(console.error);

    // 2. Broadcast compressed array payload to room & globally
    let busETAs = null;
    if (etaEngine) {
      try {
        busETAs = etaEngine.calculateBusETAs(busId);
      } catch (_) {}
    }

    // 1. Broadcast compressed array payload to Flutter room & globally
    io.to(`route:${routeId}`).emit('u', compressedPayload);
    io.emit('u', compressedPayload);

    // 2. Also emit to Web UI
    const payloadSizeBytes = Buffer.byteLength(JSON.stringify(compressedPayload), 'utf8');
    const webPayload = {
      busId,
      routeId,
      location: { lat, lng, speed, bearing: 0 },
      etas: busETAs ? busETAs.stops : [],
      bandwidthUsage: {
        bytesReceived: payloadSizeBytes,
        kilobytesReceived: parseFloat((payloadSizeBytes / 1024).toFixed(3)),
        isHyperCompressed: payloadSizeBytes < 1024
      },
      timestamp: Date.now()
    };
    io.to(`route_${routeId}`).emit('bus_location_broadcast', webPayload);
    io.emit('bus_location_broadcast', webPayload);
  });
});

server.listen(PORT, () => {
  console.log(`Engine running on port ${PORT}`);
  console.log(`=======================================================`);
  console.log(`🚀 SafarSathi Backend & Web Portal running on port ${PORT}`);
  console.log(`🌐 Open http://localhost:${PORT} in your browser`);
  console.log(`=======================================================`);
});