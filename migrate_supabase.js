const pool = require('./src/db');

async function migrateSupabase() {
    try {
        console.log("Connecting to Supabase...");
        
        // 1. Create Users Table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS users (
                user_id SERIAL PRIMARY KEY,
                u_name VARCHAR(255) NOT NULL,
                email VARCHAR(255) UNIQUE NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log("✅ Users table created");

        // 2. Create Locations Table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS locations (
                location_id SERIAL PRIMARY KEY,
                location_name VARCHAR(255) NOT NULL,
                address TEXT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log("✅ Locations table created");

        // 3. Create Hardware Inventory Table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS hardware_inventory (
                hardware_id SERIAL PRIMARY KEY,
                hardware_name VARCHAR(255) NOT NULL,
                hardware_code VARCHAR(255) UNIQUE NOT NULL,
                description TEXT,
                current_location_id INTEGER REFERENCES locations(location_id),
                status VARCHAR(50) DEFAULT 'available',
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log("✅ Hardware Inventory table created");

        // 4. Create Movement History Table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS movement_history (
                movement_id SERIAL PRIMARY KEY,
                hardware_id INTEGER REFERENCES hardware_inventory(hardware_id),
                previous_location_id INTEGER REFERENCES locations(location_id),
                new_location_id INTEGER REFERENCES locations(location_id),
                moved_by INTEGER REFERENCES users(user_id),
                movement_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                notes TEXT
            );
        `);
        console.log("✅ Movement History table created");

        // 5. Insert Default Locations
        await pool.query(`
            INSERT INTO locations (location_id, location_name, address)
            VALUES 
                (1, 'Pune', 'Pune Warehouse Main Hub'),
                (2, 'Mumbai', 'Mumbai Logistics Center'),
                (3, 'Bangalore', 'Bangalore Tech Park Storage')
            ON CONFLICT (location_id) DO NOTHING;
        `);
        
        // Reset location ID sequence since we hardcoded 1, 2, 3
        await pool.query(`SELECT setval('locations_location_id_seq', 3);`);
        console.log("✅ Default Locations seeded");

        // 6. Insert Mock Hardware Data (to test scanning)
        await pool.query(`
            INSERT INTO hardware_inventory (hardware_name, hardware_code, current_location_id)
            VALUES 
                ('Dell XPS 15 Laptop', '12345678', 1),
                ('Logitech MX Master 3 Mouse', '87654321', 2),
                ('ThinkPad T14 Gen 2', 'B08F9S3X', 1)
            ON CONFLICT (hardware_code) DO NOTHING;
        `);
        console.log("✅ Mock Hardware seeded");

        console.log("🎉 Supabase Migration Complete!");

    } catch (error) {
        console.error("Migration Error:", error);
    } finally {
        await pool.end();
    }
}

migrateSupabase();
