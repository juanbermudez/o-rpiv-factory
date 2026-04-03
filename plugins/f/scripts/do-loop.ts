#!/usr/bin/env npx tsx
/**
 * Compound Product Development Workflow — Do Loop Orchestrator
 *
 * Reads the project manifest, computes waves from the dependency graph,
 * spawns implementation agents in parallel per wave, then verification
 * agents (separate from implementers), and updates task status.
 *
 * Usage:
 *   npx tsx .claude/skills/product-dev-workflow/scripts/do-loop.ts <project-slug>
 *
 * Requirements:
 *   - @anthropic-ai/claude-agent-sdk installed
 *   - .resources/context/<project-slug>/manifest.json exists
 *   - All task context files exist
 *   - Git on main branch, clean working tree
 *
 * NOTE: This is a reference implementation. The @anthropic-ai/claude-agent-sdk
 * API surface may change between versions. If the `query` function signature
 * or message shape differs from what is used here, consult the installed
 * SDK's type definitions or README for the current contract.
 *
 * As of writing, the SDK is expected to expose:
 *   import { query } from "@anthropic-ai/claude-agent-sdk";
 * where `query()` returns an AsyncIterable of messages. Adjust the import
 * and iteration pattern if your installed version differs.
 */

import { query, type AgentDefinition } from "@anthropic-ai/claude-agent-sdk";
import * as fs from "node:fs";
import * as path from "node:path";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface TaskContext {
  task_id: string;
  project_slug: string;
  title: string;
  status: string;
  depends_on: string[];
  blocks: string[];
  wave: number;
  verification: {
    type: string;
    commands: string[];
    acceptance_criteria: string[];
  };
}

interface Wave {
  wave: number;
  tasks: string[];
  parallel: boolean;
}

