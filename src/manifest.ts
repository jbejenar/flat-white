import { VERSION } from "./index.js";
import { ASGS_YEAR } from "./schema.js";

export interface ManifestFile {
  key: string;
  records: number;
  bytes: number;
  sha256: string;
}

/** Release evidence is downloadable, but never an address ingestion input. */
export interface ManifestArtifact {
  key: string;
  bytes: number;
  sha256: string;
}

export interface ManifestPipeline {
  repo: string;
  commit: string;
  run_id: string;
}

export interface ManifestSource {
  name: string;
  release: string;
  url: string;
}

export interface ManifestIndexSettings {
  number_of_shards: number;
  number_of_replicas: number;
}

export interface ManifestIndex {
  mappings_key: string;
  settings: ManifestIndexSettings;
  source_keys: string[];
}

export interface AddressManifestV2 {
  manifest_version: 2;
  /** Absent only on historical manifests created before schema 1.0.0. */
  schema_version?: string;
  asgs_year?: number;
  product: "address";
  version: string;
  created_at: string;
  pipeline: ManifestPipeline;
  source: ManifestSource;
  files: ManifestFile[];
  artifacts?: ManifestArtifact[];
  total_records: number;
  index: ManifestIndex;
}

interface BuildAddressManifestOptions {
  version: string;
  createdAt: string;
  pipeline: ManifestPipeline;
  source: ManifestSource;
  files: ManifestFile[];
  artifacts?: ManifestArtifact[];
  sourceKeys: string[];
  mappingsKey?: string;
  settings?: ManifestIndexSettings;
}

const DEFAULT_SETTINGS: ManifestIndexSettings = {
  number_of_shards: 1,
  number_of_replicas: 0,
};

function recordsForSourceKeys(files: ManifestFile[], sourceKeys: string[]): number {
  const filesByKey = new Map(files.map((file) => [file.key, file] as const));

  return sourceKeys.reduce((sum, key) => {
    const file = filesByKey.get(key);
    if (file == null) {
      throw new Error(`Manifest source key is missing from files[]: ${key}`);
    }
    return sum + file.records;
  }, 0);
}

export function buildAddressManifestV2(options: BuildAddressManifestOptions): AddressManifestV2 {
  const mappingsKey = options.mappingsKey ?? `data/address/${options.version}/mappings.json`;
  const settings = options.settings ?? DEFAULT_SETTINGS;

  return {
    manifest_version: 2,
    schema_version: VERSION,
    asgs_year: ASGS_YEAR,
    product: "address",
    version: options.version,
    created_at: options.createdAt,
    pipeline: options.pipeline,
    source: options.source,
    files: options.files,
    ...(options.artifacts === undefined ? {} : { artifacts: options.artifacts }),
    total_records: recordsForSourceKeys(options.files, options.sourceKeys),
    index: {
      mappings_key: mappingsKey,
      settings,
      source_keys: options.sourceKeys,
    },
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function parseNonNegativeInteger(value: unknown, field: string): number {
  if (!Number.isInteger(value) || (value as number) < 0) {
    throw new Error(`Manifest field must be a non-negative integer: ${field}`);
  }
  return value as number;
}

function parseString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(`Manifest field must be a non-empty string: ${field}`);
  }
  return value;
}

function parseFiles(value: unknown): ManifestFile[] {
  if (!Array.isArray(value)) {
    throw new Error("Manifest field must be an array: files");
  }

  return value.map((item, index) => {
    if (!isRecord(item)) {
      throw new Error(`Manifest files[${index}] must be an object`);
    }

    return {
      key: parseString(item.key, `files[${index}].key`),
      records: parseNonNegativeInteger(item.records, `files[${index}].records`),
      bytes: parseNonNegativeInteger(item.bytes, `files[${index}].bytes`),
      sha256: parseString(item.sha256, `files[${index}].sha256`),
    };
  });
}

function parseSourceKeys(value: unknown): string[] {
  if (!Array.isArray(value)) {
    throw new Error("Manifest field must be an array: index.source_keys");
  }

  return value.map((item, index) => parseString(item, `index.source_keys[${index}]`));
}

