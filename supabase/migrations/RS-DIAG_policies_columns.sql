-- DIAGNOSTIC: Inspect actual column names in the policies table.
-- Run this to verify column names before applying RS-057.

SELECT column_name, data_type
  FROM information_schema.columns
 WHERE table_name = 'policies'
 ORDER BY ordinal_position;
