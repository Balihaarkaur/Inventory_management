const pool = require('../db');

const extractNameFromEmail = (email) => {
    const localPart = email.split('@')[0];
    return localPart
        .split('.')
        .map(part => part.charAt(0).toUpperCase() + part.slice(1))
        .join(' ');
};

async function handleUserLogin(email) {
    const cleanEmail = email.toLowerCase();

    const emailRegex = /^[a-zA-Z0-9._%+-]+@blauplug\.com$/;
    if (!emailRegex.test(cleanEmail)) {
        throw new Error("Only @blauplug.com emails allowed");
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const findUserQuery = 'SELECT * FROM users WHERE email = $1';
        const findUserResult = await client.query(findUserQuery, [cleanEmail]);

        if (findUserResult.rows.length > 0) {
            await client.query('COMMIT');
            return {
                action: 'EXISTING_USER',
                user: findUserResult.rows[0]
            };
        }

        const u_name = extractNameFromEmail(cleanEmail);
        const insertUserQuery = `
            INSERT INTO users (u_name, email) 
            VALUES ($1, $2) 
            RETURNING *
        `;
        const insertUserResult = await client.query(insertUserQuery, [u_name, cleanEmail]);

        await client.query('COMMIT');

        return {
            action: 'USER_CREATED',
            user: insertUserResult.rows[0]
        };
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
}

module.exports = {
    handleUserLogin
};
