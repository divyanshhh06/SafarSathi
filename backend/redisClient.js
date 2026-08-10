require('dotenv').config();
const Redis = require('ioredis');

const memoryCache = new Map();
let isRedisConnected = false;

const isUpstash = /upstash\.io$/.test(
  (process.env.REDIS_HOST || '').replace(/^https?:\/\//, '')
);

const redis = new Redis({
  host: (process.env.REDIS_HOST || '127.0.0.1').replace(/^https?:\/\//, ''),
  port: process.env.REDIS_PORT || 6379,
  password: process.env.REDIS_PASSWORD,
  ...(isUpstash ? { tls: {} } : {}),
  maxRetriesPerRequest: 1,
  retryStrategy(times) {
    if (times > 2) {
      console.warn('⚠️ Redis unreachable, using in-memory spatial cache.');
      return null;
    }
    return 1000;
  }
});

redis.on('connect', () => {
  isRedisConnected = true;
  console.log('⚡ Redis Spatial Cache Connected Successfully');
});

redis.on('error', (err) => {
  isRedisConnected = false;
  console.error('❌ Redis Connection Note:', err.message);
});

async function updateBusLocation(busId, lat, lng) {
  memoryCache.set(busId, { lat, lng, timestamp: Date.now() });
  if (isRedisConnected) {
    try {
      await redis.hset(`bus:${busId}`, 'lat', lat, 'lng', lng, 'updatedAt', Date.now());
    } catch (err) {
      // fallback to memoryCache is already updated
    }
  }
}

async function getBusLocation(busId) {
  if (isRedisConnected) {
    try {
      const data = await redis.hgetall(`bus:${busId}`);
      if (data && data.lat) {
        return { lat: parseFloat(data.lat), lng: parseFloat(data.lng) };
      }
    } catch (err) {
      // fallback
    }
  }
  return memoryCache.get(busId) || null;
}

module.exports = {
  redis,
  updateBusLocation,
  getBusLocation
};
