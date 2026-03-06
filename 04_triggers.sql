-- 04_triggers.sql
-- Create trigger function and trigger

-- Set the role to ensure ownership
SET ROLE hardware_admin;

-- Trigger Function
CREATE OR REPLACE FUNCTION update_hardware_location()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE hardware
    SET
       prev_loc = current_loc,
       current_loc = NEW.moved_to

    WHERE h_id = NEW.h_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS trigger_update_location ON hardware_history;

-- Create Trigger
CREATE TRIGGER trigger_update_location
AFTER INSERT ON hardware_history
FOR EACH ROW
EXECUTE FUNCTION update_hardware_location();

-- Reset role
RESET ROLE;
