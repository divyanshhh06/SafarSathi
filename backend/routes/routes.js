const router = require('express').Router();
const Route = require('../models/Route');
const verifyToken = require('../middleware/verifyToken');

// GET all routes
router.get('/', async (req, res) => {
  try {
    const routes = await Route.find();
    res.json(routes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET route by ID
router.get('/:id', async (req, res) => {
  try {
    const route = await Route.findById(req.params.id);

    if (!route) {
      return res.status(404).json({ error: 'Route not found' });
    }

    res.json(route);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// CREATE route - Admin only
router.post('/', verifyToken, async (req, res) => {
  try {
    const route = await Route.create(req.body);
    res.status(201).json(route);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// UPDATE route - Admin only
router.put('/:id', verifyToken, async (req, res) => {
  try {
    const route = await Route.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!route) {
      return res.status(404).json({ error: 'Route not found' });
    }

    res.json(route);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// DELETE route - Admin only
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const route = await Route.findByIdAndDelete(req.params.id);

    if (!route) {
      return res.status(404).json({ error: 'Route not found' });
    }

    res.json({ success: true, message: 'Route deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;