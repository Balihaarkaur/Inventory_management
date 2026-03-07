const pool = require('./src/db');

async function fixSequence() {
    try {
        const colName = 'user_id';
        console.log(`Checking sequence for ${colName}`);
        
        // Fix sequence
        const query = `
            SELECT setval(
                pg_get_serial_sequence('users', '${colName}'), 
                (SELECT COALESCE(MAX(${colName}), 1) FROM users)
            );
        `;
        const seqRes = await pool.query(query);
        console.log("Sequence updated:", seqRes.rows);
    } catch (e) {
        console.error(e);
    } finally {
        pool.end();
    }
}
fixSequence();
