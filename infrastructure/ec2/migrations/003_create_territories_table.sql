CREATE TABLE territories (
	id SERIAL PRIMARY KEY,
  territory2_id VARCHAR(18) NOT NULL CHECK (char_length(territory2_id) = 18),
  
  name VARCHAR(100),
  geom GEOMETRY(MULTIPOLYGON, 4326)  -- Use MULTIPOLYGON if your territories are complex areas
);

CREATE INDEX territories_geom_idx ON territories USING GIST (geom);