export function validateAddressManifestV2(
  manifest: unknown,
  expectedSourceKeys?: string[],
): AddressManifestV2 {
  if (!isRecord(manifest)) {
    throw new Error("Manifest must be an object");
  }
  if (manifest.manifest_version !== 2) {
    throw new Error("Manifest version must be 2");
  }
  if (manifest.product !== "address") {
    throw new Error("Manifest product must be address");
  }

  // Keep historical manifests readable without falsely assigning them the
  // current geography. New manifests carry both markers as one contract.
  const schemaMetadata: Pick<AddressManifestV2, "schema_version" | "asgs_year"> = {};
  if (manifest.schema_version !== undefined || manifest.asgs_year !== undefined) {
    schemaMetadata.schema_version = parseString(manifest.schema_version, "schema_version");
    schemaMetadata.asgs_year = parseNonNegativeInteger(manifest.asgs_year, "asgs_year");
    if (schemaMetadata.asgs_year === 0) throw new Error("Manifest asgs_year must be positive");
  }

  const files = parseFiles(manifest.files);
  const totalRecords = parseNonNegativeInteger(manifest.total_records, "total_records");

  if (!isRecord(manifest.index)) {
    throw new Error("Manifest field must be an object: index");
  }
  const sourceKeys = parseSourceKeys(manifest.index.source_keys);
  const mappingsKey = parseString(manifest.index.mappings_key, "index.mappings_key");
  const artifacts = parseArtifacts(manifest.artifacts);
  const keys = [
    ...files.map((file) => file.key),
    mappingsKey,
    ...(artifacts ?? []).map((a) => a.key),
  ];
  if (new Set(keys).size !== keys.length || new Set(sourceKeys).size !== sourceKeys.length)
    throw new Error("Manifest contains duplicate or overlapping file, evidence or source keys");

  if (expectedSourceKeys != null) {
    if (sourceKeys.length !== expectedSourceKeys.length) {
      throw new Error("Manifest source_keys length does not match the expected contract");
    }

    expectedSourceKeys.forEach((expectedKey, index) => {
      if (sourceKeys[index] !== expectedKey) {
        throw new Error(`Manifest source_keys[${index}] does not match the expected contract`);
      }
    });
  }

  if (!isRecord(manifest.index.settings)) {
    throw new Error("Manifest field must be an object: index.settings");
  }

  const settings: ManifestIndexSettings = {
    number_of_shards: parseNonNegativeInteger(
      manifest.index.settings.number_of_shards,
      "index.settings.number_of_shards",
    ),
    number_of_replicas: parseNonNegativeInteger(
      manifest.index.settings.number_of_replicas,
      "index.settings.number_of_replicas",
    ),
  };

  const derivedTotal = recordsForSourceKeys(files, sourceKeys);
  if (derivedTotal !== totalRecords) {
    throw new Error(
      `Manifest total_records mismatch: expected ${derivedTotal} from index.source_keys, got ${totalRecords}`,
    );
  }

  return {
    manifest_version: 2,
    product: "address",
    version: parseString(manifest.version, "version"),
    ...schemaMetadata,
    created_at: parseString(manifest.created_at, "created_at"),
    pipeline: {
      repo: parseString((manifest.pipeline as Record<string, unknown>).repo, "pipeline.repo"),
      commit: parseString((manifest.pipeline as Record<string, unknown>).commit, "pipeline.commit"),
      run_id: parseString((manifest.pipeline as Record<string, unknown>).run_id, "pipeline.run_id"),
    },
    source: {
      name: parseString((manifest.source as Record<string, unknown>).name, "source.name"),
      release: parseString((manifest.source as Record<string, unknown>).release, "source.release"),
      url: parseString((manifest.source as Record<string, unknown>).url, "source.url"),
    },
    files,
    ...(artifacts === undefined ? {} : { artifacts }),
    total_records: totalRecords,
    index: {
      mappings_key: mappingsKey,
      settings,
      source_keys: sourceKeys,
    },
  };
}

function parseArtifacts(value: unknown): ManifestArtifact[] | undefined {
  if (value === undefined) return undefined;
  if (!Array.isArray(value)) throw new Error("Manifest artifacts must be an array");
  return value.map((item, index) => {
    if (!isRecord(item)) throw new Error(`Invalid manifest artifact ${index}`);
    const key = parseString(item.key, `artifacts[${index}].key`);
    const sha256 = parseString(item.sha256, `artifacts[${index}].sha256`);
    if (
      !/^data\/address\/[0-9-]+\/[A-Za-z0-9][A-Za-z0-9_.-]*\.(json|md|jsonl\.gz)$/.test(key) ||
      !/^[a-f0-9]{64}$/.test(sha256)
    )
      throw new Error(`Invalid evidence key or checksum: ${key}`);
    return { key, bytes: parseNonNegativeInteger(item.bytes, `artifacts[${index}].bytes`), sha256 };
  });
}
