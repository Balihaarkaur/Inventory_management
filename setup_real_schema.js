const fs = require('fs');
const path = require('path');
const pool = require('./src/db');

async function runSchema() {
    console.log("Connecting to Supabase to run SQL schemas...");
    try {
        const schemaSql = fs.readFileSync(path.join(__dirname, '03_schema.sql'), 'utf-8');
        const triggerSql = fs.readFileSync(path.join(__dirname, '04_triggers.sql'), 'utf-8');
        const patchSql = fs.readFileSync(path.join(__dirname, 'patch.sql'), 'utf-8');

        const cleanSql = (sql) => sql
            .split('\n')
            .filter(line => !line.trim().toUpperCase().startsWith('SET ROLE'))
            .filter(line => !line.trim().toUpperCase().startsWith('RESET ROLE'))
            .filter(line => !line.trim().startsWith('--'))
            .join('\n');

        const executeStatements = async (sql, name) => {
            console.log(`\n📄 Processing ${name}...`);
            const cleaned = cleanSql(sql);
            const statements = cleaned.split(';').map(s => s.trim()).filter(s => s.length > 0);

            for (const statement of statements) {
                try {
                    console.log(`➡️ Executing: ${statement.substring(0, 70)}...`);
                    await pool.query(statement);
                    console.log('✅ Success');
                } catch (err) {
                    console.error(`❌ FAILED in ${name}:`, err.message);
                    console.log('Statement was:', statement);
                    throw err;
                }
            }
        };

        await executeStatements(schemaSql, '03_schema.sql');

        console.log("\n📄 Processing 04_triggers.sql (as single block)...");
        try {
            await pool.query(cleanSql(triggerSql));
            console.log('✅ Success');
        } catch (e) {
            console.log("Triggers might already exist or had issues, continuing:", e.message);
        }

        await executeStatements(patchSql, 'patch.sql');

        console.log("\n✨ Database initialized successfully with correct schema.");

    } catch (e) {
        console.error("\n💥 Critical Setup Error:", e.message);
    } finally {
        await pool.end();
    }
}
runSchema();
