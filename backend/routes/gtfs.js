const router = require('express').Router();
const JSZip = require('jszip');
const Route = require('../models/Route');
const Schedule = require('../models/Schedule');

router.get('/export', async (req, res) => {
  try {
    const routes = await Route.find().populate('stops.stop');
    const schedules = await Schedule.find();

    let agencyTxt = 'agency_id,agency_name,agency_url,agency_timezone\n';
    agencyTxt += '1,SafarSathi,https://safarsathi.example.com,Asia/Kolkata\n';

    let calendarTxt = 'service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date\n';
    calendarTxt += '1,1,1,1,1,1,1,1,20260101,20261231\n';

    let routesTxt = 'route_id,route_short_name,route_long_name,route_type\n';
    let tripsTxt = 'trip_id,route_id,service_id\n';
    let stopTimesTxt = 'trip_id,arrival_time,departure_time,stop_id,stop_sequence\n';
    const stopMap = new Map();

    routes.forEach(route => {
      routesTxt += `${route._id},${route.routeNumber},${route.name || ''},3\n`;
      const tripId = `${route._id}_1`;
      tripsTxt += `${tripId},${route._id},1\n`;

      const sortedStops = [...route.stops].sort((a, b) => a.sequence - b.sequence);
      const schedule = schedules.find(s => String(s.route) === String(route._id));
      let [h, m] = (schedule?.departureTimes?.[0] || '07:00').split(':').map(Number);

      sortedStops.forEach(s => {
        if (!s.stop) return;
        stopMap.set(String(s.stop._id), s.stop);
        const time = `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:00`;
        stopTimesTxt += `${tripId},${time},${time},${s.stop._id},${s.sequence}\n`;
        m += 5;
        if (m >= 60) { m -= 60; h += 1; }
      });
    });

    let stopsTxt = 'stop_id,stop_name,stop_lat,stop_lon\n';
    stopMap.forEach(stop => {
      stopsTxt += `${stop._id},${stop.name},${stop.location.coordinates[1]},${stop.location.coordinates[0]}\n`;
    });

    const zip = new JSZip();
    zip.file('agency.txt', agencyTxt);
    zip.file('calendar.txt', calendarTxt);
    zip.file('routes.txt', routesTxt);
    zip.file('trips.txt', tripsTxt);
    zip.file('stops.txt', stopsTxt);
    zip.file('stop_times.txt', stopTimesTxt);

    const content = await zip.generateAsync({ type: 'nodebuffer' });
    res.set('Content-Type', 'application/zip');
    res.set('Content-Disposition', 'attachment; filename=safarsathi_gtfs.zip');
    res.send(content);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'GTFS export failed' });
  }
});

module.exports = router;