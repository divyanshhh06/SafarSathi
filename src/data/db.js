/**
 * SafarSathi Data Store & Models (BE-2 Core Data Schema)
 * Pre-populated with Punjab Municipal Bus Routes (Amritsar, Ludhiana, Jalandhar)
 */

class Database {
  constructor() {
    // Agency Information
    this.agency = {
      agency_id: "PUNJAB_TRANS_01",
      agency_name: "Punjab Municipal Transport Corporation (PMTC)",
      agency_url: "https://pmtc.punjab.gov.in",
      agency_timezone: "Asia/Kolkata",
      agency_lang: "pa",
      agency_phone: "1800-180-2345"
    };

    // Bus Stops (with PostGIS-style lat/lng geospatial coordinates)
    this.stops = [
      { id: "STOP_01", name: "Amritsar Railway Station", lat: 31.6340, lng: 74.8723, code: "ASR-RS" },
      { id: "STOP_02", name: "Bhandari Bridge", lat: 31.6312, lng: 74.8765, code: "ASR-BB" },
      { id: "STOP_03", name: "Hall Bazaar", lat: 31.6285, lng: 74.8790, code: "ASR-HB" },
      { id: "STOP_04", name: "Golden Temple (Harmandir Sahib)", lat: 31.6200, lng: 74.8765, code: "ASR-GT" },
      { id: "STOP_05", name: "Jallianwala Bagh", lat: 31.6215, lng: 74.8801, code: "ASR-JB" },
      { id: "STOP_06", name: "ISBT Amritsar", lat: 31.6150, lng: 74.8920, code: "ASR-ISBT" },

      { id: "STOP_10", name: "Ludhiana Clock Tower", lat: 30.9100, lng: 75.8510, code: "LDH-CT" },
      { id: "STOP_11", name: "PAU Gate 1", lat: 30.9030, lng: 75.8080, code: "LDH-PAU" },
      { id: "STOP_12", name: "Model Town", lat: 30.8920, lng: 75.8320, code: "LDH-MT" },

      { id: "STOP_20", name: "Jalandhar Bus Stand", lat: 31.3200, lng: 75.5800, code: "JAL-BS" },
      { id: "STOP_21", name: "BMC Chowk", lat: 31.3260, lng: 75.5760, code: "JAL-BMC" },
      { id: "STOP_22", name: "Rama Mandi", lat: 31.3110, lng: 75.6120, code: "JAL-RM" }
    ];

    // Routes (with ordered stop sequences and route shape coordinates)
    this.routes = [
      {
        id: "ROUTE_4B",
        short_name: "4B",
        long_name: "Railway Station to Golden Temple Express",
        type: 3, // Bus
        color: "FF5733",
        text_color: "FFFFFF",
        stops: ["STOP_01", "STOP_02", "STOP_03", "STOP_04", "STOP_05", "STOP_06"],
        // Path polyline coordinates for map projection & distance calculation
        coordinates: [
          [74.8723, 31.6340],
          [74.8765, 31.6312],
          [74.8790, 31.6285],
          [74.8765, 31.6200],
          [74.8801, 31.6215],
          [74.8920, 31.6150]
        ]
      },
      {
        id: "ROUTE_101",
        short_name: "101",
        long_name: "Ludhiana City Circular",
        type: 3,
        color: "33A8FF",
        text_color: "FFFFFF",
        stops: ["STOP_10", "STOP_11", "STOP_12"],
        coordinates: [
          [75.8510, 30.9100],
          [75.8080, 30.9030],
          [75.8320, 30.8920]
        ]
      },
      {
        id: "ROUTE_202",
        short_name: "202",
        long_name: "Jalandhar Intercity Shuttle",
        type: 3,
        color: "28A745",
        text_color: "FFFFFF",
        stops: ["STOP_20", "STOP_21", "STOP_22"],
        coordinates: [
          [75.5800, 31.3200],
          [75.5760, 31.3260],
          [75.6120, 31.3110]
        ]
      }
    ];

    // Buses (Vehicles)
    this.buses = [
      {
        id: "BUS_101",
        registration_no: "PB-02-EG-4521",
        route_id: "ROUTE_4B",
        driver_id: "DRV_01",
        status: "ACTIVE",
        capacity: 45,
        current_location: { lat: 31.6312, lng: 74.8765, speed: 32.5, bearing: 140 },
        crowd_status: "Seats Available",
        last_updated: new Date().toISOString()
      },
      {
        id: "BUS_102",
        registration_no: "PB-02-EG-8890",
        route_id: "ROUTE_4B",
        driver_id: "DRV_02",
        status: "ACTIVE",
        capacity: 50,
        current_location: { lat: 31.6285, lng: 74.8790, speed: 28.0, bearing: 160 },
        crowd_status: "Standing Room",
        last_updated: new Date().toISOString()
      },
      {
        id: "BUS_201",
        registration_no: "PB-10-CZ-9912",
        route_id: "ROUTE_101",
        driver_id: "DRV_03",
        status: "ACTIVE",
        capacity: 40,
        current_location: { lat: 30.9030, lng: 75.8080, speed: 40.0, bearing: 90 },
        crowd_status: "Packed",
        last_updated: new Date().toISOString()
      }
    ];

    // Drivers
    this.drivers = [
      { id: "DRV_01", name: "Gurpreet Singh", phone: "+919876543210", license: "PB0220190012", active_bus: "BUS_101" },
      { id: "DRV_02", name: "Harjeet Kaur", phone: "+919876543211", license: "PB0220180055", active_bus: "BUS_102" },
      { id: "DRV_03", name: "Rajinder Sharma", phone: "+919876543212", license: "PB1020200088", active_bus: "BUS_201" }
    ];

    // Schedules (Static Timetable)
    this.schedules = [
      { id: "SCH_01", route_id: "ROUTE_4B", trip_id: "TRIP_4B_01", start_time: "08:00:00", end_time: "08:45:00", service_id: "DAILY" },
      { id: "SCH_02", route_id: "ROUTE_4B", trip_id: "TRIP_4B_02", start_time: "09:00:00", end_time: "09:45:00", service_id: "DAILY" },
      { id: "SCH_03", route_id: "ROUTE_101", trip_id: "TRIP_101_01", start_time: "08:30:00", end_time: "09:15:00", service_id: "WEEKDAY" }
    ];

    // Crowd Reports ("Waze for Buses" crowdsourced feedback)
    this.crowdReports = [];
  }

