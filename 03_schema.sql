-- 03_schema.sql
-- Create tables and indexes

-- Set the role to ensure ownership
SET ROLE hardware_admin;

-- Table: users
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    u_name VARCHAR(255) NOT NULL
);

-- Table: hardware
CREATE TABLE IF NOT EXISTS hardware (
    h_id SERIAL PRIMARY KEY,
    h_name VARCHAR(255) NOT NULL,
    init_del_date DATE NOT NULL,
    init_del_loc VARCHAR(255) NOT NULL,
    vendor VARCHAR(255),
    prev_loc VARCHAR(255),
    current_loc VARCHAR(255) NOT NULL
);

-- Table: hardware_history
CREATE TABLE IF NOT EXISTS hardware_history (
    history_id SERIAL PRIMARY KEY,
    h_id INTEGER NOT NULL REFERENCES hardware(h_id) ON DELETE CASCADE,
    moved_from VARCHAR(255) NOT NULL,
    moved_to VARCHAR(255) NOT NULL,
    moved_by INTEGER REFERENCES users(user_id),
    moved_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_hardware_current_loc ON hardware(current_loc);
CREATE INDEX IF NOT EXISTS idx_hardware_history_h_id ON hardware_history(h_id);
CREATE INDEX IF NOT EXISTS idx_hardware_history_moved_at ON hardware_history(moved_at);

-- Reset role
RESET ROLE;
