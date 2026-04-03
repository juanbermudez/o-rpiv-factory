---
name: compound
description: "Extract engineering learnings from completed tasks into docs/solutions/"
argument-hint: "project-slug or task-id"
---

# /compound — Extract Engineering Learnings

Extract learnings from completed work and store them as structured solution documents
in `docs/solutions/`. This is the core of the compound engineering loop: every solved
problem becomes institutional knowledge that future `/plan` and `/do` commands surface
automatically.

---

## Phase 0: Determine Scope

Determine what to compound based on the argument provided.

<thinking>
Parse the argument:
- If it matches a project slug (e.g., `auth-system`, `user-export`): compound ALL completed tasks in that project
- If it matches a task ID pattern (e.g., `PROJ-123`, `ENG-456`): compound just that one task

Fetch the relevant data:
</thinking>

### If argument is a project slug:

Read `.resources/context/{slug}/manifest.json` and `.resources/context/{slug}/tasks/*.json`
to get the project details and task list.

Filter to only tasks with status `complete` or `qa`. These are the tasks worth compounding.
If no completed tasks exist, inform the user and exit.

### If argument is a task ID:

Read `.resources/context/{slug}/tasks/{task-id}.json` for the individual task details.

Verify the task has status `complete` or `qa`. If not, use the `AskUserQuestion` tool to warn the user that compounding incomplete tasks may produce incomplete learnings, and ask whether to proceed.

Build a list of tasks to compound. For each task, proceed to Phase 1.

---

## Phase 1: For Each Task to Compound

Iterate through each task in the compound list. For each task:

### Step 1a: Gather Task Artifacts

Collect file pointers for all available artifacts. Not all will exist for every task — gather
what is available and note what is missing.

<sequential_tasks>

1. **Task spec** — Read the task context file:
   ```bash
   cat .resources/context/{slug}/tasks/{task-id}.json
   ```

2. **Git diff** — Get the code changes associated with this task:
   ```bash
   # Try branch-based diff first
   git diff main...feat/{task-id}-* -- . 2>/dev/null

   # If no branch exists, search merged commits by task ID
   git log --all --oneline --grep="{task-id}" | head -10
   # Then get the diff from those commits
   git diff {first-commit}^..{last-commit}
   ```

3. **Verification report** — Check for verification output:
   ```bash
   cat .resources/context/{slug}/tasks/{task-id}-verify.md 2>/dev/null
   ```

4. **Implementation log** — Check for implementation notes:
   ```bash
   cat .resources/context/{slug}/tasks/{task-id}-impl-log.md 2>/dev/null
   ```

5. **Related existing solutions** — Search for potentially related docs:
   ```bash
   # Search by component and tags from the task context
   grep -rl "component:.*{component}" docs/solutions/ 2>/dev/null
   grep -rl "{relevant-tag}" docs/solutions/ 2>/dev/null
   ```

Store all gathered paths/content as context variables for the sub-agents.

</sequential_tasks>

### Step 1b: Spawn 5 Compound Sub-Agents (Parallel)

Launch all 5 sub-agents simultaneously. Each writes its analysis to a designated output file.

<parallel_tasks>

#### Agent 1: Context Analyzer
**Agent**: `context-analyzer`
**Prompt**:
```
Analyze completed task {task-id}. Your job is to understand what happened.

Task spec: {task spec content or path}
Git diff: {diff content or command to run}
Verification report: {verify path or "not available"}
Implementation log: {impl-log path or "not available"}

Write your analysis to: .resources/context/{slug}/compound/context.md

Follow the output format specified in your agent prompt. Be factual —
report what happened, include file paths and line numbers, note any
patterns of rework or iteration.
```

