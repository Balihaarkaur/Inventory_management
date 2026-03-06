const pool = require('../db');

async function handleHardwareScan(hardwareCode) {
    if (!hardwareCode) {
        throw new Error('Hardware code is required');
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const findQuery = 'SELECT * FROM hardware WHERE barcode_value = $1';
        const findResult = await client.query(findQuery, [hardwareCode]);

        if (findResult.rows.length > 0) {
            await client.query('COMMIT');
            return {
                step: 2,
                status: "HARDWARE_FOUND",
                hardware: findResult.rows[0]
            };
        }

        const insertQuery = `
            INSERT INTO hardware (hardware_name, barcode_value, current_location_id, status, current_loc)
            VALUES ($1, $2, 1, 'IN_STOCK', 'Unknown')
            RETURNING *
        `;
        const insertResult = await client.query(insertQuery, [hardwareCode, hardwareCode]);

        await client.query('COMMIT');

        return {
            step: 2,
            status: "HARDWARE_CREATED",
            hardware: insertResult.rows[0]
        };
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
}

async function moveHardware(hardwareId, newLocationId, movedBy) {
    if (!hardwareId || !newLocationId || !movedBy) {
        throw new Error('hardware_id, new_location_id, and moved_by are required');
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const hardwareQuery = 'SELECT current_location_id FROM hardware WHERE hardware_id = $1';
        const hardwareRes = await client.query(hardwareQuery, [hardwareId]);

        if (hardwareRes.rows.length === 0) {
            throw new Error(`Hardware with ID ${hardwareId} not found`);
        }

        const oldLocationId = hardwareRes.rows[0].current_location_id;

        const updateQuery = 'UPDATE hardware SET current_location_id = $1 WHERE hardware_id = $2 RETURNING *';
        await client.query(updateQuery, [newLocationId, hardwareId]);

        const historyQuery = `
            INSERT INTO movement_logs (hardware_id, from_location, to_location, moved_by)
            VALUES ($1, $2, $3, $4)
        `;
        await client.query(historyQuery, [hardwareId, oldLocationId, newLocationId, String(movedBy)]);

        await client.query('COMMIT');

        return {
            success: true,
            step: 2,
            status: "HARDWARE_MOVED",
            hardware_id: hardwareId,
            from: oldLocationId,
            to: newLocationId
        };
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
}

module.exports = {
    handleHardwareScan,
    moveHardware
};
