const router = require('express').Router();
const Bus = require('../models/Bus');
const verifyToken = require('../middleware/verifyToken');

// GET all buses
router.get('/', async (req, res) => {
  try {
    const buses = await Bus.find()
      .populate('route')
      .populate('driver');

    res.json(buses);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET bus by ID
router.get('/:id', async (req, res) => {
  try {
    const bus = await Bus.findById(req.params.id)
      .populate('route')
      .populate('driver');

    if (!bus) {
      return res.status(404).json({ error: 'Bus not found' });
    }

    res.json(bus);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// CREATE bus - Admin only
router.post('/', verifyToken, async (req, res) => {
  try {
    const bus = await Bus.create(req.body);
    res.status(201).json(bus);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// UPDATE bus - Admin only
router.put('/:id', verifyToken, async (req, res) => {
  try {
    const bus = await Bus.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!bus) {
      return res.status(404).json({ error: 'Bus not found' });
    }

    res.json(bus);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// DELETE bus - Admin only
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const bus = await Bus.findByIdAndDelete(req.params.id);

    if (!bus) {
      return res.status(404).json({ error: 'Bus not found' });
    }

    res.json({ success: true, message: 'Bus deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;