# Edge Cases — flat-white Fixtures

This document catalogues the edge case categories covered by the fixture data in `seed-postgres.sql`. Each category includes selection criteria and minimum counts.

## Categories

### 1. Standard addresses (100+)

- **Criteria:** VIC addresses with no flat, no level, no primary/secondary relationship
- **Purpose:** Baseline — simple house-on-a-street addresses across diverse postcodes
- **Selection:** Deterministic pseudo-random (ORDER BY md5(gnaf_pid))

### 2. Units / flats (80+)

- **Criteria:** `flat_number IS NOT NULL`
- **Purpose:** Test flat type expansion (UNIT, APT, SHOP, etc.) and secondary address handling
- **Examples:** "UNIT 704, 57 BAY STREET, PORT MELBOURNE VIC 3207"

### 3. Levels (50+)

- **Criteria:** `level_number IS NOT NULL`
- **Purpose:** Test level type expansion (LEVEL, FLOOR, etc.)
- **Examples:** Multi-storey commercial buildings, high-rises

### 4. Melbourne CBD dual-postcode — 3000 (25+)

- **Criteria:** `locality_name = 'MELBOURNE' AND postcode = '3000'`
- **Purpose:** Melbourne has two postcodes (3000 for street addresses, 3004 for GPO). gnaf-loader splits the locality boundary. Tests this edge case.

### 5. Melbourne CBD dual-postcode — 3004 (25+)

- **Criteria:** `locality_name = 'MELBOURNE' AND postcode = '3004'`
- **Purpose:** The other half of the Melbourne dual-postcode split.

### 6. Addresses with aliases (50+)

- **Criteria:** Address has entry in `address_alias_lookup` table
- **Purpose:** Test alias aggregation — addresses with alternative names (synonyms, historical)
- **Verification:** Check `address_alias_lookup.principal_pid` matches, `address_aliases` rows present

### 7. Secondary addresses (60+)

- **Criteria:** `primary_secondary = 'S'`
- **Purpose:** Child addresses (units within a building) — test secondary aggregation on parent
- **Verification:** Each secondary's primary exists in `address_secondary_lookup`

### 8. Primary addresses with secondaries (60+)

- **Criteria:** `primary_secondary = 'P'`
- **Purpose:** Parent addresses — test that `secondaries[]` array is populated correctly
- **Verification:** Each primary has entries in `address_secondary_lookup`

### 9. Multi-geocode addresses (50+)

- **Criteria:** Address has 3+ geocode types in `raw_gnaf.address_site_geocode`
- **Purpose:** Test `allGeocodes[]` array aggregation and primary geocode selection
- **Note:** Multi-geocode data is in raw tables, not yet in fixture (requires raw PSV subset — Tier 2)

### 10. Non-gazetted localities (20+)

- **Criteria:** `locality_class != 'GAZETTED LOCALITY'` (TOPOGRAPHIC LOCALITY, INDIGENOUS LOCATION, UNOFFICIAL SUBURB)
- **Purpose:** Edge case locality types that may have different boundary or naming characteristics

### 11. Ward-tagged addresses (30+)

- **Criteria:** `address_principal_admin_boundaries.ward_name IS NOT NULL`
- **Purpose:** Not all LGAs have wards — these test the ward boundary enrichment path

### 12. Lot number addresses (30+)

- **Criteria:** `lot_number IS NOT NULL AND number_first IS NULL`
- **Purpose:** Rural-style addresses without street numbers — "LOT 5 SMITH ROAD"

### 13. Building name addresses (30+)

- **Criteria:** `building_name IS NOT NULL`
- **Purpose:** Named buildings — "CHADSTONE SHOPPING CENTRE 1341 DANDENONG RD"

## Missing categories

The following categories from the ROADMAP are not represented in this fixture because the Feb 2026 VIC data doesn't contain them:

- **Retired addresses** — `date_retired IS NOT NULL` returns 0 rows in VIC Feb 2026. The dataset appears to have been cleaned of retired records. If future releases include retired addresses, re-extract with `scripts/extract-fixtures.sh`.

## Regeneration

To regenerate fixtures from a full VIC load:

```bash
./scripts/extract-fixtures.sh
```

This requires a running Postgres with a full VIC gnaf-loader load. See ROADMAP ticket P0.07.
