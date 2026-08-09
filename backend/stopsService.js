const fs = require('fs');
const path = require('path');

// Data/ sits at the repo root, one level above backend/
const DATA_DIR = path.join(__dirname, '..', 'Data');

function slugify(name) {
  return name
    .toLowerCase()
    .replace(/\(([^)]+)\)/g, '$1') // "Rupnagar (Ropar)" -> "Rupnagar Ropar"
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
}

// districtSlug -> { name, stops: [...] }
let districts = new Map();

function loadAll() {
  districts = new Map();

  const folders = fs.readdirSync(DATA_DIR, { withFileTypes: true })
    .filter((entry) => entry.isDirectory());

  for (const folder of folders) {
    const filePath = path.join(DATA_DIR, folder.name, 'stops.json');
    if (!fs.existsSync(filePath)) continue;

    try {
      const raw = fs.readFileSync(filePath, 'utf8');
      const stops = JSON.parse(raw);
      districts.set(slugify(folder.name), {
        name: folder.name,
        stops,
      });
    } catch (err) {
      console.error(`Failed to load stops for ${folder.name}:`, err.message);
    }
  }

  console.log(`Loaded stops for ${districts.size} districts`);
}

function getDistrictList() {
  return Array.from(districts.entries()).map(([slug, d]) => ({
    slug,
    name: d.name,
    stopCount: d.stops.length,
  }));
}

function getDistrict(slug) {
  return districts.get(slug) || null;
}

function getAllStops() {
  const all = [];
  for (const { name, stops } of districts.values()) {
    for (const stop of stops) {
      all.push({ ...stop, district: name });
    }
  }
  return all;
}

// Simple haversine distance in km
function distanceKm(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function getNearbyStops(lat, lng, radiusKm = 2) {
  return getAllStops()
    .map((stop) => ({
      ...stop,
      distanceKm: distanceKm(lat, lng, stop.latitude, stop.longitude),
    }))
    .filter((stop) => stop.distanceKm <= radiusKm)
    .sort((a, b) => a.distanceKm - b.distanceKm);
}

module.exports = {
  loadAll,
  getDistrictList,
  getDistrict,
  getAllStops,
  getNearbyStops,
};