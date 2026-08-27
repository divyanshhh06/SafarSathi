const { io } = require('socket.io-client');
const { compressPayload } = require('./payloadCompressor');

const SERVER_URL = 'http://localhost:3000';
const NUM_DRIVERS = 8; // Simulating 8 concurrent drivers
const UPDATE_INTERVAL_MS = 1500; // Update every 1.5 seconds

// Base coordinates
const baseLat = 12.9716;
const baseLng = 77.5946;
const routeId = '101';

const sockets = [];
let totalEmits = 0;

console.log(`🚀 STARTING STRESS TEST: ${NUM_DRIVERS} Active Drivers emitting every ${UPDATE_INTERVAL_MS}ms...\n`);

for (let i = 1; i <= NUM_DRIVERS; i++) {
  const busId = `BUS-${100 + i}`;
  const socket = io(SERVER_URL);

  let lat = baseLat + (i * 0.002);
  let lng = baseLng + (i * 0.002);

  socket.on('connect', () => {
    console.log(`🟢 Driver ${busId} connected [Socket ID: ${socket.id}]`);

    // Loop continuous location updates
    setInterval(() => {
      // Small coordinate drift simulation
      lat += (Math.random() - 0.48) * 0.001;
      lng += (Math.random() - 0.48) * 0.001;
      const speed = Math.floor(Math.random() * 25) + 25;

      const payload = compressPayload(lat, lng, busId, speed, routeId);
      socket.emit('d_up', payload);
      
      totalEmits++;
    }, UPDATE_INTERVAL_MS);
  });

  sockets.push(socket);
}

// Log status summary every 5 seconds
setInterval(() => {
  console.log(`\n⚡ [STRESS STATUS] Active Drivers: ${NUM_DRIVERS} | Total Frames Broadcasted: ${totalEmits}`);
}, 5000);