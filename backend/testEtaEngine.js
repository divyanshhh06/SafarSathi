/**
 * Test Suite & Demonstration for BE-3 Geospatial ETA Engine
 * Runs on terminal with demo transit data from Amritsar Corridor
 */

const path = require('path');
// Enable resolving dependencies installed in backend/node_modules
const backendModules = path.resolve(__dirname, 'node_modules');
process.env.NODE_PATH = backendModules;
require('module').Module._initPaths();
if (!module.paths.includes(backendModules)) {
  module.paths.unshift(backendModules);
}

const etaEngine = require('../src/services/etaEngine');
const trafficAdjuster = require('../src/services/trafficAdjuster');
const osrmRouting = require('../src/services/osrmRouting');
const db = require('../src/data/db');

async function runTestSuite() {
  console.log('================================================================');
  console.log('🚌 SAFARSATHI BE-3: GEOSPATIAL ETA ENGINE TEST SUITE');
  console.log('   Punjab Govt Challenge IDSVH26003');
  console.log('================================================================\n');

  // -------------------------------------------------------------
  // TEST 1: Basic Spatial Math (Turf.js)
  // -------------------------------------------------------------
  console.log('📍 [TEST 1] Geospatial Distance & Bearing Calculations:');
  const isbt = [74.8800, 31.6260];
  const hallBazaar = [74.8750, 31.6300];
  const distKm = etaEngine.calculateDistanceKm(isbt, hallBazaar);
  const bearing = etaEngine.calculateBearing(isbt, hallBazaar);

  console.log(`   - Straight-line ISBT -> Hall Bazaar: ${distKm.toFixed(3)} km`);
  console.log(`   - Compass Bearing: ${bearing}°`);
  console.log(`   - Status: ${distKm > 0 && bearing >= 0 && bearing <= 360 ? 'PASSED ✅' : 'FAILED ❌'}\n`);

  // -------------------------------------------------------------
  // TEST 2: GPS Snapping & Drift Detection
  // -------------------------------------------------------------
  console.log('🎯 [TEST 2] Route Polyline Snapping & GPS Drift:');
  const rawGps = { lng: 74.8768, lat: 31.6310 }; // Jittered GPS point near Bhandari Bridge
  const route = db.getRouteById('ROUTE_4B');
  const snapResult = etaEngine.getBusRoutePosition(rawGps, route.coordinates);

  console.log(`   - Raw GPS Input: [${rawGps.lng}, ${rawGps.lat}]`);
  console.log(`   - Snapped On Polyline: [${snapResult.snappedLocation.lng.toFixed(5)}, ${snapResult.snappedLocation.lat.toFixed(5)}]`);
  console.log(`   - GPS Drift Distance: ${(snapResult.distanceFromRouteKm * 1000).toFixed(1)} meters`);
  console.log(`   - Status: ${snapResult.distanceFromRouteKm >= 0 ? 'PASSED ✅' : 'FAILED ❌'}\n`);

  // -------------------------------------------------------------
  // TEST 3: Dynamic Traffic Congestion Adjuster
  // -------------------------------------------------------------
  console.log('🚦 [TEST 3] Dynamic Traffic Adjuster:');
  const baseSpeed = 30.0;
  const normalSpeed = trafficAdjuster.getAdjustedSpeed(baseSpeed, 'STOP_01', 'STOP_02');
  const congestedSpeed = trafficAdjuster.getAdjustedSpeed(baseSpeed, 'STOP_03', 'STOP_04');
  const timeFactor = trafficAdjuster.getTimeOfDayFactor();

  console.log(`   - Base Speed: ${baseSpeed} km/h`);
  console.log(`   - Time-of-Day Multiplier: ${timeFactor}x`);
  console.log(`   - Normal Segment (STOP_01 -> STOP_02): ${normalSpeed.adjustedSpeed} km/h (isCongested: ${normalSpeed.isCongested})`);
  console.log(`   - Congested Segment (STOP_03 -> STOP_04): ${congestedSpeed.adjustedSpeed} km/h (isCongested: ${congestedSpeed.isCongested})`);
  console.log(`   - Status: ${congestedSpeed.adjustedSpeed < normalSpeed.adjustedSpeed ? 'PASSED ✅' : 'FAILED ❌'}\n`);

  // -------------------------------------------------------------
  // TEST 4: Full Bus ETA Matrix Execution
  // -------------------------------------------------------------
  console.log('⏱️ [TEST 4] Full Stop-by-Stop ETA Matrix (Bus 101 in Transit):');
  const bus101Eta = etaEngine.calculateBusETAs('BUS_101');

  console.log(`   Bus ID: ${bus101Eta.busId} (${bus101Eta.registrationNo})`);
  console.log(`   Route: ${bus101Eta.routeName}`);
  console.log(`   Telemetry Speed: ${bus101Eta.currentSpeed} km/h`);
  console.log(`   GPS Drift: ${(bus101Eta.gpsDriftKm * 1000).toFixed(1)} meters\n`);

  console.log('   STOPS ETA SCHEDULE:');
  console.log('   --------------------------------------------------------------------------------------------------');
  console.log('   Stop ID | Stop Name                                  | Status      | Dist(km) | Speed(km/h) | ETA ');
  console.log('   --------------------------------------------------------------------------------------------------');
  
  for (const s of bus101Eta.stops) {
    const paddedId = s.stopId.padEnd(7, ' ');
    const paddedName = s.stopName.padEnd(42, ' ');
    const paddedStatus = s.status.padEnd(11, ' ');
    const paddedDist = (s.distanceKm + ' km').padEnd(8, ' ');
    const paddedSpeed = (s.adjustedSpeedKmh > 0 ? s.adjustedSpeedKmh + ' km/h' : '-').padEnd(11, ' ');
    const etaStr = s.status === 'PASSED' ? 'Passed' : `${s.etaMinutes} min`;
    console.log(`   ${paddedId} | ${paddedName} | ${paddedStatus} | ${paddedDist} | ${paddedSpeed} | ${etaStr}`);
  }
  console.log('   --------------------------------------------------------------------------------------------------\n');

  // -------------------------------------------------------------
  // TEST 5: Route ETAs (All buses on Route)
  // -------------------------------------------------------------
  console.log('🚌 [TEST 5] Multi-Bus Route ETAs:');
  const allRouteEtas = etaEngine.getRouteETAs('ROUTE_4B');
  console.log(`   - Total Active Buses Found on ROUTE_4B: ${allRouteEtas.length}`);
  allRouteEtas.forEach((b, idx) => {
    const approachingStop = b.stops.find(s => s.status === 'APPROACHING') || b.stops[0];
    console.log(`     [${idx + 1}] Bus ${b.busId} (${b.registrationNo}): Next stop -> ${approachingStop.stopName} (ETA: ${approachingStop.etaMinutes}m)`);
  });
  console.log(`   - Status: ${allRouteEtas.length === 2 ? 'PASSED ✅' : 'FAILED ❌'}\n`);

  // -------------------------------------------------------------
  // TEST 6: OSRM Road-Network Routing with Turf Fallback
  // -------------------------------------------------------------
  console.log('🌐 [TEST 6] OSRM Road-Network Travel Matrix:');
  try {
    const roadMatrix = await osrmRouting.getRoadNetworkMatrix(isbt, hallBazaar);
    console.log(`   - Routing Source: ${roadMatrix.source}`);
    console.log(`   - Road Distance: ${roadMatrix.distanceKm} km`);
    console.log(`   - Estimated Travel Time: ${roadMatrix.durationMinutes} min`);
    console.log(`   - Calculated Speed: ${roadMatrix.averageSpeedKmh} km/h`);
    console.log(`   - Status: ${roadMatrix.success ? 'PASSED ✅' : 'FAILED ❌'}\n`);
  } catch (err) {
    console.log(`   - OSRM test error: ${err.message}\n`);
  }

  console.log('================================================================');
  console.log('🎉 BE-3 ETA ENGINE EVALUATION COMPLETE');
  console.log('================================================================');
}

runTestSuite().catch(err => {
  console.error('Fatal Test Error:', err);
  process.exit(1);
});
