---
description: "Bootstrap a Fortissimo wiki workspace. Writes the workspace sentinel, hub-level files, and shows the first-run orientation. Run once per workspace; use /wiki:topic afterward to create topic wikis."
argument-hint: "[<workspace-path>]"
allowed-tools: Read, Write, Edit, Glob, Bash(ls:*), Bash(wc:*), Bash(mkdir:*), Bash(date:*), Bash(mv:*)
---

## Your task

Bootstrap a Fortissimo wiki workspace. This is a one-time operation per workspace — once the sentinel exists, every other `/wiki:` command finds the workspace automatically.

**Resolution prelude** — check whether a workspace already exists:
0. **(HORDE fork)** Walk up from `cwd` looking for `.fortissimo-vault.json`. If found → workspace already exists at the directory containing the sentinel; abort with: "Workspace already initialized at `<path>/`. To add a topic, run `/wiki:topic <name>`."
1. Read `$HOME/.config/llm-wiki/config.json`. If it has `resolved_path` and `<resolved_path>/_index.md` exists → workspace exists; abort same way.
2. Read `$HOME/wiki/_index.md`. If it exists → workspace exists; abort same way.
3. No workspace yet → proceed.

### Parse $ARGUMENTS

- `<workspace-path>` (positional, optional) — where to create the workspace. If omitted, ask the user.

### First-run primer

Before creating anything, show:

