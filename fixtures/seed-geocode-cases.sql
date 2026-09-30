-- Synthetic schema 1.1.0 cases layered over four frozen fixture addresses.
-- Retain the original snapshot in seed-postgres.sql and historical reader samples.
BEGIN;
UPDATE raw_gnaf_202602.address_site_geocode
SET date_retired = '2026-02-01'
WHERE address_site_pid IN ('411236384', '411585778', '411814562', '411832680');

-- Three valid points: stable PID breaks the equal FCS/reliability tie.
-- Physical insertion order intentionally disagrees with selection order.
INSERT INTO raw_gnaf_202602.address_site_geocode
  (address_site_geocode_pid, date_created, address_site_pid, geocode_type_code,
   reliability_code, longitude, latitude)
VALUES
  ('FW_SITE_003', '2026-02-01', '411236384', 'PC', 2, 144.899, -37.799),
  ('FW_SITE_002', '2026-02-01', '411236384', 'FCS', 2, 144.898, -37.798),
  ('FW_SITE_001', '2026-02-01', '411236384', 'FCS', 2, 144.897, -37.797),
  -- NaN and out-of-bounds active points cannot become primary geometry.
  ('FW_SITE_004', '2026-02-01', '411814562', 'FCS', 1, 144.899, 'NaN'),
  ('FW_SITE_005', '2026-02-01', '411832680', 'PC', 2, 0, -37.798);

-- Identical defaults collapse, even when their source PIDs differ.
INSERT INTO raw_gnaf_202602.address_default_geocode
  (address_default_geocode_pid, date_created, address_detail_pid, geocode_type_code, longitude, latitude)
SELECT 'FW_DEFAULT_001', '2026-02-01', address_detail_pid, geocode_type_code, longitude, latitude
FROM raw_gnaf_202602.address_default_geocode
WHERE address_detail_pid = 'GAVIC411441273' AND date_retired IS NULL;

UPDATE raw_gnaf_202602.address_default_geocode
SET geocode_type_code = 'STL'
WHERE address_detail_pid = 'GAVIC411441273';
UPDATE raw_gnaf_202602.address_default_geocode
SET geocode_type_code = 'LOC'
WHERE address_detail_pid = 'GAVIC411670057';
-- Invalid default must remain null and be visible in the quality report.
UPDATE raw_gnaf_202602.address_default_geocode
SET longitude = 0
WHERE address_detail_pid = 'GAVIC411685451';
COMMIT;
