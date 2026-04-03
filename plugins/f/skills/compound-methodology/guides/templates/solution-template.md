# Solution Document Template

Copy this template when creating a new solution document. Replace all `{placeholder}` values. The file goes in `docs/solutions/{category}/{slug}.md`.

---

```markdown
---
title: "{Short description of the problem}"
linear_task: "TASK-XXX"
date: "YYYY-MM-DD"
category: "{one of 12 categories}"
severity: "{critical|high|medium|low}"
resolution_type: "{code-fix|config-change|architecture-change|dependency-update|documentation|workflow-change}"
component: "{kebab-case-component-name}"
tags:
  - "{feature-area}"
  - "{technical-layer}"
  - "{problem-type}"
symptoms:
  - "{Observable symptom 1}"
  - "{Observable symptom 2}"
related_solutions:
  - "{category/slug.md}"
---

# {Title — same as frontmatter title}

## Problem

{2-4 sentences describing the problem. What situation triggers it? What is the root cause?
Include the environment and conditions that led to discovering it.}

## Symptoms

{List of observable symptoms. What did the developer or user see?}

- {Symptom 1}
- {Symptom 2}

## WRONG Approach

{Code or configuration that seems correct but causes the problem.
Include file:line references. For pure additions (new feature), use "NAIVE Approach" heading instead.}

```typescript
// WRONG: Missing organization_id scope
const { data } = await ctx.supabase
  .from('orders')
  .select('*')
// Returns data from ALL organizations
```

## CORRECT Approach

{Code or configuration that correctly solves the problem.
Include file:line references.}

```typescript
// CORRECT: Always scope by organization_id
const { data } = await ctx.supabase
  .from('orders')
  .select('*')
  .eq('organization_id', ctx.organizationId)
// Returns only the current org's orders
```

## Why This Happens

{Explanation of root cause. Why does the wrong approach seem reasonable? What mental model
leads developers to make this mistake?}

## Prevention

{Concrete prevention steps. At least one must be actionable now.}

1. **Code review checklist**: Every Supabase query in an API route must include `.eq('organization_id', ctx.organizationId)`.
2. **Test coverage**: Add a test that logs in as two orgs and confirms data isolation.
3. **Linter rule**: {If a linter rule can catch this, specify it.}

## Related Solutions

{Cross-references to related documents. One line per related doc.}

- [`docs/solutions/{category}/{slug}.md`]({category}/{slug}.md) — {One-line description of how it's related}
```

---

## Template Notes

- **WRONG vs CORRECT**: This comparison is the most valuable part of the document. Make it concrete with real code.
- **Prevention**: At least one prevention step must be something an agent or human can DO TODAY (not just "be careful").
- **Related solutions**: Only link genuinely related docs. False connections dilute the knowledge graph.
- **File path**: `docs/solutions/{category}/{slug}.md` where slug is kebab-case problem description.
