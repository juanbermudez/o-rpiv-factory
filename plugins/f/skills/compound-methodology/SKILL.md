---
name: compound-methodology
description: >
  Methodology for extracting, categorizing, and storing engineering learnings
  after tasks are verified. Creates structured solution documents that future
  agents automatically surface during planning and implementation. The core
  of the compound engineering loop.
---

# Compound Methodology Skill

## Gotchas

<!-- Gotchas sourced from docs/solutions/ on 2026-03-17. Run /f:compound to add more. -->

- **YAML frontmatter validation is blocking**: Do NOT proceed with invalid YAML. The validation gate is explicitly marked `blocking="true"` — malformed frontmatter makes the solution unsearchable.
- **Bidirectional cross-references**: Cross-references must be bidirectional — update BOTH documents when linking. One-way links break discoverability.
- **One solution per task**: Don't combine multiple learnings from one task into a single document. Each distinct problem gets its own solution file.
- **WRONG vs CORRECT examples are required**: Every solution MUST have WRONG vs CORRECT (or NAIVE vs CORRECT for additive work) code examples — solutions without comparisons are not actionable.
- **Prevention steps are required**: What would have caught this earlier? Every solution must answer this. Without prevention steps, the same problem will recur.

## Purpose

Every solved problem becomes institutional knowledge. After a task is verified, this skill guides the agent through extracting the engineering learnings and storing them in a structured format that future agents can discover and apply.

## Inputs

The agent receives the following context before extraction begins:

- **Linear task reference** — The task ID (e.g., `TASK-150`) linking to the original work item
- **Git diff** — The actual code changes made during implementation
- **Verification report pointer** — Path to the verification output confirming the fix works
- **Implementation log pointer** — Path to notes/logs from the implementation session
- **Existing solution pointers** — Paths to `docs/solutions/` files for cross-referencing

## Workflow

### Phase 1: Parallel Analysis

<parallel_tasks>

#### Sub-Agent 1: Context Analyzer
Read the Linear task, implementation log, and verification report. Extract:
- What was the original problem?
- What environment/conditions triggered it?
- What symptoms were observed?
- How was it discovered?

#### Sub-Agent 2: Solution Extractor
Read the git diff and implementation log. Extract:
- What was the key insight that led to the solution?
- What code patterns were applied?
- What was the WRONG approach (before) vs CORRECT approach (after)?
- If purely additive (no prior wrong approach), show NAIVE vs CORRECT alternatives
- Include file:line references for all code snippets

#### Sub-Agent 3: Related Docs Finder
Search `docs/solutions/` for related solutions:
- Find solutions with overlapping tags, components, or root causes
- Check if this problem is a variation of an existing documented solution
- Identify candidates for bidirectional cross-referencing
- Flag if 3+ related solutions suggest a pattern promotion

#### Sub-Agent 4: Prevention Strategist
Analyze the root cause and determine:
- Could this have been caught by a test? If so, what test?
- Could a linter rule or type constraint prevent recurrence?
- Should a code review checklist item be added?
- What guardrails would prevent this class of problem?

#### Sub-Agent 5: Category Classifier
Based on the problem type and root cause:
- Classify into one of the 12 problem categories (see `guides/categorization.md`)
- Determine severity level (critical, high, medium, low)
- Determine resolution type (code-fix, config-change, architecture-change, dependency-update, documentation, workflow-change)
- Generate searchable tags and symptom strings

</parallel_tasks>

### Phase 2: Assembly

<sequential_tasks>

#### Step 1: Synthesize
Read all 5 sub-agent outputs. Merge into a single solution document following the template in `guides/templates/solution-template.md`.

#### Step 2: Validate YAML Frontmatter

<validation_gate name="yaml-schema" blocking="true">
Validate the YAML frontmatter against the schema defined in `guides/yaml-schema.md`:
- All required fields present
- Enum values are valid
- Date is ISO format (YYYY-MM-DD)
- Arrays (symptoms, tags) are non-empty
- linear_task matches expected format

If validation fails, fix the frontmatter before proceeding. Do NOT skip this gate.
</validation_gate>

#### Step 3: Write Solution Document
Write the solution document to `docs/solutions/{category}/{slug}.md` where:
- `{category}` is the classified problem type (e.g., `database-issues`, `api-issues`)
- `{slug}` is a kebab-case summary of the problem (e.g., `missing-org-scope-in-orders-query`)

#### Step 4: Cross-Reference
Follow the process in `guides/cross-referencing.md`:
- Add `related_solutions` links to the new document
- Update existing related documents with backlinks to this new solution
- Only add links when genuinely related

#### Step 5: Evaluate Pattern Promotion
Follow the criteria in `guides/pattern-promotion.md`:
- If frequency >= 3 similar issues, promote to `docs/solutions/patterns/critical-patterns.md`
- If severity is critical with non-obvious solution, promote
- If the pattern affects security or data integrity, promote

#### Step 6: Skill Gotchas Auto-Update

If Step 5 promoted a pattern to `docs/solutions/patterns/critical-patterns.md`, you MUST also append the pattern to the relevant methodology skill's Gotchas section.

**6a. Determine the target skill** using this category-to-skill mapping:

| Pattern Category | Target Skill |
|-----------------|-------------|
| security-issues | implementation-methodology |
| api-issues | implementation-methodology |
| database-issues | implementation-methodology |
| runtime-errors | implementation-methodology |
| integration-issues | implementation-methodology |
| performance-issues | implementation-methodology |
| ui-bugs | implementation-methodology |
| test-failures | verification-methodology |
| build-errors | verification-methodology |
| workflow-issues | planning-methodology |
| documentation-gaps | planning-methodology |
| best-practices (code patterns) | implementation-methodology |
| best-practices (process) | planning-methodology |

