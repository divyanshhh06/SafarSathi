const { io } = require('socket.io-client');
const { decompressPayload } = require('./payloadCompressor');

// Connect to your WebSocket server
const socket = io('http://localhost:3000');

socket.on('connect', () => {
  console.log('📱 Commuter client connected to server!');

  // 1. Join Route 101 stream
  const routeId = '101';
  socket.emit('join_route', routeId);
  console.log(`📡 Subscribed to stream: route:${routeId}`);

  // 2. Fetch latest position from Redis cache upon connecting
  socket.emit('get_initial_position', 'BUS-101', (initialData) => {
    if (initialData) {
      console.log('📍 Initial location fetched from Redis:', initialData);
    } else {
      console.log('ℹ️ No active position cached yet in Redis.');
    }
  });
});

// 3. Listen for live compressed broadcasts from the driver
socket.on('u', (rawTuple) => {
  // Decompress array [lat, lng, busId, speed, routeId] into an object
  const { lat, lng, busId, speed, routeId } = decompressPayload(rawTuple);

  // Trigger marker/UI update
  updateMapMarker(busId, lat, lng, speed, routeId);
});

function updateMapMarker(busId, lat, lng, speed, routeId) {
  console.log(`📍 [MAP MARKER UPDATED] Bus: ${busId} | Coords: (${lat}, ${lng}) | Speed: ${speed} km/h | Route: ${routeId}`);
}