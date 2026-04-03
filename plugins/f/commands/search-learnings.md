---
name: search-learnings
description: "Search the docs/solutions/ knowledge base for past solutions"
argument-hint: ""search query""
---

# Search Learnings

Search the `docs/solutions/` knowledge base for solutions matching the user's query.

## Instructions

1. **Spawn the `learnings-researcher` agent** with the search query provided as the argument.
   - The agent should search across all files in `docs/solutions/` recursively.
   - Match against: YAML frontmatter fields (title, category, severity, tags), headings, and body content.
   - Rank results by relevance to the query.

2. **Present results in a table**:

| Path | Title | Category | Severity | Relevance |
|------|-------|----------|----------|-----------|
| `docs/solutions/category/file.md` | Solution Title | Category | high/medium/low | Brief relevance note |

3. **If no results are found**, respond with:

> No matching solutions found. The knowledge base grows as you run `/f:compound` after completing tasks.

## Agent Configuration

- **Agent**: `learnings-researcher`
- **Model**: haiku (fast, low-cost search)
- **Input**: The search query string from the user
- **Output**: Table of matching solutions sorted by relevance

## Search Strategy

The learnings-researcher agent should:
1. Glob `docs/solutions/**/*.md` to find all solution files
2. Read YAML frontmatter from each file to extract metadata (title, category, severity, tags)
3. Score relevance based on:
   - Exact keyword matches in title or tags (highest weight)
   - Category match (high weight)
   - Body content matches (moderate weight)
   - Related terms or synonyms (lower weight)
4. Return top 10 results sorted by relevance score
