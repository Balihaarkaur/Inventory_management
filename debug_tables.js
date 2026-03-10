const pool = require('./src/db');

async function debugTables() {
    try {
        console.log('🔍 Checking ALL schemas and tables...');
        const res = await pool.query(`
            SELECT table_schema, table_name 
            FROM information_schema.tables 
            WHERE table_schema NOT IN ('information_schema', 'pg_catalog')
        `);

        console.log('📋 All Tables:', res.rows);

        const res2 = await pool.query('SELECT current_schemas(true)');
        console.log('🔍 Current search_path:', res2.rows[0]);

    } catch (err) {
        console.error('❌ Error:', err.message);
    } finally {
        await pool.end();
    }
}

debugTables();
