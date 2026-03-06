-- 01_create_database.sql
-- Create database hardware_management owned by hardware_admin
-- Note: This script cannot be run inside a transaction block.

SELECT 'CREATE DATABASE hardware_management OWNER hardware_admin'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'hardware_management')\gexec
