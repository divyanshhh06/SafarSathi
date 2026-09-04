const router = require('express').Router();
const Schedule = require('../models/Schedule');
const verifyToken = require('../middleware/verifyToken');

// GET all schedules
router.get('/', async (req, res) => {
  try {
    const schedules = await Schedule.find()
      .populate('route');

    res.json(schedules);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET schedule by ID
router.get('/:id', async (req, res) => {
  try {
    const schedule = await Schedule.findById(req.params.id)
      .populate('route');

    if (!schedule) {
      return res.status(404).json({ error: 'Schedule not found' });
    }

    res.json(schedule);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// CREATE schedule - Admin only
router.post('/', verifyToken, async (req, res) => {
  try {
    const schedule = await Schedule.create(req.body);
    res.status(201).json(schedule);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// UPDATE schedule - Admin only
router.put('/:id', verifyToken, async (req, res) => {
  try {
    const schedule = await Schedule.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!schedule) {
      return res.status(404).json({ error: 'Schedule not found' });
    }

    res.json(schedule);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// DELETE schedule - Admin only
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const schedule = await Schedule.findByIdAndDelete(req.params.id);

    if (!schedule) {
      return res.status(404).json({ error: 'Schedule not found' });
    }

    res.json({ success: true, message: 'Schedule deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;