#### Agent 2: Solution Extractor
**Agent**: `solution-extractor`
**Prompt**:
```
Extract the solution pattern from task {task-id}. Your job is to
identify what was WRONG (or NAIVE) vs what was CORRECT.

Task spec: {task spec content or path}
Git diff: {diff content or command to run}
Context analysis: .resources/context/{slug}/compound/context.md
  (may not be ready yet — use the git diff and task spec as primary sources)

Write your analysis to: .resources/context/{slug}/compound/solution.md

Include file:line references for all code snippets. If there was no prior
wrong approach (purely additive work), use NAIVE vs CORRECT framing instead.
```

#### Agent 3: Related Docs Finder
**Agent**: General-purpose agent
**Prompt**:
```
Search docs/solutions/ for solutions related to task {task-id}.

Component: {component}
Tags: {tags}
Problem summary: {one-line summary from task spec}

Search strategy:
1. Grep docs/solutions/ YAML frontmatter for matching component fields
2. Grep docs/solutions/ YAML frontmatter for overlapping tags
3. Grep docs/solutions/ content for similar symptoms or root causes
4. Check if this is a variation of an already-documented problem

Write your findings to: .resources/context/{slug}/compound/related.md

Format:
## Related Solutions
### Exact Matches (same component + overlapping tags)
- path — brief description, relevance

### Partial Matches (same category or similar symptoms)
- path — brief description, relevance

### Pattern Promotion Candidates
- If 3+ related solutions exist for same component/category, flag for promotion

### Total Related Count: N
```

#### Agent 4: Prevention Strategist
**Agent**: `prevention-strategist`
**Prompt**:
```
Determine how issues from task {task-id} could be prevented in the future.

Task spec: {task spec content or path}
Implementation log: {impl-log path or "not available"}
Verification report: {verify path or "not available"}
Git diff: {diff content or command to run}

Write your analysis to: .resources/context/{slug}/compound/prevention.md

Prioritize earliest-in-workflow prevention. Be specific — name the exact
test, linter rule, type constraint, or review checklist item. Include
effort/impact assessments.
```

#### Agent 5: Category Classifier
**Agent**: `category-classifier`
**Prompt**:
```
Classify the solution for task {task-id}.

Task spec: {task spec content or path}
Context analysis: .resources/context/{slug}/compound/context.md
  (may not be ready yet — use the task spec as primary source)
Solution pattern: .resources/context/{slug}/compound/solution.md
  (may not be ready yet — use the git diff as primary source)

Search docs/solutions/ for frequency of this category + component
combination to determine pattern promotion eligibility.

Write your classification to: .resources/context/{slug}/compound/classification.md

Include: primary category, severity, tags, promotion check result,
and recommended filename.
```

</parallel_tasks>

**Wait for all 5 agents to complete before proceeding.**

### Step 1c: Assembly

<sequential_tasks>

#### 1. Read All Sub-Agent Outputs

Read the 5 output files from `.resources/context/{slug}/compound/`:
- `context.md` — Problem context, timeline, complexity
- `solution.md` — WRONG vs CORRECT patterns, key insight
- `related.md` — Cross-reference candidates, promotion flags
- `prevention.md` — Prevention strategies with effort/impact
- `classification.md` — Category, severity, tags, filename

#### 2. Assemble Solution Document

Merge all 5 analyses into a single solution document following the template
at `.claude/skills/compound-methodology/guides/templates/solution-template.md`.

Populate every section:
- **Frontmatter**: From classifier output (category, severity, tags) + context (date, task ref)
- **Problem**: From context analyzer (problem statement, symptoms, environment)
- **Root Cause**: From solution extractor (root cause analysis)
- **Solution (WRONG vs CORRECT)**: From solution extractor (code comparisons with file:line refs)
- **What Changed**: From context analyzer (files modified, changes summary)
- **Prevention**: From prevention strategist (concrete prevention actions)
- **Key Takeaway**: Synthesize from solution extractor's key insight — one actionable sentence

#### 3. Generate YAML Frontmatter

Build the complete YAML frontmatter block with all required fields:

