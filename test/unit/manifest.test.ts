import { describe, expect, it } from "vitest";
import { buildAddressManifestV2, validateAddressManifestV2 } from "../../src/manifest.js";

const baseFiles = [
  {
    key: "data/address/2026-02-7/vic.ndjson.gz",
    records: 3,
    bytes: 30,
    sha256: "vic",
  },
  {
    key: "data/address/2026-02-7/nsw.ndjson.gz",
    records: 2,
    bytes: 20,
    sha256: "nsw",
  },
  {
    key: "data/address/2026-02-7/all.ndjson.gz",
    records: 5,
    bytes: 50,
    sha256: "all",
  },
] as const;

describe("buildAddressManifestV2", () => {
  it("derives total_records from index.source_keys instead of files[]", () => {
    const manifest = buildAddressManifestV2({
      version: "2026-02-7",
      createdAt: "2026-04-11T12:00:00Z",
      pipeline: {
        repo: "jbejenar/flat-white",
        commit: "abc123",
        run_id: "123456789",
      },
      source: {
        name: "G-NAF",
        release: "February 2026",
        url: "https://data.gov.au/dataset/geocoded-national-address-file-g-naf",
      },
      files: [...baseFiles],
      sourceKeys: ["data/address/2026-02-7/all.ndjson.gz"],
    });

    expect(manifest.manifest_version).toBe(2);
    expect(manifest.total_records).toBe(5);
    expect(manifest.files.map((file) => file.records)).toEqual([3, 2, 5]);
    expect(manifest.index.source_keys).toEqual(["data/address/2026-02-7/all.ndjson.gz"]);
    expect(manifest.index.settings).toEqual({
      number_of_shards: 1,
      number_of_replicas: 0,
    });
  });
});

describe("validateAddressManifestV2", () => {
  it("accepts a phase 1 manifest whose source_keys match files[]", () => {
    const manifest = buildAddressManifestV2({
      version: "2026-02-7",
      createdAt: "2026-04-11T12:00:00Z",
      pipeline: {
        repo: "jbejenar/flat-white",
        commit: "abc123",
        run_id: "123456789",
      },
      source: {
        name: "G-NAF",
        release: "February 2026",
        url: "https://data.gov.au/dataset/geocoded-national-address-file-g-naf",
      },
      files: [...baseFiles],
      sourceKeys: ["data/address/2026-02-7/all.ndjson.gz"],
    });

    expect(() =>
      validateAddressManifestV2(manifest, ["data/address/2026-02-7/all.ndjson.gz"]),
    ).not.toThrow();
  });

  it("rejects manifests whose total_records still sums all files[]", () => {
    const manifest = {
      ...buildAddressManifestV2({
        version: "2026-02-7",
        createdAt: "2026-04-11T12:00:00Z",
        pipeline: {
          repo: "jbejenar/flat-white",
          commit: "abc123",
          run_id: "123456789",
        },
        source: {
          name: "G-NAF",
          release: "February 2026",
          url: "https://data.gov.au/dataset/geocoded-national-address-file-g-naf",
        },
        files: [...baseFiles],
        sourceKeys: ["data/address/2026-02-7/all.ndjson.gz"],
      }),
      total_records: 10,
    };

    expect(() => validateAddressManifestV2(manifest)).toThrow(
      "Manifest total_records mismatch: expected 5 from index.source_keys, got 10",
    );
  });

  it("rejects manifests whose source_keys are missing from files[]", () => {
    const manifest = {
      ...buildAddressManifestV2({
        version: "2026-02-7",
        createdAt: "2026-04-11T12:00:00Z",
        pipeline: {
          repo: "jbejenar/flat-white",
          commit: "abc123",
          run_id: "123456789",
        },
        source: {
          name: "G-NAF",
          release: "February 2026",
          url: "https://data.gov.au/dataset/geocoded-national-address-file-g-naf",
        },
        files: [...baseFiles],
        sourceKeys: ["data/address/2026-02-7/all.ndjson.gz"],
      }),
      index: {
        mappings_key: "data/address/2026-02-7/mappings.json",
        settings: {
          number_of_shards: 1,
          number_of_replicas: 0,
        },
        source_keys: ["data/address/2026-02-7/missing.ndjson.gz"],
      },
    };

    expect(() => validateAddressManifestV2(manifest)).toThrow(
      "Manifest source key is missing from files[]: data/address/2026-02-7/missing.ndjson.gz",
    );
  });

  it("rejects manifests whose phase 1 source key differs from all.ndjson.gz", () => {
    const manifest = buildAddressManifestV2({
      version: "2026-02-7",
      createdAt: "2026-04-11T12:00:00Z",
      pipeline: {
        repo: "jbejenar/flat-white",
        commit: "abc123",
        run_id: "123456789",
      },
      source: {
        name: "G-NAF",
        release: "February 2026",
        url: "https://data.gov.au/dataset/geocoded-national-address-file-g-naf",
      },
      files: [...baseFiles],
      sourceKeys: ["data/address/2026-02-7/vic.ndjson.gz"],
    });

    expect(() =>
      validateAddressManifestV2(manifest, ["data/address/2026-02-7/all.ndjson.gz"]),
    ).toThrow("Manifest source_keys[0] does not match the expected contract");
  });
});
