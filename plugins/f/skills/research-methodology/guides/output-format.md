# Research Output Format

This guide defines the standard format for research output documents. All research agents write their findings to a file at the path specified by the orchestrator. That file must follow this format.

## File Structure

```markdown
# Research: {Topic}

**Research Type**: {codebase-exploration | online-research | pattern-discovery | learnings-search}
**Requested By**: {orchestrator reference or task ID}
**Date**: {YYYY-MM-DD}

## Summary

{2-4 sentence overview of what was found. Lead with the most important finding.}

## Findings

{Main findings section — structure varies by research type, see below}

## Pattern Anchors

{For codebase/pattern research: list the 2-3 implementations the implementer should follow}

| Pattern | File | Lines | Similarity |
|---------|------|-------|------------|
| ... | ... | ... | ... |

## Learnings Applied

{List any docs/solutions/ entries that are relevant to this work}

- `docs/solutions/{category}/{file}.md` — {one-line summary of the relevant learning}

## Gaps & Open Questions

{Explicit list of things you could not determine. Be honest. Unanswered questions here
are better than false confidence in the Findings section.}

- [ ] {Unknown or ambiguous item}
- [ ] {Item needing human clarification}
```

## Section Guidelines

### Summary

- Maximum 4 sentences
- Lead with the answer, not the process
- State the most important finding first
- Flag any blocking issues immediately

### Findings

Organize by sub-topic, not by the order you discovered things. Each finding must include:
- File:line reference for codebase findings
- URL for external findings
- Short explanation of why this is relevant

### Pattern Anchors

Only include patterns that are genuinely reusable. If none reach 60% similarity, state that explicitly here and explain what partial patterns are available.

### Learnings Applied

List every `docs/solutions/` file you read, even if it turned out not to be relevant (noting "not applicable" is better than omitting — it shows the search was done).

### Gaps & Open Questions

This section is mandatory. An empty gaps section usually means the researcher was overconfident. Common valid gaps:
- "Could not determine the correct permission scope — needs product clarification"
- "The migration runs in CI but behavior in production with existing data is unknown"
- "External API docs do not specify rate limits for this endpoint"

## Anti-Patterns to Avoid

- Do not restate the task description in the findings
- Do not include implementation code (short snippets under 15 lines only)
- Do not omit file:line references ("somewhere in the orders module" is not acceptable)
- Do not mark the gaps section as "None" unless you genuinely have no unknowns
- Do not pad the document — the orchestrator reads many of these; be dense and useful
