const pool = require('../db');

const getAllHistory = async () => {
    const result = await pool.query('SELECT * FROM movement_logs ORDER BY moved_at DESC');
    return result.rows;
};

const getHistoryByHardwareId = async (hardwareId) => {
    const result = await pool.query('SELECT * FROM movement_logs WHERE hardware_id = $1 ORDER BY moved_at DESC', [hardwareId]);
    return result.rows;
};

const createHistory = async (hardware_id, from_location, to_location, moved_by) => {
    const result = await pool.query(
        'INSERT INTO movement_logs (hardware_id, from_location, to_location, moved_by) VALUES ($1, $2, $3, $4) RETURNING *',
        [hardware_id, from_location, to_location, moved_by]
    );
    return result.rows[0];
};

module.exports = {
    getAllHistory,
    getHistoryByHardwareId,
    createHistory,
};
