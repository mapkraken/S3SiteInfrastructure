-- migrate:up
GRANT INSERT, UPDATE, DELETE ON TABLE public.territories TO koopuser;

-- migrate:down
REVOKE INSERT, UPDATE, DELETE ON TABLE public.territories FROM koopuser;
