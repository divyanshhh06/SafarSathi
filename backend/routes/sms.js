const router = require('express').Router();
const twilio = require('twilio');
const Route = require('../models/Route');
const Bus = require('../models/Bus');
const Schedule = require('../models/Schedule');

router.post('/webhook', async (req, res) => {
  const incomingText = (req.body.Body || '').trim().toUpperCase(); // Twilio sends Body & From
  const twiml = new twilio.twiml.MessagingResponse();
  const [command, routeNumber] = incomingText.split(' ');

  if (command !== 'BUS' || !routeNumber) {
    twiml.message('Format: BUS <route number>, e.g. BUS 4B');
  } else {
    const route = await Route.findOne({ routeNumber });
    if (!route) {
      twiml.message(`Route ${routeNumber} not found.`);
    } else {
      const bus = await Bus.findOne({ route: route._id });
      const schedule = await Schedule.findOne({ route: route._id });
      const nextDeparture = schedule?.departureTimes?.[0] || 'not available';
      twiml.message(
        bus
          ? `Bus ${bus.busNumber} on route ${routeNumber}. Next departure: ${nextDeparture}.`
          : `No active bus on route ${routeNumber} right now. Next scheduled: ${nextDeparture}.`
      );
    }
  }

  res.type('text/xml').send(twiml.toString());
});

module.exports = router;