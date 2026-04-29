---
description: "Create a topic wiki within an existing Fortissimo workspace. Topics carry an isolation flag (commons / client / personal) and hold sources, articles, and outputs. Run after /wiki:init."
argument-hint: "<name> [--commons|--client <client-name>|--personal] [--local]"
allowed-tools: Read, Write, Edit, Glob, Bash(ls:*), Bash(wc:*), Bash(mkdir:*), Bash(date:*), Bash(mv:*)
---

## Your task

Create a new topic wiki inside an existing workspace.

**Resolution prelude:**
0. **(HORDE fork)** Walk up from `cwd` looking for `.fortissimo-vault.json`. If found → HUB = the directory containing the sentinel; read `topics_root` (default `topics`) and `default_topic` from the sentinel. Skip to "Parse $ARGUMENTS".
1. If no sentinel → read `$HOME/.config/llm-wiki/config.json`. If it has `resolved_path` → HUB = that value; skip to "Parse $ARGUMENTS".
2. If no config → read `$HOME/wiki/_index.md`. If it exists → HUB = `$HOME/wiki`; skip to "Parse $ARGUMENTS".
3. **If still no workspace** → abort with: "No workspace found. Run `/wiki:init` first to bootstrap a workspace, then come back here to create a topic."

For `--local`, skip steps 0-3 and target `<cwd>/.wiki/` directly.

### Parse $ARGUMENTS

- `<name>` (positional, required) — topic slug. Lowercase, hyphens, max 60 chars. There is no anonymous topic.
- `--commons` — generally-applicable knowledge (frameworks, methodology, standards)
- `--client <client-name>` — engagement-specific knowledge (tagged with the client name)
- `--personal` — your own research / learning / reading
- `--local` — create at `<cwd>/.wiki/` instead of in the workspace (project-local; no isolation flag)

If `<name>` is missing, ask: "What's the topic slug? (lowercase, hyphens, like `cybersecurity-frameworks` or `uline`)"

**Isolation flag** — if none of `--commons|--client|--personal|--local` is provided, prompt:

> Which kind of topic is this?
>
> 1. **commons** — generally-applicable knowledge (frameworks, methodology, standards). Reusable across engagements.
> 2. **client `<name>`** — engagement-specific. Tag it so cross-engagement isolation works when the future hook layer ships.
> 3. **personal** — your own research, reading, learning.
>
> (1 / 2 / 3, or `client <name>` for option 2)

Exactly one must be chosen.

### Steps

1. Compute the topic path: `<HUB>/<topics_root>/<name>/` (or `<cwd>/.wiki/` for `--local`).

2. Check the topic doesn't already exist. If it does, abort with: "Topic already exists at `<path>/`. To inspect, run `/wiki:wiki status --wiki <name>`."

3. Create the topic directory structure:
   - `inbox/`, `inbox/.processed/`
   - `raw/`, `raw/articles/`, `raw/papers/`, `raw/repos/`, `raw/notes/`, `raw/data/`
   - `wiki/`, `wiki/concepts/`, `wiki/topics/`, `wiki/references/`, `wiki/theses/`
   - `output/`
   - For local wikis (`--local`): append `.wiki/` to the project's `.gitignore`.

4. Create `.obsidian/` directory with minimal vault config:
   - `.obsidian/app.json`:
     ```json
     {
       "showFrontmatter": true,
       "alwaysUpdateLinks": true,
       "newLinkFormat": "relative",
       "useMarkdownLinks": false
     }
     ```
   - `.obsidian/appearance.json`:
     ```json
     {
       "accentColor": ""
     }
     ```
   - `.obsidian/graph.json`:
     ```json
     {
       "collapse-filter": false,
       "search": "",
       "showTags": true,
       "showAttachments": false,
       "showOrphans": true,
       "collapse-color-groups": false,
       "collapse-display": false,
       "showArrow": true,
       "textFadeMultiplier": 0,
       "nodeSizeMultiplier": 1,
       "lineSizeMultiplier": 1
     }
     ```

5. Create empty `_index.md` in every directory following the format in `references/wiki-structure.md`. Use today's date. Set all counts to 0.

6. Create per-topic `wiki_log.md` with the initial entry:
   ```
   # Wiki Activity Log

   ## [YYYY-MM-DD] init | Topic <name> initialized (<flag>)
   ```

7. Ask: "What is this topic about?" Use the answer to write `config.md` (title, description, scope, today's date).

8. Register the topic in `<HUB>/wikis.json` (skip for `--local`). Include the isolation flag (`commons: true`, `client: "<name>"`, or `personal: true`) on the entry — see `references/wiki-structure.md` § "Isolation flags". For `--local` wikis, append to the `local_wikis` array (no isolation flag — local wikis are out of scope for the future hook layer).

9. Update `<HUB>/_index.md` topic table to list the new topic with its description and isolation flag.

10. Append to `<HUB>/wiki_log.md` (workspace-level activity log):
    ```
    ## [YYYY-MM-DD] topic | <name> created (<flag>)
    ```

11. If the workspace's `default_topic` is unset (first topic in this workspace), update `<HUB>/.fortissimo-vault.json` to set `default_topic: <name>`.

12. Report what was created and suggest:
    > **Topic `<name>` created** at `<HUB>/<topics_root>/<name>/` (`<flag>`).
    >
    > Next:
    > - `/wiki:ingest <url|file|text>` — add a source (lands in `raw/<type>/`)
    > - `/wiki:research "<topic>" --sources 10 --wiki <name>` — auto-research the web and bootstrap with ~10 sources
    > - `/wiki:compile --wiki <name>` — synthesize ingested sources into wiki articles
    > - `/wiki:query "<question>" --wiki <name>` — ask the wiki questions

    For first-time users, the natural-language router picks the right command for you: `/wiki:wiki "<freeform request>"`.
