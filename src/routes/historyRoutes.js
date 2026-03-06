const express = require('express');
const router = express.Router();
const historyService = require('../services/historyService');

router.get('/', async (req, res) => {
    try {
        const history = await historyService.getAllHistory();
        res.json(history);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

router.get('/hardware/:hId', async (req, res) => {
    try {
        const history = await historyService.getHistoryByHardwareId(req.params.hId);
        res.json(history);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

router.post('/', async (req, res) => {
    try {
        const { hardware_id, from_location, to_location, moved_by } = req.body;
        if (!hardware_id || !from_location || !to_location) {
            return res.status(400).json({ error: 'Missing required fields: hardware_id, from_location, to_location' });
        }
        const newHistory = await historyService.createHistory(hardware_id, from_location, to_location, moved_by);
        res.status(201).json(newHistory);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
