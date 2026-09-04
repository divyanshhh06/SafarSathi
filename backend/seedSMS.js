const mongoose = require('mongoose');
require('dotenv').config();

const Route = require('./models/Route');
const Bus = require('./models/Bus');
const Schedule = require('./models/Schedule');

async function seed() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('MongoDB connected');

    // Remove old test data if it exists
    const oldRoute = await Route.findOne({ routeNumber: '4B' });

    if (oldRoute) {
      await Bus.deleteMany({ route: oldRoute._id });
      await Schedule.deleteMany({ route: oldRoute._id });
      await Route.deleteOne({ _id: oldRoute._id });
    }

    // Create route
    const route = await Route.create({
      routeNumber: '4B',
      name: 'SafarSathi Test Route',
      stops: []
    });

    // Create bus
    await Bus.create({
      busNumber: 'SS-101',
      route: route._id,
      speed: 35
    });

    // Create schedule
    await Schedule.create({
      route: route._id,
      departureTimes: ['07:00', '09:00', '11:00', '13:00', '15:00', '17:00']
    });

    console.log('✅ Test Route, Bus and Schedule created');
    console.log('Route:', route.routeNumber);
    console.log('Bus: SS-101');
    console.log('Schedule: 07:00, 09:00, 11:00, 13:00, 15:00, 17:00');

    await mongoose.disconnect();
  } catch (error) {
    console.error('❌ Seed failed:', error.message);
    process.exit(1);
  }
}

seed();
