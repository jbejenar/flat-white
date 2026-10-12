import { spawnSync } from "node:child_process";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

describe("ward release policy", () => {
  it("allows only qualified null-to-ward enrichment, preserving other comparison gates", () => {
    const result = spawnSync(
      "python3",
      [
        "-c",
        `
import json,sys,copy
from pathlib import Path
sys.path.insert(0,sys.argv[1])
from compare_release_files import allowed_change
r=json.loads(Path('config/nsw-wards.json').read_text())
d={'boundaries':{'lga':{'code':'lga2a2057496fb7','name':'Camden Council'}},'geocode':{'type':'PROPERTY CENTROID','reliability':2}}
c={'path':'boundaries.ward','beforePresent':True,'before':None,'afterPresent':True,'after':{'name':'North Ward'}}
def check(change=c,after=d,state='NSW',registry=r):
 return allowed_change(change,state,'2026.08','1.0.0','1.1.0',d,after,registry)
assert check()
assert not check(state='VIC')
assert not check(registry=None)
assert not check(change={**c,'after':{'name':'Invented Ward'}})
assert not check(change={**c,'before':{'name':'South Ward'}})
assert not check(change={**c,'path':'postcode'})
for point in [None,{'type':'GAP GEOCODE','reliability':2},{'type':'PROPERTY CENTROID','reliability':3}]:
 assert not check(after={**d,'geocode':point})
assert not check(after={**d,'boundaries':{'lga':{'code':'lga000000000000','name':'Camden Council'}}})
assert not check(after={**d,'boundaries':{'lga':{'code':'lga2a2057496fb7','name':'Incorrect name'}}})
`,
        resolve("scripts"),
      ],
      { encoding: "utf8" },
    );
    expect(result.status, result.stderr).toBe(0);
  });
  it("requires ward source bytes and every state report in the evidence inventory", () => {
    const result = spawnSync(
      "python3",
      [
        "-c",
        `
import sys,copy
sys.path.insert(0,sys.argv[1])
from release_evidence import validate_index,STATES
names=['source-lock.json','metadata.json','verification-report.json','verification-report.md','DOCUMENT-SCHEMA.md','comparison.json','comparison.md']
names += [f'{kind}-{state}.json' for kind in ['reconciliation','build-provenance','geocodes','wards'] for state in STATES]
names += [f'comparison-{state}.jsonl.gz' for state in STATES]
names += ['ward-source-lock.json','wards-camden-2024.json','NSW-WARD-SOURCES.md']
r={'formatVersion':1,'releaseVersion':'2026.08.3','sourceCommit':'a'*40,'schemaVersion':'1.1.0','wardSourceLock':'ward-source-lock.json','wardSourceFiles':['wards-camden-2024.json'],
 'files':[{'name':name,'bytes':1,'sha256':'b'*64} for name in names]}
assert validate_index(r)
for missing in ['wards-camden-2024.json','ward-source-lock.json','wards-NSW.json','NSW-WARD-SOURCES.md']:
 invalid={**r,'files':[f for f in r['files'] if f['name'] != missing]}
 try: validate_index(invalid)
 except ValueError: pass
 else: raise AssertionError(f'missing evidence accepted: {missing}')
`,
        resolve("scripts"),
      ],
      { encoding: "utf8" },
    );
    expect(result.status, result.stderr).toBe(0);
  });
});
