const pool = require('./src/db');

async function listTables() {
    try {
        console.log('🔍 Listing all tables in public schema...');
        const res = await pool.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
        `);

        console.log('📋 Tables found:', res.rows.map(r => r.table_name));

        const res2 = await pool.query('SELECT current_database(), current_user');
        console.log('🔗 Connected to:', res2.rows[0]);

    } catch (err) {
        console.error('❌ Error:', err.message);
    } finally {
        await pool.end();
    }
}

listTables();
