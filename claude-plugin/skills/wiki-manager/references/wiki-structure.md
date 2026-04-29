# Wiki Directory Structure

> **Configurable hub path**: The hub location is read from `~/.config/llm-wiki/config.json` (`resolved_path` field). If no config exists, `~/wiki/` is the fallback. Throughout this document, `HUB/` means "the resolved hub path". See [hub-resolution.md](hub-resolution.md) for the full resolution protocol (tilde expansion, space handling, iCloud paths).

## Hub (HUB/)

The hub is lightweight — it has NO content directories. It only tracks topic wikis.

```
HUB/                               # resolved from ~/.config/llm-wiki/config.json
├── wikis.json                     # Registry of all topic wikis
├── _index.md                      # Lists topic wikis with stats
├── wiki_log.md                         # Global activity log
└── topics/                        # Each topic is a full wiki
    ├── dementia/
    ├── quantum-computing/
    └── ...
```

## Topic Sub-Wiki (HUB/topics/<name>/)

All content lives here. Each topic wiki has the full structure:

```
HUB/topics/<name>/
├── .obsidian/                     # Obsidian vault config
├── _index.md                      # Master index: stats, quick nav, recent changes
├── .librarian/                    # Optional: wiki-only maintenance reports
│   ├── REPORT.md
│   └── scan-results.json
├── .audit/                        # Optional: umbrella audit reports
│   ├── REPORT.md
│   └── scan-results.json
├── config.md                      # Title, scope, conventions
├── wiki_log.md                         # Topic-level activity log
├── inbox/                         # Drop zone for this topic
│   └── .processed/
├── raw/                           # Immutable source material
│   ├── _index.md
│   ├── articles/
│   │   ├── _index.md
│   │   └── *.md
│   ├── papers/
│   │   ├── _index.md
│   │   └── *.md
│   ├── repos/
│   │   ├── _index.md
│   │   └── *.md
│   ├── notes/
│   │   ├── _index.md
│   │   └── *.md
│   └── data/
│       ├── _index.md
│       └── *.md
├── wiki/                          # Compiled articles (LLM-maintained)
│   ├── _index.md
│   ├── concepts/
│   │   ├── _index.md
│   │   └── *.md
│   ├── topics/
│   │   ├── _index.md
│   │   └── *.md
│   ├── references/
│   │   ├── _index.md
│   │   └── *.md
│   └── theses/                    # Thesis investigations
│       ├── _index.md
│       └── *.md
└── output/                        # Generated artifacts
    ├── _index.md
    ├── projects/                  # Project folders (see projects.md)
    │   ├── <slug>/
    │   │   ├── WHY.md             # Required: goal + rationale in plain markdown
    │   │   ├── *.md               # Markdown deliverables
    │   │   ├── *.png, *.svg       # Colocated images/diagrams
    │   │   ├── code/              # Optional — prototype scripts
    │   │   └── data/              # Optional — CSVs, JSON exports
    │   └── .archive/              # Archived projects (moved here by /wiki:project archive)
    │       └── <slug>/
    │           └── WHY.md
    └── *.md                       # Loose outputs (backward compatible)
```

See [projects.md](projects.md) for the full projects architecture (lifecycle, multi-membership, explicit `--project <slug>` scoping).

## Local Wiki (--local flag)

Same structure as above but rooted at `<project>/.wiki/` without `wikis.json` or `topics/`.

## Wiki Resolution Order

When a command runs, first resolve the hub path (HUB) from `~/.config/llm-wiki/config.json` (see `hub-resolution.md`). Then resolve which wiki to use:

1. `--local` flag present → `<cwd>/.wiki/`
2. `--wiki <name>` flag present → look up name in `HUB/wikis.json`
3. Current directory has `.wiki/` → use it
4. Otherwise → HUB

## wikis.json Format

```json
{
  "default": "<HUB>",
  "wikis": {
    "hub": { "path": "<HUB>", "description": "Global knowledge base" },
    "<topic>": { "path": "<HUB>/topics/<topic>", "description": "...", "commons": true },
    "<client-topic>": { "path": "<HUB>/topics/<client>", "description": "...", "client": "<client-name>" },
    "<personal-topic>": { "path": "<HUB>/topics/personal", "description": "...", "personal": true }
  },
  "local_wikis": [
    { "path": "/absolute/path/.wiki", "description": "..." }
  ]
}
```