If the category doesn't clearly map, default to `implementation-methodology`.

**6b. Read the target skill file** at `plugins/f/skills/{target-skill}/SKILL.md` and locate the `## Gotchas` section.

**6c. Check for duplicates** — search the Gotchas section for the pattern title. If a gotcha with the same title already exists, skip this step. Never add duplicate entries.

**6d. Append the new gotcha** as a bullet point at the end of the Gotchas list, matching this format exactly:

```
- **{Pattern title}**: {One-sentence summary of the gotcha}. See: `docs/solutions/{category}/{file}.md`
```

**6e. Update the date comment** at the top of the `## Gotchas` section. If the comment already exists, replace the date. If no comment exists, add it immediately after the `## Gotchas` heading:

```
<!-- Gotchas sourced from docs/solutions/ on YYYY-MM-DD. Run /f:compound to add more. -->
```

Use today's actual date in ISO format (YYYY-MM-DD).

**6f. If no `## Gotchas` section exists** in the target skill, create one at the end of the file:

```markdown
## Gotchas

<!-- Gotchas sourced from docs/solutions/ on YYYY-MM-DD. Run /f:compound to add more. -->

- **{Pattern title}**: {One-sentence summary of the gotcha}. See: `docs/solutions/{category}/{file}.md`
```

#### Step 6b: Failure Pattern Analysis

After updating skill gotchas (or if no pattern promotion occurred), check for recurring failure patterns:

1. **Read `${CLAUDE_PLUGIN_DATA}/f/failure-patterns.jsonl`** if it exists. If it does not exist, skip this step entirely.

2. **Count occurrences by `failure_type`** — look for any `failure_type` that appears 3 or more times.

3. **For each recurring failure type**, check whether a corresponding gotcha already exists in the relevant skill's Gotchas section (search by keyword match against the failure type).

4. **If a recurring failure type has no matching gotcha**, flag it for human review:

<decision_gate wait_for_user="true">
Use the `AskUserQuestion` tool to present the candidate gotcha derived from failure-patterns.jsonl. Include:
- The `failure_type` and how many times it occurred
- A draft gotcha bullet point in the standard format
- The question: "Should I add this failure-derived gotcha to the {skill} skill? (These are less certain than compound-derived ones.)"

Wait for explicit approval before adding. If approved, follow steps 6b–6f above to insert the gotcha.
</decision_gate>

#### Step 7: Human Review

<decision_gate wait_for_user="true">
You MUST use the `AskUserQuestion` tool to present the completed solution document to the human for review. Do NOT output the review as plain text — always use the tool so the user gets a proper interactive prompt. Include:
- The full solution document with YAML frontmatter
- WRONG vs CORRECT examples highlighted
- Any cross-references added
- Whether pattern promotion was triggered
- The question: "Does this accurately capture the learning? Any corrections?"

Wait for human approval before finalizing. The human may request changes to the categorization, severity, or content.
</decision_gate>

</sequential_tasks>

## Critical Requirements

<critical_requirement>
Every solution document MUST include ALL of the following:

1. **WRONG vs CORRECT examples** — Code comparison showing the anti-pattern and the fix. If the work was purely additive (new feature, no prior bug), show NAIVE vs CORRECT instead.

2. **Valid YAML frontmatter** — All required fields from `guides/yaml-schema.md` present and validated. The YAML validation gate is blocking; do not proceed without valid frontmatter.

3. **Prevention steps** — Concrete actions to prevent recurrence: tests to add, linter rules, type constraints, review checklist items. Every solution must answer "how do we ensure this never happens again?"

4. **Linear task reference** — The `linear_task` field in frontmatter must reference the originating task (e.g., `TASK-150`). Solutions without provenance cannot be trusted.
</critical_requirement>

## Output

The skill produces:
- A new file at `docs/solutions/{category}/{slug}.md`
- Updated cross-references in related existing solution documents
- (Conditionally) An updated `docs/solutions/patterns/critical-patterns.md` with promoted patterns
- (Conditionally) An updated `## Gotchas` section in the relevant methodology skill's SKILL.md

## Directory Structure

```
docs/solutions/
  build-errors/
  test-failures/
  runtime-errors/
  performance-issues/
  database-issues/
  security-issues/
  api-issues/
  ui-bugs/
  integration-issues/
  workflow-issues/
  best-practices/
  documentation-gaps/
  patterns/
    critical-patterns.md
```

## Plugin Memory

After Step 6 (Human Review) is approved, append one entry to the project history log:

```bash
if [ -n "${CLAUDE_PLUGIN_DATA}" ]; then
  mkdir -p "${CLAUDE_PLUGIN_DATA}/f/"
  echo '{"timestamp":"<ISO8601>","project_slug":"<slug>","project_name":"<name>","task_count":<n>,"tasks_completed":<n>,"outcome":"completed","duration_minutes":<n>}' >> "${CLAUDE_PLUGIN_DATA}/f/project-history.jsonl"
fi
```

Valid `outcome` values: `completed`, `paused`, `canceled`. Only write this entry after human approval — if the user cancels or rejects the compound output, do not write the entry.

See the full schema in `skills/plugin-memory/SKILL.md`.

## Related Guides

- `guides/solution-extraction.md` — How to extract learnings from implementation work
- `guides/yaml-schema.md` — YAML frontmatter validation rules
- `guides/categorization.md` — How to categorize solutions into the 12 categories
- `guides/cross-referencing.md` — How to link related solutions
- `guides/pattern-promotion.md` — When and how to promote to critical-patterns.md
- `guides/templates/solution-template.md` — Full solution document template
