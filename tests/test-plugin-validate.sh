#!/bin/bash
# Validate plugin manifest and command/skill frontmatter
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PLUGIN_DIR="$PROJECT_ROOT/claude-plugin"
PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"
PASS=0
FAIL=0
TOTAL=0

log_pass() { PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1)); printf "  \033[32mPASS\033[0m: %s\n" "$1"; }
log_fail() { FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); printf "  \033[31mFAIL\033[0m: %s — %s\n" "$1" "$2"; }

echo "=== Plugin Validation ==="

# plugin.json
if [ -f "$PLUGIN_JSON" ]; then
  log_pass "plugin.json exists"
  if python3 -c "import json; json.load(open('$PLUGIN_JSON'))" 2>/dev/null; then
    log_pass "plugin.json is valid JSON"
  else
    log_fail "plugin.json is invalid JSON" "parse error"
  fi
else
  log_fail "plugin.json not found at $PLUGIN_JSON" "missing file"
fi

# Every command .md has frontmatter (starts with ---)
echo ""
echo "--- Command frontmatter ---"
for cmd in "$PLUGIN_DIR"/commands/*.md; do
  basename=$(basename "$cmd")
  if head -1 "$cmd" | grep -q "^---$"; then
    log_pass "frontmatter in commands/$basename"
  else
    log_fail "no frontmatter in commands/$basename" "missing ---"
  fi
done

# SKILL.md exists
echo ""
echo "--- Skill files ---"
if [ -f "$PLUGIN_DIR/skills/wiki-manager/SKILL.md" ]; then
  log_pass "SKILL.md exists"
  if head -1 "$PLUGIN_DIR/skills/wiki-manager/SKILL.md" | grep -q "^---$"; then
    log_pass "SKILL.md has frontmatter"
  else
    log_fail "SKILL.md has no frontmatter" "missing ---"
  fi
else
  log_fail "SKILL.md not found" "missing file"
fi

# Reference files exist
echo ""
echo "--- Reference files ---"
for ref in audit command-prelude compilation hub-resolution indexing ingestion librarian linting projects research-infrastructure wiki-structure; do
  reffile="$PLUGIN_DIR/skills/wiki-manager/references/${ref}.md"
  if [ -f "$reffile" ]; then
    log_pass "references/$ref.md exists"
  else
    log_fail "references/$ref.md missing" "missing file"
  fi
done

# HORDE: Codex/OpenCode mirror validation removed in phase 0 — single-runtime
# (Claude Code only). Sync scripts and generated mirrors deleted; AGENTS.md
# portable protocol removed. If multi-runtime distribution is reintroduced
# later, restore these checks from upstream nvk/llm-wiki@v0.5.0.

# HORDE Patch 13: Inline template drift detector.
# Commands that embed fenced YAML frontmatter blocks are drift surfaces — the
# inline template can fall out of sync with the canonical schema in
# wiki-structure.md (see HORDE-CUSTOMIZATIONS.md "Drift Prevention" for
# rationale). Maintain an explicit allowlist of commands that intentionally
# embed templates; flag any drift in either direction.
echo ""
echo "--- Inline template registry (HORDE Patch 13) ---"

# Allowlist: commands known to embed YAML frontmatter blocks intentionally.
# Each entry must have its template documented in wiki-structure.md.
EXPECTED_INLINE_TEMPLATES="ll.md research.md assess.md"

# Detect: a command "embeds a template" if it has at least 2 lines of `^---$`
# inside a fenced code block (open delim + close delim of a YAML block).
detect_inline_template() {
  local cmd="$1"
  awk '
    /^```/ { in_fence = !in_fence; next }
    in_fence && /^---$/ { count++ }
    END { exit (count >= 2 ? 0 : 1) }
  ' "$cmd"
}

ACTUAL_INLINE=""
for cmd in "$PLUGIN_DIR"/commands/*.md; do
  if detect_inline_template "$cmd"; then
    ACTUAL_INLINE="$ACTUAL_INLINE $(basename "$cmd")"
  fi
done
ACTUAL_INLINE="${ACTUAL_INLINE# }"

# Direction 1: every actually-inline command must be in the allowlist.
for cmd in $ACTUAL_INLINE; do
  if ! printf '%s\n' $EXPECTED_INLINE_TEMPLATES | grep -qx "$cmd"; then
    log_fail "unexpected inline template in commands/$cmd" "register in EXPECTED_INLINE_TEMPLATES (and document in wiki-structure.md), or replace with a reference to the canonical spec"
  fi
done

# Direction 2: every allowlisted command must still be inline (catches the
# case where someone rips out a template but forgets to update the registry).
for cmd in $EXPECTED_INLINE_TEMPLATES; do
  if ! printf '%s\n' $ACTUAL_INLINE | grep -qx "$cmd"; then
    log_fail "registered inline template missing from commands/$cmd" "registry expected this command to embed a template; either restore it or remove from EXPECTED_INLINE_TEMPLATES"
  fi
done

# Pass when both directions match.
if [ "$ACTUAL_INLINE" = "$(echo $EXPECTED_INLINE_TEMPLATES | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ $//')" ] || \
   [ "$(echo $ACTUAL_INLINE | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ $//')" = "$(echo $EXPECTED_INLINE_TEMPLATES | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ $//')" ]; then
  log_pass "inline template registry matches actual commands ($(echo $EXPECTED_INLINE_TEMPLATES | wc -w) registered)"
fi

echo ""
echo "==========================================="
printf "Results: \033[32m%d passed\033[0m, \033[31m%d failed\033[0m, %d total\n" "$PASS" "$FAIL" "$TOTAL"
echo "==========================================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
