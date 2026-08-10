/**
 * Dynamic Geospatial ETA Calculation Engine (BE-3 Core Deliverable)
 * Advanced GIS spatial math powered by @turf/turf:
 * - Line projection & snapping (nearestPointOnLine)
 * - Curve distance along route geometry (lineSlice & length)
 * - Bearing & compass direction calculation (bearing)
 * - Time-to-stop ETA matrix with dynamic traffic delay adjustments
 */

const turf = require("@turf/turf");
const db = require("../data/db");
const trafficAdjuster = require("./trafficAdjuster");

class ETAEngine {
  /**
   * Calculate straight-line distance between two coordinate pairs in kilometers using Turf.js
   * @param {Array<number>} coord1 - [lng, lat]
   * @param {Array<number>} coord2 - [lng, lat]
   */
  calculateDistanceKm(coord1, coord2) {
    const from = turf.point(coord1);
    const to = turf.point(coord2);
    return turf.distance(from, to, { units: "kilometers" });
  }

  /**
   * Calculate compass bearing (heading 0°-360°) between two points using Turf.js
   */
  calculateBearing(coord1, coord2) {
    const from = turf.point(coord1);
    const to = turf.point(coord2);
    let bearing = turf.bearing(from, to);
    if (bearing < 0) bearing += 360;
    return parseFloat(bearing.toFixed(1));
  }

  /**
   * Project raw vehicle GPS coordinates onto route polyline shape to eliminate GPS jitter
   */
  getBusRoutePosition(busLocation, routeCoordinates) {
    const busPoint = turf.point([busLocation.lng, busLocation.lat]);
    const routeLine = turf.lineString(routeCoordinates);
    const snapped = turf.nearestPointOnLine(routeLine, busPoint);
    const distVal = snapped && snapped.properties ? (snapped.properties.dist !== undefined ? snapped.properties.dist : snapped.properties.distance) : 0;

    return {
      snappedLocation: {
        lng: snapped.geometry.coordinates[0],
        lat: snapped.geometry.coordinates[1]
      },
      distanceFromRouteKm: parseFloat((distVal || 0).toFixed(3)),
      locationOnLineIndex: snapped.properties ? snapped.properties.index : 0
    };
  }

  /**
   * Calculate curved road distance along polyline geometry between two points on route
   */
  sliceRouteDistanceKm(routeCoordinates, startCoord, endCoord) {
    try {
      if (!routeCoordinates || routeCoordinates.length < 2) {
        return this.calculateDistanceKm(startCoord, endCoord);
      }
      const routeLine = turf.lineString(routeCoordinates);
      const startPt = turf.point(startCoord);
      const endPt = turf.point(endCoord);

      const sliced = turf.lineSlice(startPt, endPt, routeLine);
      const lengthKm = turf.length(sliced, { units: "kilometers" });
      return parseFloat(lengthKm.toFixed(3));
    } catch (e) {
      // Fallback to straight-line distance if slicing boundary condition occurs
      return this.calculateDistanceKm(startCoord, endCoord);
    }
  }

