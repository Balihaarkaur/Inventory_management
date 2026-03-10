-- patch.sql
-- Fixes schema mismatch between SQL setup and Node.js backend

SET ROLE hardware_admin;

-- Drop constraints that might conflict
ALTER TABLE hardware_history DROP CONSTRAINT IF EXISTS hardware_history_h_id_fkey;

-- Rename and update columns in hardware table
ALTER TABLE hardware RENAME COLUMN h_id TO hardware_id;
ALTER TABLE hardware RENAME COLUMN h_name TO hardware_name;
ALTER TABLE hardware DROP COLUMN IF EXISTS init_del_date;
ALTER TABLE hardware DROP COLUMN IF EXISTS init_del_loc;

ALTER TABLE hardware ADD COLUMN IF NOT EXISTS barcode_value VARCHAR(255) UNIQUE;
ALTER TABLE hardware ADD COLUMN IF NOT EXISTS current_location_id INTEGER;
ALTER TABLE hardware ADD COLUMN IF NOT EXISTS status VARCHAR(50);

-- Make hardware_id the primary key if it isn't (it should be since we renamed it)

-- Fix movement_logs / hardware_history
ALTER TABLE IF EXISTS hardware_history RENAME TO movement_logs;

-- Add or rename columns in movement_logs 
ALTER TABLE movement_logs RENAME COLUMN history_id TO log_id;
ALTER TABLE movement_logs RENAME COLUMN h_id TO hardware_id;
ALTER TABLE movement_logs RENAME COLUMN moved_from TO from_location;
ALTER TABLE movement_logs RENAME COLUMN moved_to TO to_location;
-- moved_by is already there

-- Add foreign key constraint back
ALTER TABLE movement_logs ADD CONSTRAINT movement_logs_hardware_id_fkey FOREIGN KEY (hardware_id) REFERENCES hardware(hardware_id) ON DELETE CASCADE;

-- If barcode_value is null for existing rows, generate a dummy one
UPDATE hardware SET barcode_value = 'BARCODE_' || hardware_id WHERE barcode_value IS NULL;

-- Fix trigger for movement_logs
CREATE OR REPLACE FUNCTION update_hardware_location()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE hardware
    SET
       prev_loc = current_loc,
       current_loc = CAST(NEW.to_location AS VARCHAR)
    WHERE hardware_id = NEW.hardware_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add email column to users if it doesn't exist
ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255) UNIQUE;

-- Insert mock user, required by frontend 'markLocation'
INSERT INTO users (user_id, u_name, email) VALUES (1, 'mock_user', 'mock@example.com') ON CONFLICT DO NOTHING;

RESET ROLE;
