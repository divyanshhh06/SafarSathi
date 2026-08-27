const { io } = require('socket.io-client');

const SOCKET_URL = 'http://localhost:3000';

// 1. Simulate Commuter Client
const commuterSocket = io(SOCKET_URL);

commuterSocket.on('connect', () => {
  console.log('📱 Commuter connected to socket server');
  
  // Join Route 101 room
  commuterSocket.emit('join_route', '101');

  // Request initial position from Redis cache
  commuterSocket.emit('get_initial_position', 'BUS-101', (initialData) => {
    console.log('📍 [Commuter] Received initial position from Redis:', initialData);
  });
});

// Listen for broadcasted updates on route 101
commuterSocket.on('u', (payload) => {
  const [lat, lng, busId, speed, routeId] = payload;
  console.log(`⚡ [Commuter Received Live Update] Bus: ${busId} | Lat: ${lat}, Lng: ${lng} | Speed: ${speed} km/h`);
});

// 2. Simulate Driver Client emitting coordinates after 1 second
setTimeout(() => {
  const driverSocket = io(SOCKET_URL);

  driverSocket.on('connect', () => {
    console.log('🚌 Driver connected');
    
    // Payload format: [lat, lng, busId, speed, routeId]
    const payload = [12.9716, 77.5946, 'BUS-101', 45, '101'];
    
    console.log('📤 [Driver] Emitting location update...');
    driverSocket.emit('d_up', payload);
  });
}, 1000);