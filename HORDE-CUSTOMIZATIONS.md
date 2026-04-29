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
