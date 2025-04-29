-- migrate:up

-- Install PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create koopuser (if not already existing)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_catalog.pg_roles WHERE rolname = 'koopuser'
    ) THEN
        CREATE USER koopuser WITH PASSWORD 'kooppass';
    END IF;
END $$;

-- Create territories table
CREATE TABLE IF NOT EXISTS public.territories (
    gid SERIAL PRIMARY KEY,
    name TEXT,
    geom GEOMETRY(POLYGON, 4326)
);

-- Seed initial data
INSERT INTO public.territories (name, geom)
VALUES 
    (
        'Tampa North',
        ST_SetSRID(ST_MakePolygon(ST_GeomFromText(
            'LINESTRING(
                -82.5 28.1,
                -82.2 28.1,
                -82.2 28.4,
                -82.5 28.4,
                -82.5 28.1
            )')), 4326)
    ),
    (
        'Tampa South',
        ST_SetSRID(ST_MakePolygon(ST_GeomFromText(
            'LINESTRING(
                -82.6 27.8,
                -82.3 27.8,
                -82.3 28.1,
                -82.6 28.1,
                -82.6 27.8
            )')), 4326)
    );

-- Grant privileges
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO koopuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO koopuser;

-- migrate:down

-- Remove the territories table
DROP TABLE IF EXISTS public.territories;

-- Drop koopuser role
DO $$
BEGIN
    IF EXISTS (
        SELECT FROM pg_catalog.pg_roles WHERE rolname = 'koopuser'
    ) THEN
        DROP USER koopuser;
    END IF;
END $$;

-- Remove PostGIS extension
DROP EXTENSION IF EXISTS postgis;
