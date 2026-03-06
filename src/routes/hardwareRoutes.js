const express = require('express');
const { body, param } = require('express-validator');
const router = express.Router();
const hardwareService = require('../services/hardwareService');
const asyncHandler = require('../utils/asyncHandler');
const validate = require('../middleware/validator');

router.get('/', asyncHandler(async (req, res) => {
    const hardware = await hardwareService.getAllHardware();
    res.status(200).json({
        success: true,
        count: hardware.length,
        data: hardware
    });
}));

router.get('/:id', [
    param('id').isInt().withMessage('ID must be an integer').toInt(),
    validate
], asyncHandler(async (req, res) => {
    const item = await hardwareService.getHardwareById(req.params.id);

    if (!item) {
        return res.status(404).json({
            success: false,
            error: { message: `Hardware item with ID ${req.params.id} not found` }
        });
    }

    res.status(200).json({
        success: true,
        data: item
    });
}));

router.post('/', [
    body('hardware_name').trim().notEmpty().withMessage('Hardware name is required').isString(),
    body('barcode_value').trim().notEmpty().withMessage('Barcode value is required').isString(),
    body('current_location_id').isInt().withMessage('Current location ID must be an integer').toInt(),
    body('status').optional().trim().isString(),
    validate
], asyncHandler(async (req, res) => {
    const { hardware_name, barcode_value, current_location_id, status } = req.body;

    const newItem = await hardwareService.createHardware(hardware_name, barcode_value, current_location_id, status);

    res.status(201).json({
        success: true,
        data: newItem
    });
}));

router.patch('/:id', [
    param('id').isInt().withMessage('ID must be an integer').toInt(),
    body('hardware_name').optional().trim().notEmpty().isString(),
    body('barcode_value').optional().trim().notEmpty().isString(),
    body('current_location_id').optional().isInt().toInt(),
    body('status').optional().trim().isString(),
    validate
], asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { hardware_name, barcode_value, current_location_id, status } = req.body;

    if (!hardware_name && !barcode_value && !current_location_id && !status) {
        return res.status(400).json({
            success: false,
            error: { message: 'At least one field must be provided for update' }
        });
    }

    const updatedItem = await hardwareService.updateHardware(id, hardware_name, barcode_value, current_location_id, status);

    if (!updatedItem) {
        return res.status(404).json({
            success: false,
            error: { message: `Hardware item with ID ${id} not found` }
        });
    }

    res.status(200).json({
        success: true,
        data: updatedItem
    });
}));

router.delete('/:id', [
    param('id').isInt().withMessage('ID must be an integer').toInt(),
    validate
], asyncHandler(async (req, res) => {
    const deletedItem = await hardwareService.deleteHardware(req.params.id);

    if (!deletedItem) {
        return res.status(404).json({
            success: false,
            error: { message: `Hardware item with ID ${req.params.id} not found` }
        });
    }

    res.status(200).json({
        success: true,
        message: 'Hardware item deleted successfully',
        data: deletedItem
    });
}));

module.exports = router;
