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
    const result = await pool.query(
        'INSERT INTO hardware (hardware_name, barcode_value, current_location_id, status) VALUES ($1, $2, $3, $4) RETURNING *',
        [hardware_name, barcode_value, current_location_id, status]
    );
    return result.rows[0];
};

const updateHardware = async (id, hardware_name, barcode_value, current_location_id, status) => {
    const result = await pool.query(
        'UPDATE hardware SET hardware_name = COALESCE($1, hardware_name), barcode_value = COALESCE($2, barcode_value), current_location_id = COALESCE($3, current_location_id), status = COALESCE($4, status) WHERE hardware_id = $5 RETURNING *',
        [hardware_name, barcode_value, current_location_id, status, id]
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
