-- Session-only tables: council wards are always imported after a base cache restore.
CREATE TEMP TABLE tmp_ward_sources (
  lga_code text PRIMARY KEY, lga_name text NOT NULL,
  source_id text NOT NULL, status text NOT NULL
);
CREATE TEMP TABLE tmp_ward_types (code text PRIMARY KEY);
CREATE TEMP TABLE tmp_ward_polygons (
  source_id text NOT NULL, ward_id text NOT NULL, name text NOT NULL,
  geom geometry(MultiPolygon,7844) NOT NULL
);
