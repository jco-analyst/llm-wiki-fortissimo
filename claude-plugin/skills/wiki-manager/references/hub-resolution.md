# Hub Path Resolution

Every wiki operation must resolve the hub path before doing anything else. Follow this protocol exactly.

## Why this protocol exists

The hub path can come from a workspace sentinel (HORDE fork — multi-engagement workspaces), config file (most common — iCloud, Dropbox, NAS), a symlink at `~/wiki/` pointing elsewhere, or `~/wiki/` directly (simple). Earlier versions checked `~/wiki/` first, but that fails in sandboxed environments where `~/wiki/` isn't an allowed path. The protocol below checks the sentinel first (cheap walk-up), then config (one file read), falling back to `~/wiki/` only when nothing is found.

> **Note (v0.4.1):** The resolution steps are now inlined directly in each
> command file. Commands no longer depend on reading this file at runtime. This
> file remains as canonical developer documentation for the protocol, but is not
> load-bearing for command execution.

> **HORDE fork (Pass 2):** Step 0 — workspace sentinel walk-up — is the preferred resolution path for Fortissimo workspaces. When `.fortissimo-vault.json` is found, HUB is the directory containing the sentinel and the rest of the steps are skipped. Config-based resolution remains for users who haven't migrated to a sentinel-rooted workspace.

## Resolution Steps

**This is a sequential file-read protocol. Do NOT use Explore agents, `find`, `ls -R`, or any filesystem search. Each step is a single Read tool call. Most HORDE-fork sessions resolve at step 0; everyone else resolves at step 1 or step 2.**

0. **Walk up from `cwd` looking for `.fortissimo-vault.json`** (HORDE fork). At each level, check for the sentinel file. Stop at the first match — first match wins, even if a parent also has one. If found, **HUB** = the directory containing the sentinel. Read the sentinel for workspace metadata (`workspace_name`, `topics_root`, `default_topic`, etc.) and skip the remaining steps. Walk-up stops at `$HOME` and at filesystem root. If not found, fall through to step 1.

1. **Read `~/.config/llm-wiki/config.json`** (expand `~` to `$HOME`).

2. **If config has `resolved_path`** → **HUB** = that value verbatim (it's already an absolute path — no expansion needed). Done.

3. **If config has only `hub_path`** (no `resolved_path`) → expand the leading `~` ONLY (see Tilde Expansion below), set **HUB**, then **write `resolved_path` back to config** so this expansion never has to happen again:
   ```json
   {
     "hub_path": "~/Library/Mobile Documents/com~apple~CloudDocs/wiki",
     "resolved_path": "/Users/jane/Library/Mobile Documents/com~apple~CloudDocs/wiki"
   }
   ```

4. **If no config exists** → try `$HOME/wiki/_index.md`. If it exists, **HUB** = `$HOME/wiki`. Done.

5. **If nothing found** → ask the user where they want the wiki before creating anything.

Most HORDE-fork sessions resolve at step 0 from the workspace sentinel. Non-fork users hit step 1-2 and resolve from config. The `~/wiki/` fallback (step 4) is only for users with no config file and no sentinel.

## Workspace Sentinel (HORDE fork)

The sentinel file `.fortissimo-vault.json` at the workspace root marks a Fortissimo workspace and carries metadata used by other commands. Its existence is what defines the workspace — directory layout alone is not enough.

Schema:

```json
{
  "workspace_name": "fortissimo",
  "owner": "aziz",
  "created": "YYYY-MM-DD",
  "em_root": "em",
  "topics_root": "topics",
  "default_topic": "commons"
}
```

Resolution rules:

- **First match wins.** If Aziz nests workspaces (one workspace inside another's directory tree), the inner sentinel resolves. Walking up never overshoots into a parent workspace.
- **Walk-up bounds.** Stop at `$HOME` (don't walk into other users' homes) and at filesystem root.
- **Topics root.** When the sentinel resolves, `HUB/topics/` is read from `topics_root` (default `topics`). Other commands honor this — never hardcode `topics/`.
- **EM placement.** `em_root` (default `em`) marks where Aziz's existing Engagement Memory v1.5 files live. Wiki commands never touch `HUB/em_root/`; it's owned by EM.

When `/wiki:init` creates a brand-new workspace, it writes the sentinel as part of HUB creation. Existing nvk workspaces (no sentinel) keep working via step 1-2 config resolution.

> **CRITICAL — Do NOT confuse directory existence with hub existence.**
> A directory may exist (e.g., leftover `.DS_Store`, empty folder, or a symlink to an uninitialized path) without being an initialized hub. Only `_index.md` existing at the hub root counts as an initialized hub.

> **Config is authoritative.** If `~/.config/llm-wiki/config.json` exists with a `hub_path` or `resolved_path`, ALL initialization MUST happen at the config path. Never create a hub at `~/wiki/` when config points elsewhere.

> **Never access `~/wiki/` when config exists.** In sandboxed environments, `~/wiki/` may not be an allowed path. The config path is the only path the agent should touch.

## Optional setup: symlink

For users who want the convenience of `~/wiki/` without granting sandbox access to their real wiki path, a symlink works:

```bash
ln -s "/Users/jane/Library/Mobile Documents/com~apple~CloudDocs/wiki" ~/wiki
```

This is optional — config-based resolution (steps 1-2) works without it. The symlink is a convenience for shell access, not a requirement for the agent.

## Tilde Expansion — Correct Method

Only needed when step 3 runs (first use with an old config that lacks `resolved_path`). Replace ONLY the leading `~` with the user's home directory. **Do NOT expand tildes anywhere else** — characters like `~` in `com~apple~CloudDocs` are literal directory names.

```bash
hub_path="~/Library/Mobile Documents/com~apple~CloudDocs/wiki"  # from config
expanded="${hub_path/#\~/$HOME}"
# Result: /Users/jane/Library/Mobile Documents/com~apple~CloudDocs/wiki
#                                  ↑ these tildes are UNTOUCHED
```

**Never** use `eval` or unquoted expansion — these break on paths with spaces.

## Paths with Spaces

The resolved path may contain spaces (e.g., `Mobile Documents`). When using the path in Bash commands, **always double-quote it**:

```bash
ls "$HUB/topics/"           # correct
ls $HUB/topics/             # WRONG — breaks on spaces
```

The Read, Write, Edit, Glob, and Grep tools handle spaces natively.

## After Resolution

Once HUB is resolved, determine which wiki to target:

1. `--local` flag → `.wiki/` in current directory
2. `--wiki <name>` flag → look up in `HUB/wikis.json`
3. Current directory has `.wiki/` → use it
4. Otherwise → HUB (the hub itself)
