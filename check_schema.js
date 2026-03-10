const pool = require('./src/db');

async function checkSchema() {
    try {
        console.log('🔍 Checking users table schema...');
        const res = await pool.query(`
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'users'
        `);

        const columns = res.rows.map(r => r.column_name);
        console.log('📋 Columns in users table:', columns);

        if (!columns.includes('email')) {
            console.error('❌ CRITICAL ERROR: "email" column is missing from "users" table!');
            console.log('💡 Fix: Run patch.sql or ensure setup_real_schema.js completed successfully.');
        } else {
            console.log('✅ "email" column exists.');
        }

        console.log('\n🔍 Checking hardware table schema...');
        const res2 = await pool.query(`
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'hardware'
        `);
        const hwColumns = res2.rows.map(r => r.column_name);
        console.log('📋 Columns in hardware table:', hwColumns);

    } catch (err) {
        console.error('❌ Database connection error:', err.message);
    } finally {
        await pool.end();
    }
}

checkSchema();
