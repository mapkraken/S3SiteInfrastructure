-- migrate:up

-- Step 1: Add a duplicate `geom` column and copy data from `wkb_geometry`
ALTER TABLE public.census_block_groups_2024
ADD COLUMN IF NOT EXISTS geom geometry;

UPDATE public.census_block_groups_2024
SET geom = wkb_geometry
WHERE geom IS NULL;

-- Step 2: Recreate the view with *both* geometry fields
CREATE OR REPLACE VIEW public.census_block_groups_2024_view AS
SELECT
  ogc_fid,
  statefp AS "STATEFP",
  countyfp AS "COUNTYFP",
  tractce AS "TRACTCE",
  blkgrpce AS "BLKGRPCE",
  geoid AS "GEOID",
  geoidfq AS "GEOIDFQ",
  namelsad AS "NAMELSAD",
  mtfcc AS "MTFCC",
  funcstat AS "FUNCSTAT",
  aland AS "ALAND",
  awater AS "AWATER",
  intptlat AS "INTPTLAT",
  intptlon AS "INTPTLON",
  gid AS "GID",
  wkb_geometry,
  geom
FROM public.census_block_groups_2024;

-- Optional: Analyze the view for planner stats
ANALYZE public.census_block_groups_2024_view;

-- migrate:down

-- Step 1: Drop the view
DROP VIEW IF EXISTS public.census_block_groups_2024_view;

-- Step 2: Drop the `geom` column if it was added
ALTER TABLE public.census_block_groups_2024
DROP COLUMN IF EXISTS geom;
