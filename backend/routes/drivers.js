const router = require('express').Router();
const Driver = require('../models/Driver');
const verifyToken = require('../middleware/verifyToken');

// GET all drivers
router.get('/', async (req, res) => {
  try {
    const drivers = await Driver.find()
      .populate('assignedBus');

    res.json(drivers);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET driver by ID
router.get('/:id', async (req, res) => {
  try {
    const driver = await Driver.findById(req.params.id)
      .populate('assignedBus');

    if (!driver) {
      return res.status(404).json({ error: 'Driver not found' });
    }

    res.json(driver);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// CREATE driver - Admin only
router.post('/', verifyToken, async (req, res) => {
  try {
    const driver = await Driver.create(req.body);
    res.status(201).json(driver);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// UPDATE driver - Admin only
router.put('/:id', verifyToken, async (req, res) => {
  try {
    const driver = await Driver.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!driver) {
      return res.status(404).json({ error: 'Driver not found' });
    }

    res.json(driver);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// DELETE driver - Admin only
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const driver = await Driver.findByIdAndDelete(req.params.id);

    if (!driver) {
      return res.status(404).json({ error: 'Driver not found' });
    }

    res.json({ success: true, message: 'Driver deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;