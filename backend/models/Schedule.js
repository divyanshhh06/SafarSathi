const mongoose = require('mongoose');

const scheduleSchema = new mongoose.Schema({
  route: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Route'
  },
  departureTimes: [String]
});

module.exports = mongoose.model('Schedule', scheduleSchema);