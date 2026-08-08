const { updateBusLocation, getBusLocation, redis } = require('./redisClient');

async function benchmarkLatency() {
  console.log('⏱️ STARTING REDIS SPATIAL LATENCY BENCHMARK...\n');

  const busId = 'BUS-PERF-TEST';
  const testLat = 12.9716;
  const testLng = 77.5946;

  // Pre-seed test location into Redis
  await updateBusLocation(busId, testLat, testLng);

  const iterations = 10;
  const timings = [];

  console.log(`Running ${iterations} sequential spatial fetches...\n`);

  for (let i = 1; i <= iterations; i++) {
    const start = performance.now();
    await getBusLocation(busId);
    const duration = performance.now() - start;
    timings.push(duration);
    console.log(`  Fetch #${i}: ${duration.toFixed(3)} ms`);
  }

  const avgLatency = timings.reduce((a, b) => a + b, 0) / iterations;
  const minLatency = Math.min(...timings);
  const maxLatency = Math.max(...timings);

  console.log('\n📊 BENCHMARK RESULTS');
  console.log('-----------------------------------');
  console.log(`   Min Latency: ${minLatency.toFixed(3)} ms`);
  console.log(`   Max Latency: ${maxLatency.toFixed(3)} ms`);
  console.log(`   Avg Latency: ${avgLatency.toFixed(3)} ms`);
  console.log(`🎯 Sub-10ms Local Target: ${avgLatency < 10 ? 'PASSED ✅' : 'FAILED ❌'}`);

  redis.disconnect();
}

benchmarkLatency();