-- 00_create_role.sql
-- Create role hardware_admin if not exists

DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'hardware_admin') THEN

      CREATE ROLE hardware_admin WITH
        LOGIN
        PASSWORD 'DatabaseSql'
        NOSUPERUSER
        NOCREATEDB
        NOCREATEROLE
        NOINHERIT;
   END IF;
END
$do$;
