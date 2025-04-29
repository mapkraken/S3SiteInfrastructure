-- name: 002_enable_postgis
-- description: Enables the PostGIS extension in the koop database.
-- created: 2025-04-11

-- @UP
CREATE EXTENSION IF NOT EXISTS postgis;

-- @DOWN
DROP EXTENSION IF EXISTS postgis;
