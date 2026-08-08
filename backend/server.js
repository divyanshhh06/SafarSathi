
require('dotenv').config();
// server.js
const express = require('express');
const { Server } = require('socket.io');
const http = require('http');
const { updateBusLocation, getBusLocation } = require('./redisClient');

const app = express();
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

server.listen(3000, () => console.log('Engine running on port 3000'));