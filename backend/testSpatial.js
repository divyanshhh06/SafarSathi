const { updateBusLocation, getBusLocation, redis } = require('./redisClient');

async function testSpatialCache() {
  console.log('🧪 Testing Redis Spatial Engine...\n');

  const busId = 'BUS-402';
  const testLat = 12.9716; // Example latitude (e.g., Bengaluru)
  const testLng = 77.5946; // Example longitude

  // 1. Test Writing Coordinate
  console.time('⏱️ GEOADD Time');
  await updateBusLocation(busId, testLat, testLng);
  console.timeEnd('⏱️ GEOADD Time');
  console.log(`✅ Bus ${busId} location written to RAM.`);

  // 2. Test Fetching Coordinate
  console.time('⏱️ GEOPOS Fetch Time');
  const result = await getBusLocation(busId);
  console.timeEnd('⏱️ GEOPOS Fetch Time');

  console.log('📍 Retrieved Data from Redis:', result);

  // Gracefully close connection
  redis.disconnect();
}

testSpatialCache();