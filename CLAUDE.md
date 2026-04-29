# llm-wiki-fortissimo Development Guide

> **HORDE fork note:** this is a HORDE fork of nvk/llm-wiki@v0.5.0, customized for the Fortissimo AI OS Reference Corpus pillar. **Phase 0 is single-runtime — Claude Code only.** The upstream Codex and OpenCode mirrors, sync scripts, and `AGENTS.md` portable protocol have been removed. To restore multi-runtime distribution, see upstream nvk/llm-wiki@v0.5.0. See `HORDE-CUSTOMIZATIONS.md` for the patch log.

## Testing

Run tests before declaring any change to plugin code done.

### Structural tests (always run — no LLM, instant)

```bash
./tests/test-plugin-validate.sh   # plugin manifest + command frontmatter
./tests/test-structure.sh         # wiki fixture validation (C1-C15 lint rules)
```

If you changed the golden wiki fixture, regenerate defect fixtures first:

```bash
./tests/generate-defect-fixtures.sh
```

### Behavioral evals (run when changing command logic)

```bash
npx promptfoo@latest eval -c tests/promptfooconfig.yaml
```

Requires `ANTHROPIC_API_KEY`. Costs ~$2-5 per run.

### When to update tests

- **Added a new lint rule**: add a defect fixture in `generate-defect-fixtures.sh` and a negative test case in `test-structure.sh`.
- **Changed frontmatter schema** (new required field, renamed enum): update the golden wiki fixture files to match, update `test-structure.sh` field/enum lists, regenerate defect fixtures.
- **Added a new command**: add a frontmatter check to `test-plugin-validate.sh` if it's not picked up by the wildcard. Add a behavioral eval in `promptfooconfig.yaml` for routing.
- **Changed the fuzzy router**: add or update test cases in `promptfooconfig.yaml` covering the new routing behavior plus negative controls.
- **Added a new reference file**: add the filename to the `for ref in ...` loop in `test-plugin-validate.sh`.
- **Changed directory structure** (new `raw/` or `wiki/` subdirectory): update `test-structure.sh` C1 directory list and C11 placement checks. Update the golden wiki fixture if needed.

### Test file locations

- `tests/fixtures/golden-wiki/` — known-correct wiki (3 sources, 2 articles, all indexes)
- `tests/fixtures/defects/` — generated broken wikis (one per lint rule)
- `tests/promptfooconfig.yaml` — Promptfoo behavioral eval config
- `tests/evals/assertions/*.js` — custom JS assertions for file-system checks
- `tests/ci/plugin-tests.yml` — GitHub Actions workflow (copy to `.github/workflows/` to activate)

## Project Structure

```
claude-plugin/                  — source of truth, single distribution target
  commands/*.md                 — 16 command files (15 user commands + wiki router)
  skills/wiki-manager/
    SKILL.md                    — skill manifest + fuzzy router
    references/*.md             — 11 reference docs (hub-resolution, linting, audit, etc.)
  .claude-plugin/
    plugin.json                 — plugin manifest
HORDE-CUSTOMIZATIONS.md         — patch log on top of upstream nvk/llm-wiki@v0.5.0
tests/                          — test suite (see above)
```

## Release Process

This is a HORDE-internal fork. We don't cut releases; we rebase against upstream nvk/llm-wiki tags and reapply the patch log. See `HORDE-CUSTOMIZATIONS.md` for the rebase workflow.