### Isolation flags (HORDE fork — Pass 3)

Each topic wiki entry carries one of three optional flags. They are **read by future isolation hooks and ignored in phase 0** — the registry is forward-compatible, but no enforcement happens yet.

| Flag | Meaning | When to set |
|---|---|---|
| `commons: true` | Generally-applicable knowledge — visible to all sessions regardless of active client. Examples: cybersecurity frameworks, GRC methodology, standards crosswalks. | Topics that should be reusable across every client engagement and personal research. |
| `client: "<name>"` | Engagement-specific knowledge — must not leak across clients. Example: `client: "uline"` for the Uline GRC engagement. | Topics rooted in a single client's data, deliverables, interviews, or systems. |
| `personal: true` | The operator's own research, learning, and notes. Visible to the operator's sessions, not visible to client-scoped sessions. | One per workspace, owned by the workspace owner. |

A topic wiki entry must have **exactly one** of these flags (commons, client, personal) — they are mutually exclusive.

**Future isolation rule (deferred to a separate design doc when client #2 arrives):**

> A session can see all `commons: true` topics, plus at most one `client:` topic at a time, plus the workspace owner's `personal: true` topic. Default-deny on cross-client visibility.

Until that hook layer exists, the flags are documentation — they signal intent and let humans audit which topics have been correctly partitioned, but cross-topic peek operates without filtering. Do not write client-confidential material to a `commons:` topic; the lint rule (see `linting.md` C-isolation) flags such citations for review.

## _index.md Format

Every directory has an `_index.md`. This is the agent's primary navigation aid.

```markdown
# [Directory Name] Index

> [One-line description of what this directory contains]

Last updated: YYYY-MM-DD

## Contents

| File | Summary | Tags | Updated |
|------|---------|------|---------|
| [filename.md](filename.md) | One-sentence summary | tag1, tag2 | YYYY-MM-DD |

## Categories

- **category-name**: file1.md, file2.md

## Recent Changes

- YYYY-MM-DD: Description of change
```

### Master _index.md (root level)

Additionally includes:

```markdown
## Statistics

- Sources: N raw documents
- Articles: N compiled wiki articles
- Outputs: N generated artifacts
- Last compiled: YYYY-MM-DD
- Last lint: YYYY-MM-DD

## Quick Navigation

- [All Sources](raw/_index.md)
- [Concepts](wiki/concepts/_index.md)
- [Topics](wiki/topics/_index.md)
- [References](wiki/references/_index.md)
- [Outputs](output/_index.md)
```

## wiki_log.md Format

Append-only chronological activity log. Every wiki operation appends an entry. Never edit or delete existing entries. **Always open for append, never read-modify-write** — this makes concurrent writes safe (lines from multiple sessions interleave without corruption). Format is grep-friendly:

```markdown
# Wiki Activity Log

## [2026-04-04] init | Wiki initialized
## [2026-04-04] ingest | Attention Is All You Need (raw/papers/2026-04-04-attention-is-all-you-need.md)
## [2026-04-04] ingest | Illustrated Transformer (raw/articles/2026-04-04-illustrated-transformer.md)
## [2026-04-04] compile | 2 sources → 3 new articles, 1 updated (transformer-architecture, self-attention, sequence-modeling + updated attention-mechanisms)
## [2026-04-04] query | "How does self-attention work?" → answered from 2 articles
## [2026-04-05] lint | 12 checks, 0 critical, 2 warnings, 3 suggestions, 1 auto-fixed
## [2026-04-05] research | "transformer variants" → 5 sources ingested, 4 articles compiled
## [2026-04-05] output | summary on transformer-architecture → output/summary-transformer-architecture-2026-04-05.md
```

Each entry: `## [YYYY-MM-DD] operation | Description`

Operations: `init`, `ingest`, `compile`, `query`, `lint`, `research`, `output`, `refresh`, `librarian`, `audit`, `plan`, `project`, `ll`, `assess`

Useful for: `grep "^## \[" wiki_log.md | tail -10` to see recent activity.

## config.md Format

```markdown
---
title: "Wiki Title"
description: "What this wiki is about"
created: YYYY-MM-DD
freshness_threshold: 70
---

# Wiki Configuration

## Scope

[What topics this wiki covers]

## Conventions

[Any wiki-specific conventions beyond defaults]
```

## Source File Format (raw/)

```markdown
---
title: "Title"
source: "URL or filepath or MANUAL"
type: articles|papers|repos|notes|data
ingested: YYYY-MM-DD
tags: [tag1, tag2]
summary: "2-3 sentence summary"
---

# Title

[Full content]
```

## Wiki Article Format (wiki/)

```markdown
---
title: "Article Title"
category: concept|topic|reference
sources: [raw/type/file1.md, raw/type/file2.md]
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [tag1, tag2]
aliases: [alternate names for Obsidian discovery]
confidence: Confirmed|Stated|Inferred
decay_class: fast|med|slow
verified: YYYY-MM-DD
summary: "2-3 sentence summary for index"

# HORDE fork — Fortissimo additions (all optional, additive to nvk schema)
pillar: people_org|process_workflows|technology|third_party
source_provenance:
  chat_url: https://claude.ai/chat/...
  date: YYYY-MM-DD
  extraction: "context describing how the source was extracted"
em_refs: [FACT-PRO-2025-001, FACT-PEO-2026-008]
supersedes: [old-article-slug]
superseded_by: [new-article-slug]
---

# Article Title

> [One-paragraph abstract]

## [Sections as appropriate]

[Synthesized content — explain, contextualize, connect. NOT copy-paste.]

When referencing another wiki article inline, use dual-link format:
[[article-slug|Display Name]] ([Display Name](../category/article-slug.md))

This ensures both Obsidian (reads [[wikilink]]) and the agent (follows relative path) can navigate.

## See Also

- [[related-slug|Related Article]] ([Related Article](../category/related-slug.md)) — relationship note

## Sources

- [Source Title](../../raw/type/file.md) — what this source contributed
```

## Decay Class Classification

Wiki articles carry a `decay_class` field that controls how quickly their freshness score decays. The `verified` field records when a human last confirmed the article's conclusions are still accurate.

> **Naming note (HORDE fork):** upstream nvk calls this field `volatility` with values `hot|warm|cold`. The HORDE fork renames it to `decay_class` with values `fast|med|slow` to avoid colliding with Aziz's Engagement Memory v1.5 storage tiers (`Archive Hot`, `Archive Warm`, `Archive Cold`), which mean "tier of demoted-by-capacity content," not "subject-matter volatility." Same algorithm, same half-lives — different name.

| Tier | Decay rate | When to use | Examples |
|------|-----------|-------------|----------|
| `fast` | Fast | Fast-moving sources: regulations, vendor specs, current events, competitive landscape, threat intelligence | CVE feeds, NIST CSF release notes, vendor pricing |
| `med` | Moderate | Quarterly-to-annual cadence: frameworks, best practices, market analysis | Testing patterns, framework comparisons, control mappings |
| `slow` | Slow | Foundational concepts, historical events, mathematical proofs, stable reference | TCP/IP fundamentals, cryptographic algorithms, foundational standards |

Default is `med`. The compilation agent sets decay class based on source characteristics: news/trends and rapidly-changing reference sources suggest `fast`, foundational/historical sources suggest `slow`. Authors can override.

### Freshness Score (0-100)

Each article's freshness is a composite of four dimensions, each contributing 0-25 points:

| Dimension | What it measures | Computed from |
|-----------|-----------------|---------------|
| **Source freshness** | How old are the raw sources this article was compiled from? | Average days since `ingested:` across all `sources:` entries |
| **Verification recency** | When did a human last confirm accuracy? | Days since `verified:` |
| **Compilation recency** | When was this article last recompiled? | Days since `updated:` |
| **Source chain integrity** | Do all referenced sources still exist? | % of `sources:` entries that resolve to actual files |

Each dimension's decay curve is scaled by the article's `decay_class` tier — a `fast` article's source freshness decays faster than a `slow` one's. The Lindy Effect applies: `slow` content that has survived without needing updates is more durable, not less.

The freshness threshold is set per wiki in `config.md` (default: 70). Articles scoring below the threshold are flagged by lint. There are no hardcoded day cutoffs — the composite score naturally flags the right articles at the right time based on their decay class and the actual state of their sources.

## Fortissimo Frontmatter Fields (HORDE fork — Pass 5)

Four optional fields are added on top of nvk's schema for cross-citation with Aziz's Engagement Memory v1.5 and supersession discipline. All four are additive — articles without them stay valid; lint does not require them.

### `pillar:`

Marks which Fortissimo pillar an article belongs to. Used for cross-citation with EM entries (which carry the same pillar slugs). One of:

| Slug | Display | Covers |
|---|---|---|
| `people_org` | People & Organization | Roles, RACI, governance, org charts, headcount |
| `process_workflows` | Process & Workflows | Methodology, runbooks, four-question framework, citation discipline |
| `technology` | Technology | Tools, infra, platforms, vendor specs |
| `third_party` | Third Party | Suppliers, contractors, regulators, external auditors, frameworks-as-orgs |

Optional in `commons:` and `personal:` topics. Recommended in `client:` topics so EM and RC stay aligned.

### `source_provenance:`

Aziz's structured citation block, alongside nvk's machine-readable `sources: [path]` list. Extracts the chat URL, date, and human description of how the source was obtained. Use when the source came from a Claude/ChatGPT conversation, an interview transcript, or another reconstructed-from-context artifact where the bare path doesn't tell the full story.

```yaml
source_provenance:
  chat_url: https://claude.ai/chat/<id>
  date: 2026-04-29
  extraction: "Aziz GRC SecOps onboarding conversation — section 3 (third-party risk)"
```

When both `sources:` and `source_provenance:` are present, `sources:` is the canonical machine-readable list; `source_provenance:` is the human audit trail.

### `em_refs:`

List of Engagement Memory entry IDs that this article references or derives from. Lets a reader (or hook) trace from an RC article back to the EM facts/decisions it rests on.

```yaml
em_refs: [FACT-PRO-2025-001, FACT-PEO-2026-008, DEC-TEC-2026-003]
```

Phase 0 cross-citation is **one-way**: RC articles can list EM entry IDs, but EM v1.5 files don't carry RC slugs. Bidirectional linking is deferred to phase 2 EM migration.

### `supersedes:` / `superseded_by:`

Cross-version supersession (per Fortissimo §2.2). When a new article replaces an older one (e.g., NIST CSF 2.0 → 3.0, or a methodology revision), set both ends:

```yaml
# In nist-csf-3-0.md:
supersedes: [nist-csf-2-0]

# In nist-csf-2-0.md:
superseded_by: [nist-csf-3-0]
```

The superseded article stays in the wiki — it's the historical record. Lint warns if `superseded_by:` is set but the new article doesn't exist (broken supersession chain). Cross-references in active articles should prefer the most-recent version unless the historical one is what's actually being cited.

## Dual-Link Convention

All cross-references between wiki articles use BOTH link formats on the same line:

```
[[target-slug|Display Text]] ([Display Text](../category/target-slug.md))
```

- **Obsidian** reads the `[[wikilink]]` for its graph view, backlinks panel, and navigation
- **The agent** follows the standard markdown `(relative/path.md)` link
- Both coexist on one line so neither system misses the connection

For inline mentions in article body text, use the same pattern:
```
The [[transformer-architecture|Transformer]] ([Transformer](../concepts/transformer-architecture.md)) uses self-attention...
```

## Obsidian Compatibility

The wiki is designed to be opened as an Obsidian vault. On `/wiki init`, a `.obsidian/` config directory is created with minimal settings. Key compatibility notes:

- YAML frontmatter `tags` field is read natively by Obsidian
- `aliases` in frontmatter lets Obsidian find articles by alternate names
- `_index.md` files appear as regular notes in Obsidian (this is fine)
- The `inbox/` folder works as a natural Obsidian inbox
- Graph view shows connections via `[[wikilinks]]`

## Output Artifact Format (output/)

```markdown
---
title: "Output Title"
type: summary|report|study-guide|slides|timeline|glossary|comparison
sources: [wiki/category/article.md, ...]
generated: YYYY-MM-DD
---

[Content in the appropriate format for the type]
```

## File Naming

- **Raw sources**: `YYYY-MM-DD-descriptive-slug.md` (date prefix for chronological order)
- **Wiki articles**: `descriptive-slug.md` (no date — living documents)
- **Output artifacts**: `{type}-{topic-slug}-{YYYY-MM-DD}.md`
- All filenames: lowercase, hyphens for spaces, no special characters, max 60 chars

## Tag Convention

Tags are lowercase, hyphenated. Prefer specific over general:
- Good: `transformer-architecture`, `self-attention`, `natural-language-processing`
- Bad: `ai`, `ml`, `tech`

Normalize across the wiki — no near-duplicates like `ml` vs `machine-learning`.
