require('dotenv').config();
const Redis = require('ioredis');

// Fallback in-memory RAM cache when local Redis server is not installed/running
const memoryCache = new Map();

let redis = null;

try {
  redis = new Redis({
    host: process.env.REDIS_HOST || '127.0.0.1',
    port: process.env.REDIS_PORT || 6379,
    maxRetriesPerRequest: 1,
    enableOfflineQueue: false,
    retryStrategy: () => null, // Prevent connection retry loops if offline
  });

  // Catch connection errors silently to avoid crashing server.js on Windows
  redis.on('error', () => {
    // Suppress ECONNREFUSED log spam when local Redis is absent
  });
} catch (_) {}

/**
 * Cache a driver's live coordinate.
 * Uses Redis GEOADD if available, with in-memory Map fallback.
 */
async function updateBusLocation(busId, lat, lng) {
  memoryCache.set(busId, { lat, lng });

  if (redis && redis.status === 'ready') {
    try {
      await redis.geoadd('live_buses', lng, lat, busId);
    } catch (_) {}
  }
}

/**
 * Fast spatial lookup from RAM or Redis.
 */
async function getBusLocation(busId) {
  if (redis && redis.status === 'ready') {
    try {
      const pos = await redis.geopos('live_buses', busId);
      if (pos && pos[0] && pos[0][0]) {
        return {
          lat: parseFloat(pos[0][1]),
          lng: parseFloat(pos[0][0]),
        };
      }
    } catch (_) {}
  }

  return memoryCache.get(busId) || null;
}

module.exports = { redis, updateBusLocation, getBusLocation };