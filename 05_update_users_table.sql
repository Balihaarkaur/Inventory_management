-- 05_update_users_table.sql
-- Safely adds email and created_at columns to the users table
-- Optimized for empty tables (no data preservation needed for constraints)

ALTER TABLE users 
    ADD COLUMN IF NOT EXISTS email VARCHAR(255) UNIQUE NOT NULL,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
