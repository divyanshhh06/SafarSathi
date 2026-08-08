/**
 * Truncates coordinate precision to 4 decimal places (~11-meter accuracy)
 * and packs telemetry into a positional array tuple.
 * Payload Schema: [lat, lng, busId, speed, routeId]
 */
function compressPayload(lat, lng, busId, speed, routeId) {
  return [
    Math.round(lat * 10000) / 10000,
    Math.round(lng * 10000) / 10000,
    String(busId),
    Math.round(speed),
    String(routeId)
  ];
}

/**
 * Unpacks positional array elements into a clean object for client-side rendering.
 */
function decompressPayload(data) {
  const [lat, lng, busId, speed, routeId] = data;
  return {
    lat: Number(lat),
    lng: Number(lng),
    busId,
    speed: Number(speed),
    routeId
  };
}

module.exports = { compressPayload, decompressPayload };