> **Setting up your Fortissimo wiki workspace.**
>
> A workspace is a single root directory holding all your topic wikis plus shared metadata. Once it exists, every `/wiki:` command run from anywhere inside the workspace finds the right hub automatically — no environment variables, no config flags, no daily fiddling.
>
> About to create:
> - **`<HUB>/`** — workspace root (where you tell me)
> - **`<HUB>/topics/`** — directory where every topic wiki lives (initially empty; you'll add topics with `/wiki:topic <name>`)
> - A few small metadata files at the workspace root: a sentinel marking this as a workspace, a registry of your topics with isolation flags (`commons` / `client` / `personal`), an append-only activity log spanning all topics, and a top-level navigation index
>
> **Engagement Memory note:** if you keep an EM v1.5 store at `<HUB>/em/`, the wiki never touches it. The wiki and EM are separate stores with separate lifecycles — the post-init orientation explains how they cross-cite.
>
> Continue?

Pause for confirmation. If the user provided `<workspace-path>` in arguments, use that; otherwise ask "Where should the workspace live? (e.g., `~/Documents/fortissimo`)". Expand `~` to `$HOME`. Then proceed.

### Steps

1. Create the workspace directory if it doesn't exist (`mkdir -p <HUB>`).

2. Ask the user for `workspace_name` (default: directory basename) and `owner`.

3. Write `<HUB>/.fortissimo-vault.json` (the sentinel + workspace metadata):
   ```json
   {
     "workspace_name": "<answer>",
     "owner": "<answer>",
     "created": "YYYY-MM-DD",
     "em_root": "em",
     "topics_root": "topics"
   }
   ```

4. Write `<HUB>/wikis.json` with an empty registry:
   ```json
   {
     "default": null,
     "wikis": {},
     "local_wikis": []
   }
   ```

5. Write `<HUB>/_index.md` (hub-level navigation):
   ```markdown
   # Wiki Workspace

   > Your Fortissimo wiki workspace. Topics are listed below; add a new one with `/wiki:topic <name>`.

   Created: YYYY-MM-DD
   Workspace: <workspace_name>
   Owner: <owner>

   ## Topics

   _No topics yet. Run `/wiki:topic <name>` to create one._

   ## Recent Activity

   See `log.md`.
   ```

6. Write `<HUB>/log.md` with the initial entry:
   ```
   # Wiki Activity Log

   ## [YYYY-MM-DD] init | Workspace initialized
   ```

7. Create empty `<HUB>/topics/` (or `<HUB>/<topics_root>/` if the sentinel's `topics_root` differs from `topics`).

8. NO `raw/`, `wiki/`, `output/`, `inbox/`, `config.md`, or `.obsidian/` at the workspace root. The Engagement Memory store lives at `<HUB>/em/` (or wherever `em_root` points) and is owned by EM, not the wiki — never create or modify it here.

9. Show the first-run orientation:

   > **Workspace ready** at `<HUB>/`.
   >
   > ### How the wiki is laid out
   >
   > Every topic wiki you create will have three content layers, each with a clear role:
   >
   > **`raw/`** — immutable source material. When you ingest a URL, file, or pasted text, the content lands here verbatim with frontmatter (title, source URL, ingest date, type, summary). Sources are NEVER edited after ingestion — that's what makes them reproducible. Subdirectories sort by source kind: `articles/`, `papers/`, `repos/`, `notes/`, `data/`.
   >
   > **`wiki/`** — synthesized articles compiled from sources. These ARE edited — articles evolve as more sources accumulate. Each article carries a `sources:` frontmatter list naming the raw files it was compiled from, so you can always trace a claim back to its origin. Subdirectories by article kind: `concepts/` (foundational explanations), `topics/` (broader syntheses), `references/` (factual lookup), `theses/` (claim-driven investigations).
   >
   > **`output/`** — generated artifacts: summaries, reports, study guides, deliverables. Each project lives at `output/projects/<slug>/` with a `WHY.md` stating the goal. Outputs cite wiki articles, not raw sources directly — so an output's freshness inherits from the articles it cites.
   >
   > Plus per-topic infrastructure: `inbox/` (drop zone — files dropped here get picked up by `/wiki:ingest --inbox`), `config.md` (topic title, scope, conventions), `log.md` (per-topic activity log), `.obsidian/` (Obsidian vault config).
   >
   > ### The operation lifecycle
   >
   > Once you have a topic, knowledge flows through it in stages. The first four are how knowledge gets in, gets synthesized, gets used, and gets captured. The last three are maintenance.
   >
   > 1. **`/wiki:ingest <url|file|text>`** — brings external material in. The agent fetches the URL (with fallbacks for X.com, paywalls, dead links), assigns a date-prefixed slug for the filename, fills in frontmatter, appends to `log.md`. Idempotent — re-ingesting an already-known URL says "already have it." Sources go to `raw/<type>/` and are never touched after.
   >
   > 2. **`/wiki:compile`** — reads unprocessed sources (or a flagged subset), synthesizes them into wiki articles. Decides whether to create a new article or update an existing one. Sets `confidence:` (Confirmed / Stated / Inferred) based on how many sources agree. Sets `decay_class:` (fast / med / slow) based on subject volatility. Writes dual-link cross-references (Obsidian-style `[[wikilink]]` plus relative markdown path) so both Obsidian and the agent can navigate. Re-runnable — running compile after each ingest is fine; running it after several ingests batches the work.
   >
   > 3. **`/wiki:query "<question>"`** — answers from existing wiki articles. Reads articles first; falls back to raw sources only when the article doesn't have enough. Every answer cites the articles plus the underlying sources. Modes: `--quick` (one article, fast), `--standard` (default, multi-article), `--deep` (multi-article synthesis with reasoning trace), `--resume` (pick up an interrupted session).
   >
   > 4. **`/wiki:ll [topic-hint]`** — captures lessons-learned from the current session into the wiki. While `ingest` brings external material in (URLs, files), `ll` brings *internal* session knowledge in: error→fix patterns, user corrections, surprising discoveries, configuration changes, gotchas. The agent scans the conversation, distills the takeaways, and writes them as wiki articles with full frontmatter (sources, confidence, decay_class, tags) into the right `wiki/{concepts,topics}/` subdirectory. This is how working knowledge becomes reference material — particularly valuable for moving methodology from a `client:` topic into a `commons:` topic so it carries forward to the next engagement. Pass `--dry-run` to preview without writing; pass `--rules` to also suggest workspace `CLAUDE.md` rule additions.
   >
   > 5. **`/wiki:librarian`** — quality scan. Computes a freshness score (0-100) for each article from four dimensions: how old are the sources, when did a human last verify (`verified:`), when was the article last recompiled (`updated:`), do all sources still resolve. Each dimension's decay curve is scaled by the article's `decay_class` — fast articles age quickly (regulations, threat intel), slow articles barely age (foundational concepts, math). Articles below threshold (default 70 in `config.md`) land in a `REPORT.md` with suggested next steps.
   >
   > 6. **`/wiki:lint`** — structural integrity check. Fifteen rules: dead links, missing indexes, stale indexes (file count vs index count drift), orphan sources (in `raw/` but not cited), duplicate tags, mis-placed files, broken supersession chains, missing required frontmatter fields. Lint is cheap — run it freely after compiles and before commits.
   >
   > 7. **`/wiki:refresh <article>`** — when sources for an article have aged past their decay curve, re-verify the article's claims against current versions of those sources. Updates `verified:` after the agent confirms the claims still hold. Use this when `librarian` flags an article you actually want to keep current.
   >
   > ### Topic types and isolation
   >
   > Every topic carries an isolation flag (chosen when you create the topic with `/wiki:topic`):
   > - **`commons`** — generally-applicable knowledge: frameworks, methodology, standards. Not specific to any one engagement.
   > - **`client: "<name>"`** — engagement-specific knowledge. Tagged with the client name (e.g., `client: "uline"`).
   > - **`personal`** — your own research, learning, notes — separate from any client work.
   >
   > The flag is documentation today. Tomorrow, when a second engagement arrives, a hook layer reads these flags to keep client material from leaking across engagements automatically. Until then: be deliberate about which topic each ingest lands in. A NIST CSF document goes in `cybersecurity-frameworks/` (commons), not in `uline/` (client) — that way both engagements benefit from the framework analysis without duplicating it.
   >
   > ### Wiki article frontmatter
   >
   > Every wiki article has YAML frontmatter that drives tooling:
   >
   > - `category:` — concept | topic | reference | thesis
   > - `sources:` — list of `raw/` files this article was compiled from
   > - `confidence:` — Confirmed (multiple agreeing sources or peer-reviewed) | Stated (single credible source) | Inferred (derived or extrapolated)
   > - `decay_class:` — fast (regulations, vendor specs, threat intel) | med (frameworks, best practices) | slow (foundational concepts, math, principles)
   > - `verified:` — date a human last confirmed accuracy
   > - `tags:` — lowercase, hyphenated, specific (`transformer-architecture` not `ai`)
   > - `aliases:` — alternate names so Obsidian and the agent find the article via variant search terms
   >
   > Fortissimo additions (all optional, all additive — articles without them stay valid):
   > - `pillar:` — `people_org` | `process_workflows` | `technology` | `third_party` (cross-cite Engagement Memory entries)
   > - `em_refs:` — list of EM entry IDs this article rests on (e.g., `[FACT-PRO-2025-001, DEC-TEC-2026-003]`)
   > - `source_provenance:` — `chat_url:` + `date:` + `extraction:` for sources reconstructed from conversations or interview transcripts
   > - `supersedes:` / `superseded_by:` — cross-version handoff (e.g., NIST CSF 2.0 → 3.0). The superseded article stays as the historical record.
   >
   > ### Engagement Memory coexistence
   >
   > If you keep an EM v1.5 store at `<HUB>/em/`, the wiki never touches it. The two stores serve different roles:
   > - **EM** — your engagement memory: current state, decisions in flight, contextual facts, demoted by capacity tier (Hot / Warm / Cold / Frozen).
   > - **Wiki** — your reference corpus: durable knowledge, multi-source articles, freshness scored by `decay_class`.
   >
   > Wiki articles cross-cite EM entries via `em_refs:`. EM stays owned by EM; the wiki stays owned by the wiki. Different stores, different lifecycles, linked by ID.
   >
   > ### Beyond the core ops
   >
   > - **`/wiki:research <topic> --sources 10`** — parallel-agent web research, auto-ingest results. Use when you want to bootstrap a topic from scratch.
   > - **`/wiki:audit`** — truth-seeking audit of an output artifact. Follows the citation chain from output → wiki article → raw source, flags drift.
   > - **`/wiki:project new <slug> "<goal>"`** — start a deliverable folder with a `WHY.md`. Subsequent commands run inside the project context.
   > - **`/wiki:retract <source>`** — pull a source back out (removes it from `raw/`, marks dependent articles for re-compilation).
   >
   > ### Next step: create your first topic
   >
   > Pick the kind that fits and run one of:
   >
   > - `/wiki:topic <name> --commons` — generally-applicable knowledge (frameworks, methodology, standards)
   > - `/wiki:topic <name> --client <client-name>` — engagement-specific knowledge
   > - `/wiki:topic <name> --personal` — your own research / learning
   >
   > Type `/wiki:wiki "<freeform request>"` anytime to let the natural-language router pick the right command for you (e.g., `/wiki:wiki "what does NIST CSF say about supply chain risk"` → query). Type `/wiki:wiki` with no args for status.