  /**
   * Primary Dynamic ETA Engine: Computes time-to-stop for all upcoming stops on a route
   * @param {string} busId - ID of the bus
   * @returns {Object} Complete GIS ETA calculation matrix
   */
  calculateBusETAs(busId) {
    const bus = db.getBusById(busId);
    if (!bus) {
      throw new Error(`Bus with ID ${busId} not found`);
    }

    const route = db.getRouteById(bus.route_id);
    if (!route) {
      throw new Error(`Route with ID ${bus.route_id} not found`);
    }

    const currentLocation = bus.current_location;
    const baseSpeed = currentLocation.speed && currentLocation.speed > 0 ? currentLocation.speed : 25.0; // Default 25 km/h if idle

    // Snap current bus GPS location onto route geometry
    const busPointCoord = [currentLocation.lng, currentLocation.lat];
    const snapResult = this.getBusRoutePosition(currentLocation, route.coordinates);

    // Get all stops for this route
    const routeStops = route.stops.map(stopId => db.getStopById(stopId)).filter(Boolean);

    // Identify nearest stop on route
    let nearestStopIndex = 0;
    let minDistanceToStop = Infinity;

    routeStops.forEach((stop, index) => {
      const dist = this.sliceRouteDistanceKm(route.coordinates, busPointCoord, [stop.lng, stop.lat]);
      if (dist < minDistanceToStop) {
        minDistanceToStop = dist;
        nearestStopIndex = index;
      }
    });

    const stopETAs = [];
    let accumulatedMinutes = 0;
    const now = new Date();

    for (let i = 0; i < routeStops.length; i++) {
      const stop = routeStops[i];
      const stopCoord = [stop.lng, stop.lat];

      if (i < nearestStopIndex) {
        // Passed stop
        stopETAs.push({
          stopId: stop.id,
          stopName: stop.name,
          stopCode: stop.code,
          lat: stop.lat,
          lng: stop.lng,
          status: "PASSED",
          etaMinutes: 0,
          expectedArrivalTimestamp: now.toISOString(),
          distanceKm: 0,
          adjustedSpeedKmh: 0,
          isCongested: false
        });
      } else if (i === nearestStopIndex) {
        // Approaching immediate stop
        const distanceToStop = this.sliceRouteDistanceKm(route.coordinates, busPointCoord, stopCoord);
        const nextStopId = routeStops[i + 1] ? routeStops[i + 1].id : stop.id;

        const speedInfo = trafficAdjuster.getAdjustedSpeed(baseSpeed, stop.id, nextStopId);
        const timeHours = distanceToStop / speedInfo.adjustedSpeed;
        const segmentMinutes = timeHours * 60;
        accumulatedMinutes += segmentMinutes;

        const arrivalTime = new Date(now.getTime() + Math.round(accumulatedMinutes * 60 * 1000));
        const bearing = this.calculateBearing(busPointCoord, stopCoord);

        stopETAs.push({
          stopId: stop.id,
          stopName: stop.name,
          stopCode: stop.code,
          lat: stop.lat,
          lng: stop.lng,
          status: "APPROACHING",
          bearingDegrees: bearing,
          etaMinutes: Math.round(accumulatedMinutes),
          expectedArrivalTimestamp: arrivalTime.toISOString(),
          distanceKm: parseFloat(distanceToStop.toFixed(2)),
          adjustedSpeedKmh: speedInfo.adjustedSpeed,
          isCongested: speedInfo.isCongested
        });
      } else {
        // Downstream stops along route polyline
        const prevStop = routeStops[i - 1];
        const prevStopCoord = [prevStop.lng, prevStop.lat];

        const interStopDistance = this.sliceRouteDistanceKm(route.coordinates, prevStopCoord, stopCoord);
        const speedInfo = trafficAdjuster.getAdjustedSpeed(baseSpeed, prevStop.id, stop.id);

        const timeHours = interStopDistance / speedInfo.adjustedSpeed;
        const segmentMinutes = timeHours * 60;
        accumulatedMinutes += segmentMinutes;

        const arrivalTime = new Date(now.getTime() + Math.round(accumulatedMinutes * 60 * 1000));

        stopETAs.push({
          stopId: stop.id,
          stopName: stop.name,
          stopCode: stop.code,
          lat: stop.lat,
          lng: stop.lng,
          status: "UPCOMING",
          etaMinutes: Math.round(accumulatedMinutes),
          expectedArrivalTimestamp: arrivalTime.toISOString(),
          distanceKm: parseFloat(interStopDistance.toFixed(2)),
          adjustedSpeedKmh: speedInfo.adjustedSpeed,
          isCongested: speedInfo.isCongested
        });
      }
    }

    return {
      busId: bus.id,
      registrationNo: bus.registration_no,
      routeId: route.id,
      routeName: route.long_name,
      routeShortName: route.short_name,
      currentSpeed: baseSpeed,
      snappedLocation: snapResult.snappedLocation,
      gpsDriftKm: snapResult.distanceFromRouteKm,
      crowdStatus: bus.crowd_status,
      lastUpdated: bus.last_updated,
      stops: stopETAs
    };
  }

  /**
   * Get ETAs for all buses running on a given route
   */
  getRouteETAs(routeId) {
    const buses = db.getBusByRoute(routeId);
    return buses.map(bus => this.calculateBusETAs(bus.id));
  }
}

module.exports = new ETAEngine();
