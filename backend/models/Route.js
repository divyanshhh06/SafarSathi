const mongoose = require('mongoose');

const routeSchema = new mongoose.Schema({
  routeNumber: {
    type: String,
    required: true
  },
  name: String,
  stops: [{
    stop: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Stop'
    },
    sequence: Number
  }]
});

module.exports = mongoose.model('Route', routeSchema);