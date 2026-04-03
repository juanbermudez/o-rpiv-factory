# Learnings Search Guide

Use this guide when your research type is `learnings-search` — checking `docs/solutions/` for past solutions before starting work.

## Goal

Prevent repeating solved problems. Every task should be checked against the knowledge base before implementation begins.

## When to Run Learnings Search

- Always, as part of the preconditions for any research session
- Specifically when the task involves: authentication, database migrations, API routes, money/pricing, RLS policies, external integrations

## Search Strategy

### 1. Always Start With Critical Patterns

```bash
cat docs/solutions/patterns/critical-patterns.md
```

This file contains promoted patterns that caused repeated issues. Read it completely — it is short by design.

### 2. Search by Keywords

Use multiple keyword combinations. Cast a wide net:

```bash
# Search by feature area
grep -r "orders" docs/solutions/ --include="*.md" -l
grep -r "organization_id" docs/solutions/ --include="*.md" -l

# Search by problem type
grep -r "RLS" docs/solutions/ --include="*.md" -l
grep -r "withPermission" docs/solutions/ --include="*.md" -l

# Search by symptom
grep -r "403" docs/solutions/ --include="*.md" -l
grep -r "missing.*scope" docs/solutions/ --include="*.md" -l
```

### 3. Search YAML Frontmatter Fields

Solution documents have structured frontmatter. Search it directly:

```bash
# Find by category
grep -r "category: database-issues" docs/solutions/ --include="*.md" -l

# Find by component
grep -r "component: orders" docs/solutions/ --include="*.md" -l

# Find by tag
grep -r "tags:.*rls" docs/solutions/ --include="*.md" -l

# Find critical severity
grep -r "severity: critical" docs/solutions/ --include="*.md" -l
```

### 4. Read Matching Documents

For each matching file, read the full document. Extract:
- **Problem**: What situation triggers this issue
- **WRONG approach**: What not to do
- **CORRECT approach**: What to do instead
- **Prevention**: Tests or checks that catch violations

### 5. Check Related Solutions

Each solution document has a `related_solutions` field. Follow those links — a related solution may be more directly applicable than the one you found first.

## YAML Frontmatter Schema Reference

Solution documents use this frontmatter structure:

```yaml
---
title: "Short descriptive title"
linear_task: "TASK-XXX"
date: "YYYY-MM-DD"
category: "database-issues"  # one of 12 categories
severity: "critical"         # critical | high | medium | low
resolution_type: "code-fix"  # code-fix | config-change | architecture-change | dependency-update | documentation | workflow-change
component: "component-name"
tags:
  - "relevant-tag"
symptoms:
  - "observable symptom string"
related_solutions: []
---
```

## The 12 Categories

```
build-errors          test-failures         runtime-errors
performance-issues    database-issues       security-issues
api-issues            ui-bugs               integration-issues
workflow-issues       best-practices        documentation-gaps
```

## Output Requirements

Your learnings search output must include:
- List of solution documents found with file paths
- Key learnings extracted from each (WRONG vs CORRECT pattern)
- Direct applicability assessment: does this learning affect the current task?
- Any critical patterns from `critical-patterns.md` that apply
- Explicit statement if no relevant learnings were found (so the reader knows you searched)
