const pool = require('../db');

const getAllUsers = async () => {
    const result = await pool.query('SELECT * FROM users ORDER BY user_id ASC');
    return result.rows;
};

const getUserById = async (id) => {
    const result = await pool.query('SELECT * FROM users WHERE user_id = $1', [id]);
    return result.rows[0];
};

const createUser = async (name) => {
    const result = await pool.query(
        'INSERT INTO users (u_name) VALUES ($1) RETURNING *',
        [name]
    );
    return result.rows[0];
};

const updateUser = async (id, name) => {
    const result = await pool.query(
        'UPDATE users SET u_name = $1 WHERE user_id = $2 RETURNING *',
        [name, id]
    );
    return result.rows[0];
};

const deleteUser = async (id) => {
    const result = await pool.query(
        'DELETE FROM users WHERE user_id = $1 RETURNING *',
        [id]
    );
    return result.rows[0];
};

module.exports = {
    getAllUsers,
    getUserById,
    createUser,
    updateUser,
    deleteUser,
};
