/**
 * flat-white — Structured progress logging.
 *
 * Emits structured JSON log lines to stderr for both human monitoring
 * and machine parsing (e.g. jq, CI log aggregators).
 *
 * Each line is valid JSON with a human-readable `message` field.
 */

/** Structured log event types. */
export type ProgressEvent = "stage_start" | "progress" | "stage_end" | "error";

/** A single structured log entry. */
export interface ProgressEntry {
  timestamp: string;
  stage: string;
  event: ProgressEvent;
  message: string;
  elapsed_s?: number;
  rows?: number;
  percent?: number;
  error?: string;
}

export interface ProgressLoggerOptions {
  /** Minimum interval between progress updates in ms (default: 1000). */
  minInterval?: number;
  /** Output writer (default: process.stderr.write). */
  writer?: (line: string) => void;
}

/**
 * Structured progress logger for pipeline stages.
 *
 * Usage:
 *   const logger = new ProgressLogger();
 *   logger.stageStart("flatten");
 *   logger.progress("flatten", { rows: 50000, percent: 12 });
 *   logger.stageEnd("flatten");
 */
export class ProgressLogger {
  private stageTimers = new Map<string, number>();
  private lastEmit = new Map<string, number>();
  private minInterval: number;
  private writer: (line: string) => void;

  constructor(opts?: ProgressLoggerOptions) {
    this.minInterval = opts?.minInterval ?? 1000;
    this.writer = opts?.writer ?? ((line: string) => process.stderr.write(line));
  }

  /** Emit a stage_start event. */
  stageStart(stage: string): void {
    this.stageTimers.set(stage, Date.now());
    this.emit({
      timestamp: new Date().toISOString(),
      stage,
      event: "stage_start",
      message: `Stage: ${stage} started`,
    });
  }

  /**
   * Emit a progress event (debounced by minInterval).
   * Returns true if the event was emitted, false if debounced.
   */
  progress(stage: string, fields: { rows?: number; percent?: number; message?: string }): boolean {
    const now = Date.now();
    const last = this.lastEmit.get(stage) ?? 0;
    if (now - last < this.minInterval) return false;

    this.lastEmit.set(stage, now);
    const startTime = this.stageTimers.get(stage);
    const elapsed_s = startTime !== undefined ? Math.round((now - startTime) / 1000) : undefined;

    this.emit({
      timestamp: new Date().toISOString(),
      stage,
      event: "progress",
      message: fields.message ?? this.formatProgress(stage, fields),
      elapsed_s,
      rows: fields.rows,
      percent: fields.percent,
    });
    return true;
  }

  /** Emit a stage_end event. */
  stageEnd(stage: string, fields?: { rows?: number; message?: string }): void {
    const startTime = this.stageTimers.get(stage);
    const elapsed_s =
      startTime !== undefined ? Math.round((Date.now() - startTime) / 1000) : undefined;

    this.emit({
      timestamp: new Date().toISOString(),
      stage,
      event: "stage_end",
      message:
        fields?.message ??
        `Stage: ${stage} completed${elapsed_s !== undefined ? ` (${elapsed_s}s)` : ""}`,
      elapsed_s,
      rows: fields?.rows,
    });

    this.stageTimers.delete(stage);
    this.lastEmit.delete(stage);
  }

  /** Emit an error event. */
  error(stage: string, error: string): void {
    const startTime = this.stageTimers.get(stage);
    const elapsed_s =
      startTime !== undefined ? Math.round((Date.now() - startTime) / 1000) : undefined;

    this.emit({
      timestamp: new Date().toISOString(),
      stage,
      event: "error",
      message: `Stage: ${stage} failed — ${error}`,
      elapsed_s,
      error,
    });
  }

  private emit(entry: ProgressEntry): void {
    this.writer(JSON.stringify(entry) + "\n");
  }

  private formatProgress(stage: string, fields: { rows?: number; percent?: number }): string {
    const parts = [`Stage: ${stage}`];
    if (fields.percent !== undefined) parts.push(`${fields.percent}%`);
    if (fields.rows !== undefined) parts.push(`${fields.rows.toLocaleString()} rows`);
    return parts.join(" — ");
  }
}
