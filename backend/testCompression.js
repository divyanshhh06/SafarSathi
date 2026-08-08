const { compressPayload } = require('./payloadCompressor');

// 1. Standard Verbose JSON Object (Unoptimized)
const verbosePayload = {
  busId: 'BUS-101',
  latitude: 12.971598,
  longitude: 77.594562,
  speed: 42.4,
  routeId: 'ROUTE-101',
  timestamp: Date.now()
};

// 2. Compressed Array Tuple (Optimized)
const compressedTuple = compressPayload(
  verbosePayload.latitude,
  verbosePayload.longitude,
  verbosePayload.busId,
  verbosePayload.speed,
  verbosePayload.routeId
);

// Calculate byte sizes in memory
const verboseSize = Buffer.byteLength(JSON.stringify(verbosePayload));
const compressedSize = Buffer.byteLength(JSON.stringify(compressedTuple));
const reduction = (((verboseSize - compressedSize) / verboseSize) * 100).toFixed(2);

console.log('📊 PAYLOAD OPTIMIZATION BENCHMARK');
console.log('-----------------------------------');
console.log('🔴 Verbose JSON Payload:', JSON.stringify(verbosePayload));
console.log(`   Size: ${verboseSize} bytes\n`);

console.log('🟢 Compressed Array Tuple:', JSON.stringify(compressedTuple));
console.log(`   Size: ${compressedSize} bytes\n`);

console.log(`⚡ Bandwidth Saved: ${reduction}% reduction`);
console.log(`🎯 Target (< 1000 bytes): ${compressedSize < 1000 ? 'PASSED ✅' : 'FAILED ❌'}`);