const pool = require('../db');

const getAllHardware = async () => {
    const result = await pool.query('SELECT * FROM hardware ORDER BY hardware_id ASC');
    return result.rows;
};

const getHardwareById = async (id) => {
    const result = await pool.query('SELECT * FROM hardware WHERE hardware_id = $1', [id]);
    return result.rows[0];
};

const createHardware = async (hardware_name, barcode_value, current_location_id, status) => {
    // Map ID to a string name for the current_loc column (required by schema)
    const locationMap = { 1: 'Pune', 2: 'Mumbai', 3: 'Bangalore' };
    const current_loc = locationMap[current_location_id] || 'Unknown';

    const result = await pool.query(
        'INSERT INTO hardware (hardware_name, barcode_value, current_location_id, current_loc, status) VALUES ($1, $2, $3, $4, $5) RETURNING *',
        [hardware_name, barcode_value, current_location_id, current_loc, status]
    );
    return result.rows[0];
};

const updateHardware = async (id, hardware_name, barcode_value, current_location_id, status) => {
    let current_loc = null;
    if (current_location_id) {
        const locationMap = { 1: 'Pune', 2: 'Mumbai', 3: 'Bangalore' };
        current_loc = locationMap[current_location_id] || 'Unknown';
    }

    const result = await pool.query(
        'UPDATE hardware SET hardware_name = COALESCE($1, hardware_name), barcode_value = COALESCE($2, barcode_value), current_location_id = COALESCE($3, current_location_id), current_loc = COALESCE($4, current_loc), status = COALESCE($5, status) WHERE hardware_id = $6 RETURNING *',
        [hardware_name, barcode_value, current_location_id, current_loc, status, id]
    );
    return result.rows[0];
};

const deleteHardware = async (id) => {
    const result = await pool.query(
        'DELETE FROM hardware WHERE hardware_id = $1 RETURNING *',
        [id]
    );
    return result.rows[0];
};

module.exports = {
    getAllHardware,
    getHardwareById,
    createHardware,
    updateHardware,
    deleteHardware,
};