  // --- Helper Methods ---
  getRouteById(id) {
    return this.routes.find(r => r.id === id || r.short_name.toLowerCase() === id.toLowerCase());
  }

  getStopById(id) {
    return this.stops.find(s => s.id === id);
  }

  getBusById(id) {
    return this.buses.find(b => b.id === id);
  }

  getBusByRoute(routeId) {
    return this.buses.filter(b => b.route_id === routeId);
  }

  updateBusLocation(busId, lat, lng, speed, bearing = 0) {
    const bus = this.getBusById(busId);
    if (bus) {
      bus.current_location = {
        lat: parseFloat(lat),
        lng: parseFloat(lng),
        speed: parseFloat(speed),
        bearing: parseFloat(bearing)
      };
      bus.last_updated = new Date().toISOString();
      return bus;
    }
    return null;
  }

  addCrowdReport(busId, rating, reporterId = "anonymous") {
    // rating: "Empty" | "Standing" | "Packed"
    const report = {
      id: `CR_${Date.now()}`,
      busId,
      rating,
      reporterId,
      timestamp: new Date().toISOString()
    };
    this.crowdReports.push(report);

    const bus = this.getBusById(busId);
    if (bus) {
      bus.crowd_status = rating === "Empty" ? "Seats Available" : rating === "Standing" ? "Standing Room" : "Packed";
    }
    return report;
  }
}

module.exports = new Database();