```yaml
---
title: "[from classifier/solution extractor]"
problem_type: [from classifier — one of 12 valid categories]
component: "[from classifier]"
root_cause: "[from solution extractor — kebab-case]"
resolution_type: [from classifier — one of 6 valid types]
severity: [from classifier — critical|high|medium|low]
date_solved: [today's date in YYYY-MM-DD format]
linear_task: "[task ID reference]"
symptoms:
  - "[from context analyzer — observable symptoms]"
tags:
  - "[from classifier — searchable tags]"
related_solutions:
  - "[from related docs finder — paths to related docs]"
prevention_added: [true if prevention actions were implemented, false otherwise]
---
```

#### 4. Validate YAML Against Schema

<validation_gate name="yaml-schema" blocking="true">

Validate against `.claude/skills/compound-methodology/guides/yaml-schema.md`:

- [ ] All required fields present: title, problem_type, component, root_cause, resolution_type, severity, date_solved, linear_task, symptoms, tags
- [ ] `problem_type` is one of: build-errors, test-failures, runtime-errors, performance-issues, database-issues, security-issues, api-issues, ui-bugs, integration-issues, workflow-issues, best-practices, documentation-gaps
- [ ] `resolution_type` is one of: code-fix, config-change, architecture-change, dependency-update, documentation, workflow-change
- [ ] `severity` is one of: critical, high, medium, low
- [ ] `date_solved` matches YYYY-MM-DD format
- [ ] `symptoms` is a non-empty array (at least 1 item)
- [ ] `tags` is a non-empty array (at least 1 item)
- [ ] `title`, `component`, `root_cause`, `linear_task` are non-empty strings
- [ ] `related_solutions` paths (if present) start with `docs/solutions/` and end with `.md`

If validation fails: fix the YAML and re-validate. Do NOT proceed with invalid frontmatter.
This gate is blocking.

</validation_gate>

#### 5. Determine Output Path

```
docs/solutions/{category}/{filename}.md
```

- `{category}`: The `problem_type` value from frontmatter (e.g., `database-issues`, `api-issues`)
- `{filename}`: kebab-case descriptive slug from the title
  - Example title: "Missing org scope in orders query"
  - Example filename: `missing-org-scope-in-orders-query.md`

Ensure the category directory exists:
```bash
mkdir -p docs/solutions/{category}
```

#### 6. Write the Solution Document

Write the assembled document to the determined path.

#### 7. Cross-Reference (Bidirectional)

If the related docs finder identified related solutions:

For EACH related solution:
1. Read the existing solution file
2. Check if it already has a `related_solutions` field in its YAML frontmatter
3. If yes: append the new solution's path to the array (if not already present)
4. If no: add the `related_solutions` field with the new solution's path
5. Update the new solution's `related_solutions` to include the existing doc's path

Cross-references are BIDIRECTIONAL. Both documents must link to each other.

#### 8. Check Pattern Promotion

Evaluate whether this solution should be promoted to `docs/solutions/patterns/critical-patterns.md`:

**Promotion criteria** (either condition triggers promotion):
- **Frequency threshold**: The same `category` + `component` combination appears >= 3 times in `docs/solutions/`
- **Critical + non-obvious**: Severity is `critical` AND the solution is non-obvious (required debugging, multiple attempts, or counter-intuitive fix)

If promotion is triggered:

```bash
# Ensure patterns directory exists
mkdir -p docs/solutions/patterns
```

Append a new entry to `docs/solutions/patterns/critical-patterns.md`:

```markdown
### [Pattern Title]
**Category**: {category} | **Component**: {component} | **Frequency**: {count}
**Summary**: [One-line pattern description]
**Solutions**: [links to all related solution docs]
**Key Rule**: [The actionable rule to follow — e.g., "Always scope queries by organization_id"]
```

</sequential_tasks>

### Step 1d: Compound Review Gate

<decision_gate wait_for_user="true">

