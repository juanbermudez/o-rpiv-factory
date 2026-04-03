# Online Research Guide

Use this guide when your research type is `online-research` — external documentation, APIs, library usage, migration guides, or framework best practices.

## Goal

Gather authoritative external information that the implementation agent needs. Every claim must be traceable to a URL.

## When to Use Online Research

- New library or framework being introduced
- Upgrading a dependency and need migration steps
- External API integration (REST, webhook format, auth flow)
- Best practices for a pattern not yet in the codebase
- Bug in a third-party library — find the official fix or workaround

## Research Process

### 1. Identify Authoritative Sources

Prefer sources in this order:
1. Official documentation (framework/library docs site)
2. Official GitHub repository (README, CHANGELOG, issues)
3. Framework maintainer blog posts or release notes
4. Well-known community resources (MDN for web APIs, etc.)

Avoid: Stack Overflow answers without official backing, blog posts without dates, AI-generated summaries.

### 2. Check Versions

Always note the version the documentation applies to. Check your project's `package.json` for exact versions of all major dependencies (framework, libraries, Node, etc.).

If documentation is for a different version, note the discrepancy explicitly.

### 3. Extract Actionable Findings

For each external source, extract:
- The specific API, method, or configuration option
- The exact usage pattern (with code example if available)
- Version constraints or known incompatibilities
- Deprecation warnings

### 4. Cross-Reference With Codebase

After gathering external findings, check whether the codebase already uses the pattern:
```bash
grep -r "libraryName" apps/web/src --include="*.ts" -l
```

If it does, note where — the implementation agent should match existing usage, not introduce a second style.

## Citation Requirements

Every external finding in your output MUST include:
- The URL of the source
- The date you accessed it (today's date)
- The specific section or heading

Example:
```
Source: https://nextjs.org/docs/app/api-reference/functions/next-response (accessed 2025-01-15)
Section: "NextResponse.json()"
Finding: NextResponse.json() accepts a second parameter for status code and headers.
```

## Output Requirements

Your online research output must include:
- Summary of key findings with URLs for every claim
- Code examples with source URLs
- Version compatibility notes
- Any known issues or gotchas with the library/API
- Gaps: questions that online research could not answer (may need codebase exploration or human input)
