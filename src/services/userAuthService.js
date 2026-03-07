const pool = require('../db');
const { OAuth2Client } = require('google-auth-library');
const axios = require('axios');

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);


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

async function handleGoogleLogin(idOrAccessToken) {
    let email;
    try {
        // Try to verify token as standard IdToken first (Works for Mobile)
        const ticket = await client.verifyIdToken({
            idToken: idOrAccessToken,
            audience: process.env.GOOGLE_CLIENT_ID, 
        });
        const payload = ticket.getPayload();
        email = payload.email.toLowerCase();
    } catch (idTokenError) {
        // If it fails, treat it as a raw Access Token (Common for Web without serverClientId)
        try {
            const userInfoResponse = await axios.get('https://www.googleapis.com/oauth2/v3/userinfo', {
                headers: {
                    Authorization: `Bearer ${idOrAccessToken}`
                }
            });
            email = userInfoResponse.data.email.toLowerCase();
        } catch (accessTokenError) {
            throw new Error("Invalid Google Token (Not a valid ID or Access Token)");
        }
    }
    const allowedDomain = process.env.ALLOWED_DOMAIN || 'blauplug.com';
    const allowedTestEmail = process.env.ALLOWED_TEST_EMAIL; // Accept a specific testing email via .env
    
    // Domain Check (bypassed if email matches exact test email)
    if (!email.endsWith(`@${allowedDomain}`) && email !== allowedTestEmail) {
        throw new Error(`Only @${allowedDomain} emails are allowed`);
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
    handleGoogleLogin
};
