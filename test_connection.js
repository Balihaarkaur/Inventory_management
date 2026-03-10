const pool = require('./src/db');

async function testConnection() {
    try {
        console.log('🔗 Testing connection and simple table creation...');
        await pool.query('CREATE TABLE IF NOT EXISTS test_table (id SERIAL PRIMARY KEY, name TEXT)');
        console.log('✅ test_table created successfully');

        await pool.query('DROP TABLE test_table');
        console.log('✅ test_table dropped successfully');
    } catch (err) {
        console.error('❌ Error:', err.message);
    } finally {
        await pool.end();
    }
}

testConnection();
