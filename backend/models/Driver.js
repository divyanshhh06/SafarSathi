const mongoose = require('mongoose');

const driverSchema = new mongoose.Schema({
  name: String,
  phone: String,
  assignedBus: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Bus'
  }
});

module.exports = mongoose.model('Driver', driverSchema);