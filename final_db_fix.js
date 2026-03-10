const pool = require('./src/db');

async function finalFix() {
    try {
        console.log('👷 Finalizing database setup...');

        // Ensure email column exists (already checked, but good for safety)
        await pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255) UNIQUE');

        // Insert mock_user for frontend compatibility
        await pool.query(`
            INSERT INTO users (user_id, u_name, email) 
            VALUES (1, 'mock_user', 'mock@example.com') 
            ON CONFLICT (user_id) DO UPDATE SET email = 'mock@example.com'
        `);
        console.log('✅ Mock user (ID: 1) verified/inserted.');

        const res = await pool.query('SELECT * FROM users');
        console.log('📋 Current Users:', res.rows);

    } catch (err) {
        console.error('❌ Error:', err.message);
    } finally {
        await pool.end();
    }
}

finalFix();
