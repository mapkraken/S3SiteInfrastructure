-- name: 001_create_koop_db
-- description: Creates the `koop` database.
-- created: 2025-04-11

-- @UP
-- This section will be executed when applying the migration
CREATE DATABASE koop;

-- @DOWN
-- This section will be executed when rolling back the migration
DROP DATABASE koop;
