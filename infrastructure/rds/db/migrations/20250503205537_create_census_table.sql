-- migrate:up
CREATE TABLE public.census_block_groups_2024 ();

ALTER TABLE public.census_block_groups_2024 ADD ogc_fid serial4 NOT NULL;
ALTER TABLE public.census_block_groups_2024 ADD statefp varchar(2) NULL;
ALTER TABLE public.census_block_groups_2024 ADD countyfp varchar(3) NULL;
ALTER TABLE public.census_block_groups_2024 ADD tractce varchar(6) NULL;
ALTER TABLE public.census_block_groups_2024 ADD blkgrpce varchar(1) NULL;
ALTER TABLE public.census_block_groups_2024 ADD geoid varchar(12) NULL;
ALTER TABLE public.census_block_groups_2024 ADD geoidfq varchar(21) NULL;
ALTER TABLE public.census_block_groups_2024 ADD namelsad varchar(13) NULL;
ALTER TABLE public.census_block_groups_2024 ADD mtfcc varchar(5) NULL;
ALTER TABLE public.census_block_groups_2024 ADD funcstat varchar(1) NULL;
ALTER TABLE public.census_block_groups_2024 ADD aland numeric(14) NULL;
ALTER TABLE public.census_block_groups_2024 ADD awater numeric(14) NULL;
ALTER TABLE public.census_block_groups_2024 ADD intptlat varchar(11) NULL;
ALTER TABLE public.census_block_groups_2024 ADD intptlon varchar(12) NULL;
ALTER TABLE public.census_block_groups_2024 ADD wkb_geometry geometry(multipolygon, 4326) NULL;
ALTER TABLE public.census_block_groups_2024 ADD gid int4 NULL;

-- Ensure geometry column is indexed for pg_tileserv
CREATE INDEX ON public.census_block_groups_2024 USING GIST (wkb_geometry);

-- Ensure table statistics are up to date
ANALYZE public.census_block_groups_2024;

-- migrate:down
DROP TABLE IF EXISTS public.census_block_groups_2024;
