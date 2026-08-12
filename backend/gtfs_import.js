/**
 * GTFS Importer for SafarSathi
 *
 * Usage:
 *   node gtfs_import.js /path/to/gtfs-folder
 *
 * This reads standard GTFS files and converts them into SafarSathi's
 * Data/routes.json and Data/<district>/stops.json format.
 *
 * Supported GTFS files (all optional, but stops.txt is required):
 *   - stops.txt
 *   - routes.txt
 *   - trips.txt
 *   - stop_times.txt
 *   - calendar.txt
 *   - calendar_dates.txt
 */

const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, '..', 'Data');

function parseCsv(text) {
  const lines = text.trim().split(/\r?\n/);
  if (lines.length === 0) return [];
  const headers = lines[0].split(',').map((h) => h.trim().replace(/^"|"$/g, ''));
  const rows = [];
  for (let i = 1; i < lines.length; i++) {
    if (!lines[i].trim()) continue;
    const values = lines[i].split(',').map((v) => v.trim().replace(/^"|"$/g, ''));
    const obj = {};
    headers.forEach((h, idx) => {
      obj[h] = values[idx] ?? '';
    });
    rows.push(obj);
  }
  return rows;
}

function toNum(v) {
  const n = parseFloat(v);
  return Number.isNaN(n) ? null : n;
}

function slugify(name) {
  return name
    .toLowerCase()
    .replace(/\(([^)]+)\)/g, '$1')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
}

function districtFromStop(stop) {
  const city = (stop.stop_city || stop.agency_city || '').trim();
  const state = (stop.stop_state || stop.agency_state || '').trim();
  const name = (stop.stop_name || '').trim();
  if (city) return slugify(city);
  if (name && name.includes(',')) {
    const parts = name.split(',');
    return slugify(parts[parts.length - 1].trim());
  }
  return 'unknown';
}

function importGtfs(gtfsDir) {
  if (!fs.existsSync(gtfsDir)) {
    console.error(`GTFS folder not found: ${gtfsDir}`);
    process.exit(1);
  }

  const file = (name) => {
    const p = path.join(gtfsDir, name);
    return fs.existsSync(p) ? fs.readFileSync(p, 'utf8') : null;
  };

  const stopsText = file('stops.txt');
  if (!stopsText) {
    console.error('stops.txt is required in GTFS folder');
    process.exit(1);
  }

  const stops = parseCsv(stopsText);
  console.log(`GTFS stops: ${stops.length}`);

  const routes = parseCsv(file('routes.txt') || '');
  const trips = parseCsv(file('trips.txt') || '');
  const stopTimes = parseCsv(file('stop_times.txt') || '');
  const calendar = parseCsv(file('calendar.txt') || '');
  const calendarDates = parseCsv(file('calendar_dates.txt') || '');

  // Build stop lookup
  const stopById = new Map();
  for (const s of stops) {
    stopById.set(s.stop_id, s);
  }

  // Group stops by district
  const districtStops = new Map();
  for (const s of stops) {
    const district = districtFromStop(s);
    if (!districtStops.has(district)) {
      districtStops.set(district, []);
    }
    districtStops.get(district).push({
      id: s.stop_id,
      name: s.stop_name || 'Bus Stop',
      city: s.stop_city || (s.stop_name ? s.stop_name.split(',')[0].trim() : ''),
      state: s.stop_state || 'Punjab',
      country: s.stop_country || 'India',
      latitude: toNum(s.stop_lat),
      longitude: toNum(s.stop_lon),
      type: s.stop_type || 'bus_stop',
      publicTransport: s.publicTransport === 'TRUE' || s.publicTransport === '1',
      shelter: s.shelter === 'TRUE' || s.shelter === '1' ? true : null,
    });
  }

  // Ensure Data/district folders exist
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
  for (const [district, stopsList] of districtStops.entries()) {
    const dir = path.join(DATA_DIR, district);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(
      path.join(dir, 'stops.json'),
      JSON.stringify(stopsList, null, 2),
      'utf8'
    );
  }
  console.log(`Wrote stops for ${districtStops.size} districts`);

  // Build routes from trips + stop_times
  const routeStops = new Map(); // route_id -> [{stop_id, sequence}]
  const routePath = new Map(); // route_id -> [[lat,lng], ...]

  if (trips.length > 0 && stopTimes.length > 0) {
    for (const st of stopTimes) {
      const rid = st.route_id || (trips.find((t) => t.trip_id === st.trip_id)?.route_id);
      if (!rid) continue;
      if (!routeStops.has(rid)) routeStops.set(rid, []);
      routeStops.get(rid).push({
        stop_id: st.stop_id,
        sequence: parseInt(st.stop_sequence || '0', 10),
      });
    }

    for (const [rid, seq] of routeStops.entries()) {
      seq.sort((a, b) => a.sequence - b.sequence);
      const unique = [];
      const seen = new Set();
      for (const s of seq) {
        if (!seen.has(s.stop_id)) {
          seen.add(s.stop_id);
          unique.push(s.stop_id);
        }
      }
      const coords = unique
        .map((sid) => stopById.get(sid))
        .filter(Boolean)
        .map((s) => [parseFloat(s.stop_lat), parseFloat(s.stop_lon)]);
      routePath.set(rid, coords);
    }
  }

  const routeList = [];
  for (const r of routes) {
    const stopsForRoute = (routeStops.get(r.route_id) || [])
      .map((s) => stopById.get(s.stop_id))
      .filter(Boolean)
      .map((s) => ({
        id: s.stop_id,
        name: s.stop_name || 'Bus Stop',
        city: s.stop_city || '',
        state: s.stop_state || 'Punjab',
        latitude: parseFloat(s.stop_lat),
        longitude: parseFloat(s.stop_lon),
        shelter: s.shelter === 'TRUE' || s.shelter === '1' ? true : null,
      }));

    const pathForRoute = routePath.get(r.route_id) || [];

    routeList.push({
      id: r.route_id || r.route_short_name || `route-${routeList.length + 1}`,
      name: r.route_long_name || r.route_short_name || 'Unnamed Route',
      namePa: '',
      nameHi: '',
      stops: stopsForRoute,
      path: pathForRoute,
    });
  }

  // Fallback: if no routes.txt, create one route per district from stops
  if (routeList.length === 0 && districtStops.size > 0) {
    for (const [district, stopsList] of districtStops.entries()) {
      const coords = stopsList
        .map((s) => [s.latitude, s.longitude])
        .filter((c) => c[0] != null && c[1] != null);
      routeList.push({
        id: `R-${district}`,
        name: `Route ${district.charAt(0).toUpperCase() + district.slice(1)}`,
        namePa: '',
        nameHi: '',
        stops: stopsList,
        path: coords,
      });
    }
  }

  fs.writeFileSync(
    path.join(DATA_DIR, 'routes.json'),
    JSON.stringify(routeList, null, 2),
    'utf8'
  );
  console.log(`Wrote ${routeList.length} routes to routes.json`);
  console.log('GTFS import complete.');
}

const gtfsDir = process.argv[2];
if (!gtfsDir) {
  console.error('Usage: node gtfs_import.js /path/to/gtfs/folder');
  process.exit(1);
}

importGtfs(gtfsDir);
