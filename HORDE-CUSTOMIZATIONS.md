# HORDE Customizations on top of nvk/llm-wiki

This is a HORDE fork of [nvk/llm-wiki](https://github.com/nvk/llm-wiki), customized for the Fortissimo AI OS Reference Corpus pillar (single-operator GRC consulting practice — Aziz Malik, Fortissimo Solutions).

## Branch

- **Upstream tag**: `v0.5.0`
- **HORDE branch**: `horde/v0.5.0`
- **Fork rationale**: vocabulary alignment with Aziz's existing Engagement Memory v1.5 system, plus workspace-sentinel resolution for multi-engagement isolation prep.
- **Rebase strategy**: when nvk publishes a new release, `git fetch && git rebase v<new>` and apply this patch log to verify each customization still applies.

## Why this fork exists

- **Reference Corpus pillar of Fortissimo AI OS** ([spec §6.2](../../horde-knowledge/03-Repos/fortissimo-aios/raw/Fortissimo%20AI%20OS%20%E2%80%94%20Requirements%20Specification%20v0_1.md)) — co-resident with Aziz's existing v1.5 Engagement Memory in one workspace.
- **Karpathy's LLM Wiki pattern** ([gist verbatim](../../horde-knowledge/03-Repos/karpathy-llm-wiki/karpathy-llm-wiki-gist-verbatim.md)) is the canonical pattern; nvk is its most thorough community implementation.
- **Cross-topic peek is the feature, not a bug** — connections compounding across cybersecurity-frameworks + grc-methodology + per-client work + personal research is the whole point.
- **Phase 0 is single-client (Uline)**; cross-engagement isolation deferred to a future hook layer when client #2 arrives.

## Customization design doc

Plan: `~/.claude/plans/1-decay-fast-med-slow-2-abstract-pond.md`
Anchor decision: `horde-knowledge/06-Design/karpathy-wiki-anchor-decision.md`
Beads: `horde-je7.31.2` (workspace skeleton), `horde-je7.31.3` (ops customization)

## Patch list

Each entry: numbered patch, file(s) touched, semantic category, rationale. Patches stay surgical — vocabulary or schema, not algorithm changes.

| # | File(s) | Category | Why |
|---|---|---|---|
| 01 | claude-plugin/skills/wiki-manager/{SKILL,references/{wiki-structure,compilation,librarian,linting,audit,research-infrastructure}}.md, claude-plugin/commands/{librarian,lint,refresh,query,research,ll}.md, AGENTS.md, tests/* | vocabulary | Vocabulary swap: `volatility:` → `decay_class:` (`hot\|warm\|cold` → `fast\|med\|slow`) and `confidence:` enum (`high\|medium\|low` → `Confirmed\|Stated\|Inferred`). Aligns with Aziz's EM v1.5 Confirmed/Stated/Inferred. Decay class rename avoids collision with EM Archive Hot/Warm/Cold storage tiers. Defect fixture `missing-volatility/` renamed `missing-decay-class/`. Test enum lists updated. All 92 structural assertions pass; codex+opencode mirrors regenerated. |
| 02 | scripts/, plugins/, .agents/, AGENTS.md, tests/test-codex-*.sh, tests/test-opencode-sync.sh, README.md, CLAUDE.md, tests/ci/plugin-tests.yml, tests/test-plugin-validate.sh | distribution | Drop multi-runtime distribution. Phase 0 of HORDE fork is Claude Code only. Removed: Codex sync/bootstrap/verify scripts, OpenCode sync script, Codex+OpenCode mirror dirs, Codex marketplace JSON, AGENTS.md portable protocol, codex/opencode test scripts, codex mirror validation in test-plugin-validate.sh, codex sync step in CI workflow. README.md gets HORDE-fork banner; CLAUDE.md (project-level) rewritten for single-runtime. To restore multi-runtime distribution later, reapply from upstream nvk/llm-wiki@v0.5.0. Verified: tests/test-plugin-validate.sh 31/31 pass; tests/test-structure.sh 92/92 pass. |
| 03 | claude-plugin/skills/wiki-manager/references/hub-resolution.md, claude-plugin/commands/wiki.md | sentinel | Workspace sentinel resolution. Add Step 0 to hub resolution: walk up from `cwd` looking for `.fortissimo-vault.json`, first match wins, walk-up bounded by `$HOME`/filesystem root. Sentinel carries workspace metadata (`workspace_name`, `owner`, `created`, `em_root`, `topics_root`, `default_topic`). `wiki.md` resolution prelude updated with the same Step 0; `init` writes the sentinel as part of HUB creation when no HUB exists. Existing nvk workspaces without the sentinel keep working via config fallback. |
| 04 | claude-plugin/skills/wiki-manager/references/wiki-structure.md, claude-plugin/commands/wiki.md | schema | `wikis.json` extension: `commons:`/`client:`/`personal:` isolation flags on each topic wiki entry, mutually exclusive. Documented as forward-compatible — read by future isolation hooks, ignored in phase 0. `init` accepts `--commons`, `--client <name>`, `--personal` flags; prompts when none provided. Future isolation rule documented (commons-visible-to-all, one-client-at-a-time, personal-to-owner) for the hook layer when client #2 arrives. Lint rule placeholder noted (C-isolation) for cross-citation review. |
| 05 | claude-plugin/skills/wiki-manager/references/wiki-structure.md | frontmatter | Four optional Fortissimo frontmatter additions on wiki articles: `pillar:` (people_org/process_workflows/technology/third_party — cross-cite EM entries), `source_provenance:` (chat_url + date + extraction context, alongside nvk's `sources:`), `em_refs:` (EM entry ID pointers, e.g., `FACT-PRO-2025-001`), `supersedes:`/`superseded_by:` (cross-version supersession per Fortissimo §2.2). All additive — articles without them stay valid; lint does not require them. Phase 0 cross-citation is one-way (RC→EM) until phase 2 EM migration. |
| 06 | .claude-plugin/marketplace.json, claude-plugin/.claude-plugin/plugin.json | rebrand | Marketplace renamed `llm-wiki` → `llm-wiki-fortissimo` (matches the GitHub repo, avoids collision with upstream). Plugin name stays `wiki` (commands keep the `/wiki:` prefix Aziz is used to). Owner / author updated to credit jco-analyst as the HORDE fork maintainer; descriptions reference the HORDE fork plus nvk lineage; keywords expanded with `fortissimo`, `horde`, `grc`. |
| 07 | claude-plugin/commands/wiki.md | onboarding | First-run primer in the `init` flow. New step 0 shows a "what's about to be created" pre-init message before HUB creation (only fires when HUB doesn't exist). Step 8 expanded with first-run orientation: three core ops (ingest/compile/query), three topic types (commons/client/personal), cross-topic peek explanation, EM coexistence note, frontmatter cross-citation overview, beyond-core ops index, and how to add more topics. Subsequent-init invocations (HUB already exists) keep the brief command suggestions. |
| 08 | claude-plugin/commands/{init.md (new), topic.md (new), wiki.md (thinned)} | refactor | Split init into two distinct commands. nvk's design folded "bootstrap a workspace" and "create a topic" into one `init` flow — natural mismatch with users' mental model and awkward when teaching the system. New split: `/wiki:init` is workspace-only (sentinel + hub files + first-run orientation, no topic argument); `/wiki:topic <name>` creates topics in an existing workspace (errors helpfully if no workspace), prompts for the isolation flag if not passed. The post-init orientation in `/wiki:init` ends with "Next step: create your first topic — `/wiki:topic <name> --commons|--client <name>|--personal`". `wiki.md` keeps the natural-language router (16 priority patterns), the status view, and the config commands; "no wiki found" branch redirects at `/wiki:init` instead of running bootstrap inline. Argument-hint and description updated to match the new role. Tests: 33/33 plugin-validate (two new commands picked up by the wildcard), 92/92 structural still pass. |
| 09 | rename throughout: claude-plugin/{commands/*.md, skills/wiki-manager/{SKILL.md, references/*.md}}, tests/{test-structure.sh, fixtures/**/log.md→wiki_log.md} | filename | Rename `log.md` → `wiki_log.md` everywhere (both workspace-level and per-topic activity logs). nvk's generic `log.md` collides with whatever else a workspace root might already contain — concrete case: Aziz might keep an EM-related `log.md` at his workspace root, and Jon's horde repo already has a `log.md` (ingest-kb skill). `wiki_log.md` is unambiguous about ownership. ~50 prose references and 14 fixture files renamed. Append-only semantics, format, lint rules unchanged. Section "## log.md Format" in `references/wiki-structure.md` becomes "## wiki_log.md Format" — content unchanged. Tests: 33/33 plugin-validate, 92/92 structural still pass. |
| 10 | claude-plugin/commands/init.md | onboarding | Walkthrough section added to the post-init primer — teaches by worked example instead of describing each command in the abstract. Steps: create-topic → ingest → compile → query → ll → lint+librarian, with literal example commands (NIST CSF as the concrete topic) showing exactly what to type. Closes with the natural-language router shortcut and a note that the reference sections below are for skim-now-refer-back-later. Sits between "Workspace ready" and "How the wiki is laid out" so first-run users see the worked flow before the deeper reference. |
| 11 | claude-plugin/commands/ll.md, claude-plugin/skills/wiki-manager/references/wiki-structure.md | schema | Align the `/wiki:ll` Stage 4 raw-note template to the canonical raw-source schema. Pre-fix template used `type: lessons-learned` (not in enum), `date:` (canonical key is `ingested:`), and `category: notes` (raw sources don't carry `category:`) — drift inherited from upstream nvk commit 95249d4 ("Add /wiki:ll"). Post-fix template uses `type: notes`, `ingested:`, drops `category:`, and keeps `confidence:` + `lesson_count:` as documented optional extensions in `wiki-structure.md` § Source File Format → Optional Extensions. Heals 3 critical lint findings (C2 missing `ingested:`, C2 invalid `type` enum, C11 placement ambiguity) without losing the LL-specific signals that downstream `/wiki:compile` uses. |
| 12 | claude-plugin/commands/research.md, claude-plugin/skills/wiki-manager/references/wiki-structure.md | schema | Align the `/wiki:research --mode thesis` template to the canonical wiki-article schema, document thesis-specific extensions. Pre-fix template was missing required `tags`, `summary`, `decay_class`, `verified` fields and used `confidence: pending` (not in the canonical Confirmed/Stated/Inferred enum, which is the result of Patch 01 — Patch 12 is partly an audit miss against Patch 01). Post-fix template adds the four canonical fields, omits `confidence:` during investigation (set on verdict from the canonical enum), and `wiki-structure.md` gains a new "Thesis Frontmatter (wiki/theses/)" section that legitimizes `status`, `verdict`, `core_claim`, `key_variables`, `falsification` as investigation-specific extensions. Lint must treat these as known extensions, not unknown keys. |
| 13 | HORDE-CUSTOMIZATIONS.md, tests/test-plugin-validate.sh | drift-prevention | Codify the lint-as-migration principle for inline templates. Adds a "Drift Prevention" section to this file, plus an inline-template registry test in `test-plugin-validate.sh` that diffs every fenced YAML block in `commands/` against an explicit allowlist (`ll.md`, `research.md`, `assess.md`). New embedded templates fail the test until registered, forcing a conscious decision: either match the canonical schema in `wiki-structure.md` exactly or replace the inline block with a reference to the spec. Trades one new test for systemic protection against the kind of drift Patches 11 and 12 had to clean up. |
| 14 | claude-plugin/skills/wiki-manager/references/linting.md | lint-rules | Two related fixes for HUB-level lint behavior surfaced by the first embedded-workspace deployment. (a) Add `.fortissimo-vault.json` to the C12 HUB allowlist and update C11's hub-content sentence — the sentinel was introduced by Patch 03 but never registered as a wiki-owned HUB file, so strict lint would flag it as unknown. (b) Add a new "Scoping Rules" section that distinguishes standalone workspaces (no sentinel, strict HUB checks) from embedded workspaces (sentinel present, scoped HUB checks — foreign items at HUB are ignored rather than flagged). C11 placement and C12 unknown-file checks now respect this scope at HUB level only; per-topic checks are unchanged. Without this fix, running `/wiki:lint` against an embedded workspace would flag every host-project file as misplaced/unknown — useless noise that hides actionable wiki findings. |

(Patches added below as commits land.)

## Guiding principle

**nvk's algorithms and topology are the asset; nvk's vocabulary is the variable.** A line gets edited only when one of three conditions holds:

1. Aziz's vocabulary requires it (cross-citation between EM and RC must read coherently).
2. Fortissimo spec mandates it (workspace marker, EM placement, isolation metadata).
3. A nvk concept collides head-on with an Aziz concept and would cause real ambiguity (decay vs storage tier).

If any single file's diff exceeds **~30% of lines changed**, stop and reclassify — the file likely belongs in REPLACE, not SURGICAL.

## Drift Prevention (added 2026-04-29)

Inline frontmatter templates embedded in command files are a drift surface. When a template is duplicated in `commands/<x>.md` instead of referenced from `skills/wiki-manager/references/wiki-structure.md`, schema changes that update the spec leave the inline copy out of sync. Patches 11 and 12 cleaned up two such drifts inherited from upstream nvk and one introduced by our own Patch 01 (the `confidence: pending` thesis placeholder).

**Rule**: command-side inline templates must satisfy one of three conditions:

1. **Match the canonical schema in `wiki-structure.md` exactly**, including documented optional extensions for that file kind.
2. **Be replaced by a reference** to the section of `wiki-structure.md` that defines the canonical template (preferred when the schema is non-trivial).
3. **Be registered in the inline-template allowlist** (`tests/test-plugin-validate.sh` — currently `ll.md`, `research.md`, `assess.md`) along with any extensions documented in `wiki-structure.md`.

The test enforces (3) — it fails if a new command grows an embedded YAML block without being added to the allowlist, and fails if a registered command stops embedding a template (likely indicates the schema spec drifted out of registry).

This is the inline-template counterpart to the lint-is-the-migration principle in `references/linting.md`: the schema definition lives in one place, and tooling enforces that everything else points to it rather than duplicating it.

## Vocabulary substitutions

| nvk term | Aziz/Fortissimo term |
|---|---|
| `confidence: high\|medium\|low` | `confidence: Confirmed\|Stated\|Inferred` |
| `volatility: hot\|warm\|cold` | `decay_class: fast\|med\|slow` |
| `~/wiki/` (default) | Workspace path resolved from sentinel |

## Frontmatter additions (additive)

| Field | Purpose |
|---|---|
| `pillar:` | Cross-citation with EM entries (`people_org`/`process_workflows`/`technology`/`third_party`) |
| `source_provenance:` | Aziz's structured citation (chat_url, date, extraction context) |
| `em_refs:` | Pointer to related EM entry IDs (e.g., `FACT-PRO-2025-001`) |
| `supersedes:` / `superseded_by:` | Cross-version supersession (NIST 2.0 → 3.0) |

## `wikis.json` extensions

Added `commons:`/`client:`/`personal:` flags per wiki entry — read by future isolation hooks, ignored in phase 0.

## Workspace sentinel

`.fortissimo-vault.json` at workspace root — marker plus metadata holder (workspace_name, owner, em_root, topics_root, default_topic).