You MUST use the `AskUserQuestion` tool to present the assembled solution to the human for review. Do NOT output review content as plain text — always use the tool so the user gets a proper interactive prompt.

---

## Compound Review: {task-id}

### Solution Document
**Title**: {title}
**Category**: {problem_type} | **Severity**: {severity}
**Component**: {component}
**Output path**: `docs/solutions/{category}/{filename}.md`

**Key Takeaway**: {key takeaway sentence}

### WRONG vs CORRECT

```{language}
// WRONG — {brief explanation}
{wrong code}
```

```{language}
// CORRECT — {brief explanation}
{correct code}
```

### Prevention
{prevention recommendations summary — bullet points}

### Cross-References
{list of bidirectional links that will be added, or "None — no related solutions found"}

### Pattern Promotion
{if applicable: "This pattern has appeared N times for {component} in {category}. Promoting to critical-patterns.md."}
{show the pattern entry that would be added}
{if not applicable: "No promotion triggered (frequency: N, severity: {severity})"}

---

**Approve these learnings?**
- **Yes** — Store the solution document, update cross-references, promote pattern (if applicable)
- **Edit** — Modify before storing (specify what to change)
- **Skip** — Don't store this learning (only for trivial/not-worth-capturing tasks)

</decision_gate>

**On "Yes"**: Write all files (solution doc, cross-reference updates, pattern promotion).
**On "Edit"**: Ask what to change, make modifications, re-present for approval.
**On "Skip"**: Log that this task was skipped and move to the next task in the list.

---

## Phase 2: Summary

After all tasks have been compounded (or skipped), present a summary:

### Compound Results

| Task | Category | Severity | Solution | Pattern Promoted? |
|------|----------|----------|----------|-------------------|
| {task-id} | {category} | {severity} | `docs/solutions/{path}` | Yes/No |
| ... | ... | ... | ... | ... |

### Knowledge Base Stats

```bash
# Count total solutions
find docs/solutions/ -name "*.md" ! -name "README.md" ! -path "*/patterns/*" | wc -l

# Count patterns promoted
grep -c "^### " docs/solutions/patterns/critical-patterns.md 2>/dev/null || echo "0"
```

- **Total solutions**: {count}
- **Solutions added this session**: {count}
- **Patterns promoted this session**: {count}
- **Cross-references updated**: {count}

**Knowledge base updated.** Future `/plan` and `/do` commands will automatically surface
these learnings when working on related components.

---

## Auto-Detection (Optional Enhancement)

When a user says things like:
- "that worked"
- "figured it out"
- "the issue was..."
- "fixed it"
- "the problem was..."

Suggest:

> Sounds like you solved something. Run `/f:compound {task-id}` to capture this learning
> so future agents can benefit from it.

---

## Key Rules

<critical_requirement>

1. **Every solution MUST have WRONG vs CORRECT** (or NAIVE vs CORRECT for additive work) code examples with file:line references. No exceptions.

2. **YAML frontmatter MUST pass validation** before writing. The validation gate is blocking. Do not skip it, do not write files with invalid frontmatter.

3. **Cross-references are BIDIRECTIONAL**. When linking solution A to solution B, BOTH files must be updated. Never create a one-way link.

4. **Pattern promotion threshold**: frequency >= 3 for the same category+component combination, OR severity is critical with a non-obvious solution. Both conditions are checked independently.

5. **Human approval required** before storing. The Compound Review gate is mandatory. Never write solution documents without presenting them for review first. Always use the `AskUserQuestion` tool for the review gate — never output the review as plain text.

6. **File naming**: kebab-case, descriptive, in the correct category directory under `docs/solutions/`. Filename should be self-explanatory without reading the file.

7. **Intermediate artifacts** go in `.resources/context/{slug}/compound/`. These are working files for the sub-agents, not permanent documentation.

8. **One solution document per task**. If a task involved multiple distinct learnings, capture the primary one. Mention secondary learnings in the "What Changed" section.

</critical_requirement>
