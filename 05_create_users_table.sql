-- 05_create_users_table.sql
-- Safely creates the users table with email and created_at columns

CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    u_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
