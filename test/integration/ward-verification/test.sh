#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../.."
export DATABASE_URL="${DATABASE_URL:-postgres://postgres:postgres@localhost:${POSTGRES_PORT:-5432}/gnaf}"
node --input-type=module - <<'JS'
import assert from 'node:assert/strict';
import { readFile, mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createHash } from 'node:crypto';
import { gzipSync } from 'node:zlib';
import { wardContext, registryIdentity } from './dist/ward-sources.js';
import { WardDiagnostics, WardOutputVerifier } from './dist/ward-diagnostics.js';
import { createWardLookup } from './dist/ward-spatial.js';
import { verifyGzippedState } from './dist/verification-report.js';

const context = await wardContext('2026.02');
const directory = await mkdtemp(join(tmpdir(), 'flat-white-ward-verification-'));
const base = JSON.parse((await readFile('fixtures/expected-output.ndjson', 'utf8')).split('\n')[0]);
const council = context.lock.registry.councils[0];
const doc = (id, longitude, name) => ({
  ...base, _id: id, state: 'NSW',
  geocode: { ...base.geocode, latitude: -37.797, longitude },
  boundaries: { ...base.boundaries, lga: {code: council.lgaCode, name: council.lgaName}, ward: name ? {name} : null },
});
const north = doc('north', 144.897, 'North Ward');
const central = doc('central', 144.898, 'Central Ward');
const row = reason => ({ward_source_id: council.id, ward_reason: reason});
let spatial;
try {
  await assert.rejects(createWardLookup(context.lock, context.directory, undefined), /DATABASE_URL/);
  await assert.rejects(createWardLookup(context.lock, directory, process.env.DATABASE_URL), /ENOENT/);
  spatial = await createWardLookup(context.lock, context.directory, process.env.DATABASE_URL);
  const point = (longitude, latitude=-37.797) => ({sourceId: council.id, longitude, latitude});
  assert.deepEqual(await spatial.lookup([point(144.897), point(144.898), point(144.8975), point(145.1)]), [
    {matches: 1, name: 'North Ward'}, {matches: 1, name: 'Central Ward'},
    {matches: 2, name: 'Central Ward'}, {matches: 0, name: null},
  ]);
  const diagnostics = new WardDiagnostics('2026.02', context.lock);
  diagnostics.observe(row('matched'), north); diagnostics.observe(row('matched'), central);
  const report = diagnostics.report();
  async function compressed(docs) {
    const path = join(directory, 'addresses.gz');
    await writeFile(path, gzipSync(docs.map(d => JSON.stringify(d)+'\n').join('')));
    return verifyGzippedState(path, 'NSW', undefined, undefined, {
      sourceVersion: '2026.02', count: 2,
      wards: {lock: context.lock, report, lookup: spatial.lookup},
    });
  }
  assert.equal((await compressed([north, central])).passed, true);
  const swapped = [doc('north', 144.897, 'Central Ward'), doc('central', 144.898, 'North Ward')];
  const bad = await compressed(swapped);
  assert.equal(bad.passed, false);
  assert.match(bad.qualityDiagnostics.join(' '), /Ward/);
  // A false null can keep 99% aggregate coverage. Geometry must still reject it.
  const falseNull = doc('false-null', 144.897, null);
  const almost = new WardDiagnostics('2026.02', context.lock);
  for (let i=0;i<99;i++) almost.observe(row('matched'), north);
  almost.observe(row('unmatched'), falseNull);
  assert.equal(almost.report().passed, true);
  const verifier = new WardOutputVerifier(context.lock, almost.report(), '2026.02', spatial.lookup);
  for (let i=0;i<99;i++) await verifier.observe(north);
  await verifier.observe(falseNull);
  assert.equal(await verifier.passed(), false);
  const sharedEdge = doc('shared-edge', 144.8975, null);
  const misreported = new WardOutputVerifier(context.lock, almost.report(), '2026.02', spatial.lookup);
  const correctOverlap = new WardDiagnostics('2026.02', context.lock);
  for (let i=0;i<99;i++) {
    await misreported.observe(north);
    correctOverlap.observe(row('matched'), north);
  }
  await misreported.observe(sharedEdge);
  assert.equal(await misreported.passed(), false); // ambiguous must not be called unmatched
  correctOverlap.observe(row('ambiguous'), sharedEdge);
  const overlapCheck = new WardOutputVerifier(context.lock, correctOverlap.report(), '2026.02', spatial.lookup);
  for (let i=0;i<99;i++) await overlapCheck.observe(north);
  await overlapCheck.observe(sharedEdge);
  assert.equal(await overlapCheck.passed(), true);
  // Exercise automatic batch flush and the final partial batch with actual SQL.
  const many = new WardDiagnostics('2026.02', context.lock);
  for (let i=0;i<1001;i++) many.observe(row('matched'), north);
  const bounded = new WardOutputVerifier(context.lock, many.report(), '2026.02', spatial.lookup);
  for (let i=0;i<1001;i++) await bounded.observe(north);
  assert.equal(await bounded.passed(), true);
  await spatial.close(); spatial = undefined;

  // Synthetic source variations test holes, MultiPolygons and fail-closed import.
  const shapes = JSON.parse(await readFile(join(context.directory, council.source.file), 'utf8'));
  const hole = [[144.8968,-37.7972],[144.8972,-37.7972],[144.8972,-37.7968],[144.8968,-37.7968],[144.8968,-37.7972]];
  for (const feature of shapes.features) {
    if (feature.properties.ward === 'North Ward') feature.geometry.coordinates.push(hole);
    if (feature.properties.ward === 'South Ward') feature.geometry = {type: 'MultiPolygon', coordinates: [feature.geometry.coordinates]};
  }
  async function snapshot() {
    const bytes = Buffer.from(JSON.stringify(shapes));
    await writeFile(join(directory, council.source.file), bytes);
    const lock = structuredClone(context.lock);
    Object.assign(lock.registry.councils[0].source, {bytes: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex')});
    lock.identity = registryIdentity(lock.registry);
    return lock;
  }
  spatial = await createWardLookup(await snapshot(), directory, process.env.DATABASE_URL);
  assert.deepEqual(await spatial.lookup([point(144.897), point(144.897, -37.7972), point(144.897, -37.9)]), [
    {matches: 0, name: null}, {matches: 1, name: 'North Ward'}, {matches: 1, name: 'South Ward'},
  ]);
  await spatial.close(); spatial = undefined;
  shapes.features[0].geometry.coordinates = [[[144.8965,-37.798],[144.8975,-37.796],[144.8975,-37.798],[144.8965,-37.796],[144.8965,-37.798]]];
  await assert.rejects(createWardLookup(await snapshot(), directory, process.env.DATABASE_URL), /Invalid or out-of-bounds/);
} finally {
  await spatial?.close();
  await rm(directory, {recursive:true, force:true});
}
console.log('[ward-verification] PASS: locked polygons, swapped names, false null at 99%, bounded batches, duplicate parts, shared edges, holes, MultiPolygons and invalid/missing sources');
JS
