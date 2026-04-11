export interface ManifestFile {
  key: string;
  records: number;
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
  product: "address";
  version: string;
  created_at: string;
  pipeline: ManifestPipeline;
  source: ManifestSource;
  files: ManifestFile[];
  total_records: number;
  index: ManifestIndex;
}

interface BuildAddressManifestOptions {
  version: string;
  createdAt: string;
  pipeline: ManifestPipeline;
  source: ManifestSource;
  files: ManifestFile[];
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
    product: "address",
    version: options.version,
    created_at: options.createdAt,
    pipeline: options.pipeline,
    source: options.source,
    files: options.files,
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

  const files = parseFiles(manifest.files);
  const totalRecords = parseNonNegativeInteger(manifest.total_records, "total_records");

  if (!isRecord(manifest.index)) {
    throw new Error("Manifest field must be an object: index");
  }
  const sourceKeys = parseSourceKeys(manifest.index.source_keys);

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
    total_records: totalRecords,
    index: {
      mappings_key: parseString(manifest.index.mappings_key, "index.mappings_key"),
      settings,
      source_keys: sourceKeys,
    },
  };
}
