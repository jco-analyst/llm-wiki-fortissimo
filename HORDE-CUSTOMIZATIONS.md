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

(Patches added below as commits land.)

## Guiding principle

**nvk's algorithms and topology are the asset; nvk's vocabulary is the variable.** A line gets edited only when one of three conditions holds:

1. Aziz's vocabulary requires it (cross-citation between EM and RC must read coherently).
2. Fortissimo spec mandates it (workspace marker, EM placement, isolation metadata).
3. A nvk concept collides head-on with an Aziz concept and would cause real ambiguity (decay vs storage tier).

If any single file's diff exceeds **~30% of lines changed**, stop and reclassify — the file likely belongs in REPLACE, not SURGICAL.

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
