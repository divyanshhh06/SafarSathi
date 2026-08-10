/**
 * OSRM / Mapbox Road-Network Routing Engine (BE-3 Learning Roadmap Topic)
 * Computes road-network travel time matrices in Node.js via Open Source Routing Machine (OSRM) API,
 * with seamless fallback to Turf.js spatial curve calculations.
 */

const http = require("http");
const https = require("https");
const turf = require("@turf/turf");

class OSRMRoutingService {
  constructor() {
    this.osrmBaseUrl = process.env.OSRM_URL || "https://router.project-osrm.org";
  }

  /**
   * Fetch road network route distance and travel time matrix between coordinates [lng, lat]
   * @param {Array<number>} origin - [lng, lat]
   * @param {Array<number>} destination - [lng, lat]
   */
  async getRoadNetworkMatrix(origin, destination) {
    const url = `${this.osrmBaseUrl}/route/v1/driving/${origin[0]},${origin[1]};${destination[0]},${destination[1]}?overview=false`;

    return new Promise((resolve) => {
      const client = url.startsWith("https") ? https : http;

      const req = client.get(url, { timeout: 3000 }, (res) => {
        let body = "";
        res.on("data", (chunk) => body += chunk);
        res.on("end", () => {
          try {
            const data = JSON.parse(body);
            if (data.code === "Ok" && data.routes && data.routes.length > 0) {
              const route = data.routes[0];
              return resolve({
                success: true,
                source: "OSRM_ROAD_NETWORK",
                distanceKm: parseFloat((route.distance / 1000).toFixed(3)),
                durationMinutes: parseFloat((route.duration / 60).toFixed(1)),
                averageSpeedKmh: parseFloat(((route.distance / 1000) / (route.duration / 3600)).toFixed(1))
              });
            }
          } catch (e) {}
          resolve(this._getTurfFallbackMatrix(origin, destination));
        });
      });

      req.on("error", () => resolve(this._getTurfFallbackMatrix(origin, destination)));
      req.on("timeout", () => {
        req.destroy();
        resolve(this._getTurfFallbackMatrix(origin, destination));
      });
    });
  }

  _getTurfFallbackMatrix(origin, destination) {
    const from = turf.point(origin);
    const to = turf.point(destination);
    const distKm = turf.distance(from, to, { units: "kilometers" });
    const speedKmh = 30.0; // Default urban speed
    const durationMin = (distKm / speedKmh) * 60;

    return {
      success: true,
      source: "TURF_SPATIAL_FALLBACK",
      distanceKm: parseFloat(distKm.toFixed(3)),
      durationMinutes: parseFloat(durationMin.toFixed(1)),
      averageSpeedKmh: speedKmh
    };
  }
}

module.exports = new OSRMRoutingService();

