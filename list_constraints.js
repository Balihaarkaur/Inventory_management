const pool = require('./src/db');

async function listConstraints() {
    try {
        console.log('🔍 Listing all foreign key constraints...');
        const res = await pool.query(`
            SELECT conname, relname as table_name
            FROM pg_constraint c
            JOIN pg_class t ON c.conrelid = t.oid
            WHERE contype = 'f'
        `);

        console.log('📋 Constraints found:', res.rows);

    } catch (err) {
        console.error('❌ Error:', err.message);
    } finally {
        await pool.end();
    }
}

listConstraints();
