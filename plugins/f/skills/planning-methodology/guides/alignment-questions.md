# Alignment Questions Guide

This guide defines how to run the alignment checkpoint before writing a PRD. The alignment checkpoint prevents wasted effort on a misaligned specification.

## When to Run

After reading all research documents (Step 1 in the sequential workflow), before writing the PRD (Step 3). This is a mandatory human gate.

## Purpose

You have just read the research. You now have a mental model of:
- What is technically feasible
- What the codebase supports today
- What constraints or gotchas exist

Before committing that to a full PRD, confirm the direction with the human. This surfaces misalignments early, when they are cheap to fix.

## Question Selection

Prepare 4-6 targeted questions. These should be questions where:
- The answer materially changes the design
- You genuinely do not know the answer from the research
- The answer cannot be inferred from business context

Do NOT ask questions that:
- Have obvious answers from the research
- Are purely implementation details (the agent can decide those)
- Cover every possible edge case (focus on the critical unknowns)

## Question Categories

### Direction Questions
About the fundamental approach:
- "Should this be real-time or batch? The current pattern is batch but the feature description implies real-time."
- "Should this extend the existing orders table or use a separate table? Each has tradeoffs I can outline."

### Scope Questions
About boundaries:
- "The research found that X and Y are coupled. Should we decouple them as part of this feature, or keep them coupled?"
- "The feature description mentions mobile. Is the mobile app in scope for this iteration?"

### Constraint Questions
About hard requirements:
- "Is backward compatibility required? The proposed schema change would require a migration of existing data."
- "Are there regulatory requirements I should know about for storing this data?"

### Priority Questions
About trade-offs where you need guidance:
- "The implementation can optimize for developer speed (using existing patterns) or for performance (requires new pattern). Which matters more?"

## Format for AskUserQuestion

You MUST use the `AskUserQuestion` tool — never output alignment questions as plain text.

Structure your question text as:

```
## Alignment Checkpoint

I've read the research and have a clear picture of the solution space. Before writing the PRD, I need to confirm direction on a few points.

**Context**: {1-2 sentences summarizing the key technical finding that motivates these questions}

**Questions**:

1. {Question about scope/direction} — My current assumption is X. If wrong, the PRD will change significantly in {area}.

2. {Question about constraint} — The research found {finding}. Should the PRD address this or treat it as out of scope?

3. {Question about trade-off} — I can go either way on {decision}. Leaning toward {option} because {brief reason}. Correct if needed.

4. {Question about gap} — Research could not determine {unknown}. What should I assume?

Please confirm or correct. I'll proceed to write the PRD once these are resolved.
```

## After Getting the Response

- Update your mental model with the human's answers
- If the human's answers reveal the research was incomplete, note this in the PRD under "Open Questions"
- If the human approves with no changes, proceed directly to PRD writing
- If denied or major changes requested, determine whether additional research is needed and coordinate with the orchestrator
