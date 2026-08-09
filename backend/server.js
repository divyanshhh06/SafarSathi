
require('dotenv').config();
const express = require('express');
const { Server } = require('socket.io');
const http = require('http');
const { updateBusLocation, getBusLocation } = require('./redisClient');

const app = express();
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'SafarSathi BE-1', time: new Date() });
});

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

io.on('connection', (socket) => {
  console.log(`🔌 Client connected: ${socket.id}`);

  // Commuter joins a specific bus or route stream
  socket.on('join_route', (routeId) => {
    socket.join(`route:${routeId}`);
    console.log(`📡 Client ${socket.id} joined route:${routeId}`);
  });

  // REST or Socket fallback: fast sub-100ms lookup from Redis
  socket.on('get_initial_position', async (busId, callback) => {
    const coords = await getBusLocation(busId);
    if (typeof callback === 'function') {
      callback(coords);
    }
  });

  // Driver sends live location
  socket.on('d_up', async (compressedPayload) => {
    // Unpack compressed array payload: [lat, lng, busId, speed, routeId]
    if (!Array.isArray(compressedPayload) || compressedPayload.length < 5) return;
    const [lat, lng, busId, speed, routeId] = compressedPayload;

    // 1. Write to Redis spatial cache (non-blocking)
    updateBusLocation(busId, lat, lng).catch(console.error);

    // 2. Broadcast compressed array payload directly to room
    io.to(`route:${routeId}`).emit('u', compressedPayload);
  });

  socket.on('disconnect', () => {
    console.log(`❌ Client disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`🚀 Engine running on port ${PORT}`));
