-- migrate:up
ALTER TABLE public.territories
ADD COLUMN salesforceid CHAR(18);

-- migrate:down
ALTER TABLE public.territories
DROP COLUMN salesforceid;