interface Manifest {
  project_slug: string;
  linear_project_id: string;
  waves: Wave[];
  dependency_graph: Record<string, { blocks: string[]; blockedBy: string[] }>;
  spec: string;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function loadManifest(projectSlug: string): Manifest {
  const manifestPath = `.resources/context/${projectSlug}/manifest.json`;
  if (!fs.existsSync(manifestPath)) {
    throw new Error(`Manifest not found: ${manifestPath}`);
  }
  return JSON.parse(fs.readFileSync(manifestPath, "utf-8"));
}

function loadTaskContext(projectSlug: string, taskId: string): TaskContext {
  const taskPath = `.resources/context/${projectSlug}/tasks/${taskId}.json`;
  if (!fs.existsSync(taskPath)) {
    throw new Error(`Task context not found: ${taskPath}`);
  }
  return JSON.parse(fs.readFileSync(taskPath, "utf-8"));
}

function updateTaskStatus(
  projectSlug: string,
  taskId: string,
  status: string
) {
  const taskPath = `.resources/context/${projectSlug}/tasks/${taskId}.json`;
  const task = JSON.parse(fs.readFileSync(taskPath, "utf-8"));
  task.status = status;
  fs.writeFileSync(taskPath, JSON.stringify(task, null, 2));
}

function checkDependenciesResolved(
  projectSlug: string,
  taskId: string,
  manifest: Manifest
): string[] {
  const deps = manifest.dependency_graph[taskId]?.blockedBy ?? [];
  const unresolved: string[] = [];
  for (const dep of deps) {
    const depContext = loadTaskContext(projectSlug, dep);
    if (depContext.status !== "Done" && depContext.status !== "Archived") {
      unresolved.push(`${dep} (status: ${depContext.status})`);
    }
  }
  return unresolved;
}

function slugifyBranch(taskId: string, title: string): string {
  const slug = title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .slice(0, 40)
    .replace(/-$/, "");
  return `feat/${taskId.toLowerCase()}-${slug}`;
}

// ---------------------------------------------------------------------------
// Implementation agent spawner
// ---------------------------------------------------------------------------

async function spawnImplementer(
  projectSlug: string,
  taskId: string,
  manifest: Manifest
): Promise<{ taskId: string; success: boolean; error?: string }> {
  const taskContext = loadTaskContext(projectSlug, taskId);
  const contextPath = `.resources/context/${projectSlug}/tasks/${taskId}.json`;
  const specPath = manifest.spec;
  const criticalPatternsPath = "docs/solutions/patterns/critical-patterns.md";
  const branchName = slugifyBranch(taskId, taskContext.title);

  console.log(`  [impl] Starting ${taskId}: ${taskContext.title}`);

  try {
    let result: string = "";

    for await (const msg of query({
      prompt: `Implement task ${taskId}: ${taskContext.title}

Read your task context: ${contextPath}
Read critical patterns (REQUIRED): ${criticalPatternsPath}
Read PRD: ${specPath}

Follow your implementation-methodology skill.
Git branch: ${branchName}

After implementation:
1. Run quality gates: pnpm lint && pnpm typecheck && pnpm test
2. Push your branch: git push -u origin ${branchName}
3. Report what you implemented and any issues encountered`,
      options: {
        allowedTools: ["Read", "Edit", "Write", "Bash", "Grep", "Glob"],
        model: "sonnet",
        permissionMode: "acceptEdits",
      },
    })) {
      if ("result" in msg) result = msg.result;
    }

    console.log(`  [impl] Completed ${taskId}`);
    return { taskId, success: true };
  } catch (error) {
    console.error(`  [impl] Failed ${taskId}:`, error);
    return { taskId, success: false, error: String(error) };
  }
}

// ---------------------------------------------------------------------------
// Verification agent spawner
// ---------------------------------------------------------------------------

async function spawnVerifier(
  projectSlug: string,
  taskId: string,
  manifest: Manifest
): Promise<{ taskId: string; passed: boolean; report: string }> {
  const taskContext = loadTaskContext(projectSlug, taskId);
  const contextPath = `.resources/context/${projectSlug}/tasks/${taskId}.json`;
  const reportPath = `.resources/context/${projectSlug}/tasks/${taskId}-verify.md`;
  const criticalPatternsPath = "docs/solutions/patterns/critical-patterns.md";
  const branchName = slugifyBranch(taskId, taskContext.title);

  console.log(`  [verify] Starting ${taskId}`);

  try {
    let result: string = "";

    for await (const msg of query({
      prompt: `Verify task ${taskId}. You did NOT write this code.

Task context: ${contextPath}
Read critical patterns: ${criticalPatternsPath}
Write your verification report to: ${reportPath}

Follow your verification-methodology skill.
Check the branch for this task: ${branchName}
Run ALL quality gates. Check for anti-patterns. Verify acceptance criteria.

Report PASS or FAIL.`,
      options: {
        allowedTools: ["Bash", "Read", "Grep", "Glob"],
        model: "sonnet",
        permissionMode: "dontAsk",
      },
    })) {
      if ("result" in msg) result = msg.result;
    }

    // Read the verification report
    const report = fs.existsSync(reportPath)
      ? fs.readFileSync(reportPath, "utf-8")
      : result;

    const passed =
      report.toLowerCase().includes("pass") &&
      !report.toLowerCase().includes("fail");

    console.log(`  [verify] ${taskId}: ${passed ? "PASS" : "FAIL"}`);
    return { taskId, passed, report };
  } catch (error) {
    console.error(`  [verify] Failed ${taskId}:`, error);
    return { taskId, passed: false, report: String(error) };
  }
}

// ---------------------------------------------------------------------------
// Main do-loop
// ---------------------------------------------------------------------------

async function doLoop(projectSlug: string) {
  console.log(`\n=== Compound Do Loop: ${projectSlug} ===\n`);

  const manifest = loadManifest(projectSlug);
  console.log(`Project: ${manifest.project_slug}`);
  console.log(`Waves: ${manifest.waves.length}`);
  console.log(
    `Total tasks: ${manifest.waves.reduce((sum, w) => sum + w.tasks.length, 0)}`
  );

  for (const wave of manifest.waves) {
    console.log(`\n--- Wave ${wave.wave}: [${wave.tasks.join(", ")}] ---`);

    // Check dependencies for all tasks in this wave
    for (const taskId of wave.tasks) {
      const unresolved = checkDependenciesResolved(
        projectSlug,
        taskId,
        manifest
      );
      if (unresolved.length > 0) {
        console.error(
          `BLOCKED: ${taskId} has unresolved dependencies: ${unresolved.join(", ")}`
        );
        process.exit(1);
      }
    }

    // Update statuses to In Progress
    for (const taskId of wave.tasks) {
      updateTaskStatus(projectSlug, taskId, "In Progress");
    }

    // Spawn implementation agents in parallel
    console.log(`\nSpawning ${wave.tasks.length} implementation agent(s)...`);
    const implResults = await Promise.all(
      wave.tasks.map((taskId) =>
        spawnImplementer(projectSlug, taskId, manifest)
      )
    );

    // Check for implementation failures
    const implFailures = implResults.filter((r) => !r.success);
    if (implFailures.length > 0) {
      console.error(`\nImplementation failures:`);
      for (const f of implFailures) {
        console.error(`  ${f.taskId}: ${f.error}`);
        updateTaskStatus(projectSlug, f.taskId, "Blocked");
      }
      console.error(`\nStopping loop. Fix failures and re-run.`);
      process.exit(1);
    }

    // Spawn verification agents in parallel (DIFFERENT agents from implementers)
    const successfulTasks = implResults.filter((r) => r.success);
    console.log(
      `\nSpawning ${successfulTasks.length} verification agent(s)...`
    );
    const verifyResults = await Promise.all(
      successfulTasks.map((r) =>
        spawnVerifier(projectSlug, r.taskId, manifest)
      )
    );

    // Process verification results
    const verifyFailures = verifyResults.filter((r) => !r.passed);
    for (const vr of verifyResults) {
      if (vr.passed) {
        updateTaskStatus(projectSlug, vr.taskId, "Done");
        console.log(`  [done] ${vr.taskId}: Verified`);
      } else {
        updateTaskStatus(projectSlug, vr.taskId, "In Progress");
        console.log(`  [fail] ${vr.taskId}: Verification FAILED`);
        console.log(
          `    Report: .resources/context/${projectSlug}/tasks/${vr.taskId}-verify.md`
        );
      }
    }

    if (verifyFailures.length > 0) {
      console.error(
        `\nWave ${wave.wave} had ${verifyFailures.length} verification failure(s).`
      );
      console.error(
        `Review the reports and fix issues before re-running.`
      );
      process.exit(1);
    }

    console.log(`\nWave ${wave.wave} complete. All tasks verified.`);
  }

  console.log(`\n=== All waves complete! ===`);
  console.log(`\nRun: /compound ${projectSlug}`);
  console.log(`To extract learnings from this work.`);
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

const projectSlug = process.argv[2];
if (!projectSlug) {
  console.error(
    "Usage: npx tsx .claude/skills/product-dev-workflow/scripts/do-loop.ts <project-slug>"
  );
  process.exit(1);
}

doLoop(projectSlug).catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
