-- 02_security_setup.sql
-- Connect to hardware_management database before running this script
-- \c hardware_management

-- Revoke all access from PUBLIC
REVOKE ALL ON DATABASE hardware_management FROM PUBLIC;

-- Revoke CREATE on schema public from PUBLIC
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Grant CONNECT to hardware_admin
GRANT CONNECT ON DATABASE hardware_management TO hardware_admin;

-- Grant USAGE and CREATE on schema public to hardware_admin
GRANT USAGE, CREATE ON SCHEMA public TO hardware_admin;

-- Set default privileges for tables and sequences to ensure hardware_admin has access to future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO hardware_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO hardware_admin;
