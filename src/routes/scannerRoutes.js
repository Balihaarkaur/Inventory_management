const express = require('express');
const router = express.Router();
const scannerService = require('../services/scannerService');
const asyncHandler = require('../utils/asyncHandler');

router.post('/hardware', asyncHandler(async (req, res) => {
    const { hardware_code } = req.body;

    if (!hardware_code) {
        return res.status(400).json({
            success: false,
            message: 'Hardware code is required'
        });
    }

    const result = await scannerService.handleHardwareScan(hardware_code);

    res.status(200).json({
        success: true,
        step: result.step,
        status: result.status,
        hardware: result.hardware
    });
}));

router.post('/move', asyncHandler(async (req, res) => {
    const { hardware_id, new_location_id, moved_by } = req.body;

    if (!hardware_id || !new_location_id || !moved_by) {
        return res.status(400).json({
            success: false,
            message: 'hardware_id, new_location_id, and moved_by are required'
        });
    }

    const result = await scannerService.moveHardware(hardware_id, new_location_id, moved_by);

    res.status(200).json({
        success: true,
        step: result.step,
        status: result.status,
        hardware_id: result.hardware_id,
        from: result.from,
        to: result.to
    });
}));

module.exports = router;
