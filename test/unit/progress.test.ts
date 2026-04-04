/**
 * Unit tests for progress.ts — structured progress logging.
 */

import { describe, it, expect, vi, beforeEach } from "vitest";
import { ProgressLogger } from "../../src/progress.js";
import type { ProgressEntry } from "../../src/progress.js";

function createLogger(minInterval = 0) {
  const lines: ProgressEntry[] = [];
  const writer = (line: string) => {
    lines.push(JSON.parse(line.trimEnd()));
  };
  const logger = new ProgressLogger({ minInterval, writer });
  return { logger, lines };
}

describe("ProgressLogger", () => {
  describe("stageStart", () => {
    it("emits a stage_start event", () => {
      const { logger, lines } = createLogger();
      logger.stageStart("flatten");
      expect(lines).toHaveLength(1);
      expect(lines[0].event).toBe("stage_start");
      expect(lines[0].stage).toBe("flatten");
      expect(lines[0].message).toContain("flatten");
      expect(lines[0].timestamp).toBeTruthy();
    });
  });

  describe("progress", () => {
    it("emits a progress event with rows and percent", () => {
      const { logger, lines } = createLogger();
      logger.stageStart("flatten");
      logger.progress("flatten", { rows: 50000, percent: 12 });
      expect(lines).toHaveLength(2);
      const prog = lines[1];
      expect(prog.event).toBe("progress");
      expect(prog.rows).toBe(50000);
      expect(prog.percent).toBe(12);
      expect(prog.elapsed_s).toBeDefined();
    });

    it("debounces progress events by minInterval", () => {
      const { logger, lines } = createLogger(5000);
      logger.stageStart("flatten");
      const emitted1 = logger.progress("flatten", { rows: 100 });
      const emitted2 = logger.progress("flatten", { rows: 200 });
      // First progress emits, second is debounced
      expect(emitted1).toBe(true);
      expect(emitted2).toBe(false);
      expect(lines).toHaveLength(2); // stage_start + 1 progress
    });

    it("emits progress with custom message", () => {
      const { logger, lines } = createLogger();
      logger.stageStart("download");
      logger.progress("download", { message: "Downloading file 2/3" });
      expect(lines[1].message).toBe("Downloading file 2/3");
    });
  });

  describe("stageEnd", () => {
    it("emits a stage_end event with elapsed time", () => {
      const { logger, lines } = createLogger();
      logger.stageStart("verify");
      logger.stageEnd("verify", { rows: 451 });
      expect(lines).toHaveLength(2);
      const end = lines[1];
      expect(end.event).toBe("stage_end");
      expect(end.stage).toBe("verify");
      expect(end.rows).toBe(451);
      expect(end.elapsed_s).toBeDefined();
      expect(end.message).toContain("verify");
      expect(end.message).toContain("completed");
    });

    it("accepts a custom message", () => {
      const { logger, lines } = createLogger();
      logger.stageStart("compress");
      logger.stageEnd("compress", { message: "Compressed 3 files" });
      expect(lines[1].message).toBe("Compressed 3 files");
    });
  });

  describe("error", () => {
    it("emits an error event", () => {
      const { logger, lines } = createLogger();
      logger.stageStart("flatten");
      logger.error("flatten", "Connection refused");
      expect(lines).toHaveLength(2);
      const err = lines[1];
      expect(err.event).toBe("error");
      expect(err.error).toBe("Connection refused");
      expect(err.message).toContain("failed");
      expect(err.elapsed_s).toBeDefined();
    });
  });

  describe("JSON output", () => {
    it("each line is valid JSON", () => {
      const rawLines: string[] = [];
      const logger = new ProgressLogger({
        minInterval: 0,
        writer: (line) => rawLines.push(line),
      });
      logger.stageStart("test");
      logger.progress("test", { rows: 100, percent: 50 });
      logger.stageEnd("test");

      for (const line of rawLines) {
        expect(() => JSON.parse(line)).not.toThrow();
      }
      expect(rawLines).toHaveLength(3);
    });
  });
});
