# Hardware Tracking Database Setup

This directory contains the SQL scripts and configuration examples for setting up the PostgreSQL database for the Hardware Tracking System.

## Prerequisites

- PostgreSQL (v13 or higher recommended) installed and running.
- `psql` command-line tool available.

## Setup Instructions

Run the scripts in the following order.

### 1. Create Role
Run as superuser (e.g., `postgres`).

```bash
psql -U postgres -f 00_create_role.sql
```

### 2. Create Database
Run as superuser.

```bash
psql -U postgres -f 01_create_database.sql
```

### 3. Security Setup
Run as superuser (or database owner) to apply security restrictions.

```bash
psql -U postgres -d hardware_management -f 02_security_setup.sql
```

### 4. Schema Creation
Run as `hardware_admin` or superuser. The script sets the role to `hardware_admin` internally to ensure ownership.

```bash
psql -U hardware_admin -d hardware_management -h localhost -f 03_schema.sql
```

### 5. Triggers
Run as `hardware_admin`.

```bash
psql -U hardware_admin -d hardware_management -h localhost -f 04_triggers.sql
```

## Security Best Practices implemented

1.  **Strict Role**: `hardware_admin` has no superuser or create db privileges.
2.  **Least Privilege**: Public access to the implementation database is fully revoked.
3.  **Owner Separation**: Database and objects are owned by `hardware_admin`, not `postgres`.
4.  **Environment Variables**: Credentials should be stored in a `.env` file.
5.  **SSL**: `DB_SSL_MODE=require` is recommended.

## Connection String Example

```
postgresql://hardware_admin:DatabaseSql@localhost:5432/hardware_management?sslmode=require
```

## Testing the Application

1. **Start the Backend:**
   Open a terminal in the root folder (`Inventory_management`) and run:
   ```bash
   npm start
   # or
   node src/server.js
   ```
   *You should see "Database connected successfully" and "Server is running on port 3000".*

2. **Start the Frontend (Mobile App):**
   Open another terminal in the `frontend` folder (`Inventory_management/frontend`) and run:
   ```bash
   flutter run
   ```
   *Note: For the best experience analyzing barcodes, use a physical device or a mobile emulator with camera routing enabled rather than the Chrome Web target.*

3. **Verify Functionality:**
   - Scan any barcode; the backend currently mocks a creation if the hardware doesn't exist.
   - You can also test with the pre-seeded item which has the barcode `BARCODE_1`.
