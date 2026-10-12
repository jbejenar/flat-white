#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../.."
export DATABASE_URL="${DATABASE_URL:-postgres://postgres:postgres@localhost:${POSTGRES_PORT:-5432}/gnaf}"
# The normal 451-address fixture remains Victorian. This transaction-only overlay
# places one address under a synthetic NSW crosswalk, then rolls everything back.
node --input-type=module - <<'JS'
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import postgres from 'postgres';
import { wardContext, importWardSources } from './dist/ward-sources.js';
import { WardDiagnostics } from './dist/ward-diagnostics.js';
import { composeDocument } from './dist/flatten.js';
const connection=postgres(process.env.DATABASE_URL,{max:1,onnotice:()=>{}});
const sql=await connection.reserve();
const context=await wardContext('2026.02');
const text=path=>readFileSync(path,'utf8').replaceAll('__SCHEMA_VERSION__','202602');
const prep=text('sql/address_geocodes_prep.sql')+'\n'+text('sql/address_full_prep.sql');
const target='GAVIC411087566';
async function change(query){ for await(const batch of sql.unsafe(query).cursor(1)) void batch; }
async function both(reason,ward,passed){
  await sql.unsafe(prep); // DDL only
  const hashes=[];
  for(const path of ['sql/address_full.sql','sql/address_full_main.sql']){
    const hash=createHash('sha256');let count=0;let selected;
    const diagnostics=new WardDiagnostics('2026.02',context.lock);
    for await(const batch of sql.unsafe(text(path)).cursor(100)) for(const row of batch){
      const doc=composeDocument(row,'2026.02');diagnostics.observe(row,doc);
      count++;hash.update(JSON.stringify(doc)+'\n');
      if(doc._id===target) selected={reason:row.ward_reason,ward:doc.boundaries.ward?.name??null};
    }
    assert.equal(count,451);assert.deepEqual(selected,{reason,ward});
    assert.equal(diagnostics.report().passed,passed);
    hashes.push(hash.digest('hex'));
  }
  assert.equal(hashes[0],hashes[1]);
}
try {
  await sql.unsafe('BEGIN');
  await importWardSources(sql,context.lock,context.directory);
  await change(`UPDATE gnaf_202602.address_principals SET state='NSW' WHERE gnaf_pid='${target}' RETURNING gnaf_pid`);
  await change(`UPDATE admin_bdys_202602.local_government_areas SET lga_pid='lga2a2057496fb7',full_name='Camden Council'
    WHERE ST_Covers(geom,(SELECT geom FROM gnaf_202602.address_principals WHERE gnaf_pid='${target}')) RETURNING lga_pid`);
  await both('matched','North Ward',true); // duplicated polygon parts remain one logical ward
  await sql.unsafe('SAVEPOINT overlap');
  await change(`INSERT INTO tmp_ward_polygons SELECT source_id,'camden-2024:central','Central Ward',geom
    FROM tmp_ward_polygons WHERE ward_id='camden-2024:north' LIMIT 1 RETURNING ward_id`);
  await both('ambiguous',null,false);
  await sql.unsafe('ROLLBACK TO SAVEPOINT overlap');
  await sql.unsafe('SAVEPOINT gap');
  await change("DELETE FROM tmp_ward_polygons RETURNING ward_id");
  await both('unmatched',null,false);
  await sql.unsafe('ROLLBACK TO SAVEPOINT gap');
  await sql.unsafe('SAVEPOINT imprecise');
  await change("UPDATE raw_gnaf_202602.address_site_geocode SET reliability_code=3 WHERE address_site_pid='411236384' RETURNING address_site_geocode_pid");
  await both('insufficient_precision',null,false);
  await sql.unsafe('ROLLBACK TO SAVEPOINT imprecise');
  await sql.unsafe('SAVEPOINT unknown');
  await change("UPDATE raw_gnaf_202602.address_site_geocode SET geocode_type_code='UNK' WHERE address_site_pid='411236384' RETURNING address_site_geocode_pid");
  await both('insufficient_precision',null,false);
  await sql.unsafe('ROLLBACK TO SAVEPOINT unknown');
  await sql.unsafe('SAVEPOINT fallback');
  await change("UPDATE raw_gnaf_202602.address_site_geocode SET date_retired='2026-02-01' WHERE address_site_pid='411236384' RETURNING address_site_geocode_pid");
  await both('insufficient_precision',null,false);
  await sql.unsafe('ROLLBACK TO SAVEPOINT fallback');
  await change("UPDATE admin_bdys_202602.local_government_areas SET lga_pid='lga000000000000',full_name='Unsupported Council' WHERE lga_pid='lga2a2057496fb7' RETURNING lga_pid");
  await both('unsupported',null,false); // geometry alone must never bypass the crosswalk
  await change("UPDATE admin_bdys_202602.local_government_areas SET lga_pid='lga605d8cdb0eb8',full_name='Council of the City of Sydney' WHERE lga_pid='lga000000000000' RETURNING lga_pid");
  await both('undivided',null,false);
} finally {
  await sql.unsafe('ROLLBACK');sql.release();await connection.end();
}
console.log('[wards] PASS: both SQL paths, multipart deduplication, overlap/gap nulls, precision, fallback exclusion, exact crosswalk and undivided councils');
JS
