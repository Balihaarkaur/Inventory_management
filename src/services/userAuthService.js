const pool = require('../db');
const axios = require('axios');
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

async function handleMicrosoftLogin(accessToken) {
    let email;
    try {
        // Call Microsoft Graph API to get the user's profile
        const userInfoResponse = await axios.get('https://graph.microsoft.com/v1.0/me', {
            headers: {
                Authorization: `Bearer ${accessToken}`
            }
        });

        // Microsoft returns the email in either 'mail' or 'userPrincipalName'
        const rawEmail = userInfoResponse.data.mail || userInfoResponse.data.userPrincipalName;
        if (!rawEmail) {
            throw new Error("No email found in Microsoft profile.");
        }
        email = rawEmail.toLowerCase();

    } catch (error) {
        console.error('[AUTH] Graph API Error:', error.response?.data || error.message);
        throw new Error("Invalid Microsoft Token or Graph API rejection.");
    }

    // Default organization lock
    const allowedDomain = process.env.ALLOWED_DOMAIN || 'blauplug.com';
    const isAllowedDomain = email.endsWith(`@${allowedDomain}`);
    const isAllowedTestEmail = email.toLowerCase() === (process.env.ALLOWED_TEST_EMAIL || '').toLowerCase();

    console.log(`[AUTH] User Email: ${email}`);
    console.log(`[AUTH] Allowed Domain: ${allowedDomain}`);
    console.log(`[AUTH] Is Allowed Domain: ${isAllowedDomain}`);

    if (isAllowedTestEmail) {
        console.log(`[AUTH] Bypassing domain check for allowed test email: ${email}`);
    }

    // Domain Check 
    if (!isAllowedDomain && !isAllowedTestEmail) {
        console.warn(`[AUTH] Unauthorized domain login attempt: ${email}`);
        throw new Error(`Only @${allowedDomain} and authorized testing emails are allowed`);
    }

    const dbClient = await pool.connect();
    try {
        await dbClient.query('BEGIN');

        const findUserQuery = 'SELECT * FROM users WHERE email = $1';
        const findUserResult = await dbClient.query(findUserQuery, [email]);

        if (findUserResult.rows.length > 0) {
            await dbClient.query('COMMIT');
            return {
                action: 'EXISTING_USER',
                user: findUserResult.rows[0]
            };
        }

        const u_name = extractNameFromEmail(email);
        const insertUserQuery = `
            INSERT INTO users (u_name, email) 
            VALUES ($1, $2) 
            RETURNING *
        `;
        const insertUserResult = await dbClient.query(insertUserQuery, [u_name, email]);

        await dbClient.query('COMMIT');

        return {
            action: 'USER_CREATED',
            user: insertUserResult.rows[0]
        };
    } catch (error) {
        await dbClient.query('ROLLBACK');
        throw error;
    } finally {
        dbClient.release();
    }
}

module.exports = {
    handleUserLogin,
    handleMicrosoftLogin
};
