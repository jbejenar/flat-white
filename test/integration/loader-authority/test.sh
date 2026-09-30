#!/usr/bin/env bash
set -euo pipefail

# Exercise the pinned loader's real authority cleanup and electoral SQL in the
# production image. Small upstream regressions need no source downloads.
# Usage: bash test/integration/loader-authority/test.sh [flat-white:ci]
image="${1:-flat-white:ci}"

docker run --rm -i --network none --entrypoint bash "$image" -euo pipefail -s <<'CONTAINER'
test_file=/app/gnaf-loader/tests/test_authority_cleanup.py
# A missing test suite must fail, rather than silently running zero tests.
test -s "$test_file"
test -s /app/gnaf-loader/tests/test_admin_files.py
test -s /app/gnaf-loader/tests/test_boundary_dates.py
authority_db=$(mktemp -d /tmp/loader-authority.XXXXXX)
chown postgres:postgres "$authority_db"
su postgres -c "initdb --auth=trust --encoding=UTF8 -D '$authority_db'" >/dev/null
stop_postgres() {
  su postgres -c "pg_ctl -D '$authority_db' stop -m fast" >/dev/null || true
}
trap stop_postgres EXIT
su postgres -c "pg_ctl -D '$authority_db' -l '$authority_db/postgres.log' -o '-k /tmp -c listen_addresses=' start -w" >/dev/null
export GNAF_TEST_DSN='host=/tmp user=postgres dbname=postgres'
python3 "$test_file"
python3 /app/gnaf-loader/tests/test_admin_files.py
python3 /app/gnaf-loader/tests/test_boundary_dates.py
CONTAINER
