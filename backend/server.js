require('dotenv').config();

const connectDB = require('./db');
connectDB();

// server.js
const express = require('express');
const cors = require('cors');
const { Server } = require('socket.io');
const http = require('http');
const { updateBusLocation, getBusLocation } = require('./redisClient');

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// BE-2 API routes
app.use('/api/admin', require('./routes/auth'));
app.use('/api/stops', require('./routes/stops'));
app.use('/api/routes', require('./routes/routes'));
app.use('/api/buses', require('./routes/buses'));
app.use('/api/drivers', require('./routes/drivers'));
app.use('/api/schedules', require('./routes/schedules'));
app.use('/api/gtfs', require('./routes/gtfs'));
app.use('/api/sms', require('./routes/sms'));

const server = http.createServer(app);

const io = new Server(server, {
  cors: { origin: '*' }
});

io.on('connection', (socket) => {
  // Commuter joins a specific bus or route stream
  socket.on('join_route', (routeId) => {
    socket.join(`route:${routeId}`);
  });

  // REST or Socket fallback: fast sub-100ms lookup from Redis
  socket.on('get_initial_position', async (busId, callback) => {
    const coords = await getBusLocation(busId);
    callback(coords);
  });

  // Driver sends live location
  socket.on('d_up', async (compressedPayload) => {
    // Unpack compressed array payload: [lat, lng, busId, speed, routeId]
    const [lat, lng, busId, speed, routeId] = compressedPayload;

    // 1. Write to Redis spatial cache (non-blocking)
    updateBusLocation(busId, lat, lng).catch(console.error);

    // 2. Broadcast compressed array payload directly to room
    io.to(`route:${routeId}`).emit('u', compressedPayload);
  });
});

// --- NEW CODE STARTS HERE ---
const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
    console.log(`Engine running on port ${PORT}`);
});