const router = require('express').Router();
const verifyToken = require('../middleware/verifyToken');
const Stop = require('../models/Stop');

// GET all stops
router.get('/', async (req, res) => {
  try {
    const stops = await Stop.find();
    res.json(stops);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET stop by ID
router.get('/:id', async (req, res) => {
  try {
    const stop = await Stop.findById(req.params.id);

    if (!stop) {
      return res.status(404).json({ error: 'Stop not found' });
    }

    res.json(stop);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// CREATE stop - Admin only
router.post('/', verifyToken, async (req, res) => {
  try {
    const stop = await Stop.create(req.body);
    res.status(201).json(stop);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// UPDATE stop - Admin only
router.put('/:id', verifyToken, async (req, res) => {
  try {
    const stop = await Stop.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!stop) {
      return res.status(404).json({ error: 'Stop not found' });
    }

    res.json(stop);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// DELETE stop - Admin only
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const stop = await Stop.findByIdAndDelete(req.params.id);

    if (!stop) {
      return res.status(404).json({ error: 'Stop not found' });
    }

    res.json({ success: true, message: 'Stop deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;