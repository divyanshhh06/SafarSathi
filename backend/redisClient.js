require('dotenv').config();
const Redis = require('ioredis');

// Connect to local or remote Redis instance
const redis = new Redis({
  host: process.env.REDIS_HOST || '127.0.0.1',
  port: process.env.REDIS_PORT || 6379,
});

/**
 * Cache a driver's live coordinate.
 * IMPORTANT: Redis GEOADD syntax requires LONGITUDE first, then LATITUDE.
 */
async function updateBusLocation(busId, lat, lng) {
  // GEOADD live_buses <longitude> <latitude> <member_id>
  await redis.geoadd('live_buses', lng, lat, busId);
}

/**
 * Sub-100ms spatial lookup from RAM.
 */
async function getBusLocation(busId) {
  const pos = await redis.geopos('live_buses', busId);

  // Return null if location hasn't been set or is empty
  if (!pos || !pos[0] || !pos[0][0]) return null;

  // pos[0] returns strings: [longitude, latitude]
  return {
    lat: parseFloat(pos[0][1]),
    lng: parseFloat(pos[0][0])
  };
}

module.exports = { redis, updateBusLocation, getBusLocation };