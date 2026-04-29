---
description: "LLM wiki knowledge base — understands natural language. Say what you want (add a URL, ask a question, research a topic, audit an output, resume work) and it routes to the right subcommand. Also shows status and handles config. For workspace bootstrap use /wiki:init; for topic creation use /wiki:topic."
argument-hint: "[<natural language request>] [config hub-path [<path>]] [--wiki <name>]"
allowed-tools: Read, Write, Edit, Glob, Bash(ls:*), Bash(wc:*), Bash(mkdir:*), Bash(date:*), Bash(mv:*)
---

## Your task

**Resolve the wiki.** Do NOT search the filesystem or read reference files — follow these steps:
0. **(HORDE fork)** Walk up from `cwd` looking for `.fortissimo-vault.json`. Stop at first match (or at `$HOME` / filesystem root with no match). If found → HUB = the directory containing the sentinel; read the sentinel for `topics_root` (default `topics`) and `default_topic`; skip to step 3.
1. If no sentinel, read `$HOME/.config/llm-wiki/config.json`. If it has `resolved_path` → HUB = that value, skip to step 3. If only `hub_path`, expand leading `~` only (not tildes in `com~apple~CloudDocs`), set HUB, write `resolved_path` back, skip to step 3.
2. If no config → read `$HOME/wiki/_index.md`. If it exists → HUB = `$HOME/wiki`. If nothing found, fall through to the "no wiki exists" section below.
3. **Wiki location** (first match): `--local` → `.wiki/` in CWD; `--wiki <name>` → `HUB/wikis.json` lookup; CWD has `.wiki/` → use it; else → HUB.
4. Read `<wiki>/_index.md` if found. Variant: **wiki-neutral** — `wiki.md` is the router, status, and config command. "Wiki missing" is not always an error: status shows an empty hub gracefully, the natural-language router explains how to create one, and bootstrap is delegated to `/wiki:init` (workspace) and `/wiki:topic` (topic).

You are the llm-wiki knowledge base manager. Read the skill at `skills/wiki-manager/SKILL.md` and structure reference at `skills/wiki-manager/references/wiki-structure.md` for full conventions.

---

### If $ARGUMENTS is freeform text (not "config" or empty) and a wiki exists

The user typed something that isn't a known keyword. Detect their intent and route to the right subcommand.

**Check these patterns in order — first match wins:**

| Priority | Intent | Signal patterns | Route to |
|----------|--------|----------------|----------|
| 1 | **Ingest** | Contains a URL (`http://`, `https://`), a file path (`/`, `~/`), or words: "add", "save", "ingest", "read this", "grab this" | `Skill: wiki:ingest` with the URL/path/text |
| 2 | **Resume** | "where was I", "pick up where", "continue", "resume", "get back to", "catch me up", "what was I working on" | `Skill: wiki:query` with `--resume` |
| 3 | **Audit** | "audit", "full audit", "can I trust", "trust this", "verify this output", "verify this report", "fact-check this artifact", "check everything", "provenance", "drift report", "follow the evidence", "find the truth" | `Skill: wiki:audit` |
| 4 | **Query** | Starts with what/why/how/when/where/who, contains "?", or words: "tell me about", "explain", "what do we know about" | `Skill: wiki:query` with the question |
| 5 | **Research** | "research", "find out about", "look into", "deep dive", "investigate" | `Skill: wiki:research` with the topic |
| 6 | **Thesis** | "prove that", "is it true that", "verify", "test the claim", "test the hypothesis" | `Skill: wiki:research` with `--mode thesis "<claim>"` |
| 7 | **Compile** | "compile", "process sources", "synthesize", "update articles" | `Skill: wiki:compile` |
| 8 | **Lint** | "check health", "fix wiki", "broken", "problems", "cleanup" | `Skill: wiki:lint` |
| 8b | **Librarian** | "librarian", "quality scan", "scan quality", "article quality", "content review", "keep the wiki in check", "review articles", "librarian report", "quality report", "stale articles" | `Skill: wiki:librarian` |
| 8c | **Refresh** | "check freshness", "still current", "up to date", "outdated", "refresh" | `Skill: wiki:refresh` |
| 9 | **Output** | "write a summary", "generate a report", "slides", "create a", "write a" | `Skill: wiki:output` with the request |
| 10 | **Assess** | "compare to", "assess", "gap analysis" | `Skill: wiki:assess` |
| 11 | **Plan** | "plan for", "implementation plan", "architecture for" | `Skill: wiki:plan` |
| 11b | **Lessons Learned** | "learn this", "learn that", "lesson learned", "lessons learned", "absorb this", "capture what we learned", "what did we learn", "session takeaways", "ll" | `Skill: wiki:ll` with the topic hint |
| 12 | **Retract** | "remove source", "retract", "delete source", "pull out" | `Skill: wiki:retract` |
| 13 | **Project (new)** | "new project", "start a project", "create project" (+ slug and goal) | `Skill: wiki:project` with `new <slug> "goal"` |
| 14 | **Project (list)** | "list projects", "what projects", "show projects", "my projects" | `Skill: wiki:project` with `list` |
| 15 | **Project (show)** | "show project X", "what's in project X", "open project X" | `Skill: wiki:project` with `show <slug>` |
| 16 | **Project (archive)** | "archive project", "I'm done with project", "close project" | `Skill: wiki:project` with `archive <slug>` |

**Confidence routing:**

- **High confidence** — a single strong signal (URL present, question mark, exact keyword match like "compile" or "resume"). Route directly. Tell the user what you detected:
  > Detected: **ingest** (found URL). Routing to `/wiki:ingest`.
  
  Then invoke the Skill tool with the appropriate command and pass the user's text as arguments.

- **Low confidence** — ambiguous input that could match multiple intents, or no clear signal. Present the top 2-3 matching options as a numbered list:
  > Not sure what you're after. Pick one:
  > 
  > 1. **Query** — ask the wiki what it knows
  > 2. **Research** — search the web and add new sources
  > 3. **Ingest** — add specific material you already have
  > 
  > (1/2/3)
  
  Wait for their choice, then invoke the corresponding Skill.

- **No match** — the text doesn't match any pattern. Show wiki status (fall through to status section below) and list available subcommands.

**Key rules:**
- Never guess when ambiguous. A quick menu is faster than undoing the wrong action.
- Strip the signal words when passing args to the target command (e.g., "add https://example.com" → pass just the URL to ingest, not "add https://example.com").
- Include `--wiki`, `--local`, and `--project` flags from the original args when routing.
- **No ambient project focus**: `--project <slug>` must be passed explicitly by the user. The focus-session mechanism was removed in the v0.2 projects simplification (see `skills/wiki-manager/references/projects.md` § "Focus"). If the user says "work on project X" without a clear sub-intent, treat it as a request to `show` the project — not as a focus state change.

---

### If $ARGUMENTS is empty (or just "status"/"stats"/"show") and a wiki exists

Show wiki status. Before reading any `_index.md`, stale-check it: count `.md` files in the directory vs rows in the index table. If mismatched, rebuild inline from file frontmatter first (see `references/indexing.md` Derived Index Protocol).

1. If at the hub level (HUB):
   - Read `HUB/_index.md` and `HUB/wikis.json`
   - For each registered topic wiki, read its `_index.md` to get current stats
   - Show a summary table: wiki name, description, source count, article count
   - Show global log (last 5 entries)

2. If targeting a specific topic wiki (`--wiki <name>` or local):
   - Read its `_index.md` for statistics and recent changes
   - Read `config.md` for title and description
   - Count actual files for accuracy
   - Show: title, location, source/article/output counts, inbox pending, last compiled/lint dates, last 5 recent changes

3. List available subcommands

---

### If no wiki exists

Resolution prelude found no workspace (no sentinel, no config-pointed hub, no `~/wiki/`). The user hasn't bootstrapped one yet. Show:

> **No wiki workspace found.**
>
> A workspace is a single directory holding all your topic wikis plus shared metadata. Bootstrap one with:
>
> - `/wiki:init` — pick a workspace path, write the sentinel + hub files, walk through the first-run primer
>
> If you already have a workspace somewhere and need to point this session at it, run:
>
> - `/wiki:wiki config hub-path <path>` — set the hub path explicitly (legacy fallback for sessions where the sentinel walk-up doesn't reach the workspace)

Don't dump the full command list at this stage. The user gets oriented during `/wiki:init`.

---

### If $ARGUMENTS contains "config"

Configure the wiki system.

#### `config hub-path <path>`

Set a custom hub location. Creates `~/.config/llm-wiki/config.json`.

**Steps:**

1. If `<path>` is provided:
   - Expand `~` in the path to get the absolute path
   - Check if the path exists as a directory. If not, offer to create it.
   - Write `~/.config/llm-wiki/config.json` (create `~/.config/llm-wiki/` if needed) with BOTH the user-facing path and the pre-computed absolute path:
     ```json
     {
       "hub_path": "<path as the user typed it>",
       "resolved_path": "<absolute path with ~ expanded>"
     }
     ```
     The `resolved_path` is consumed by hub resolution so tilde expansion never runs again. See `references/hub-resolution.md`.
   - Suggest creating a symlink for maximum robustness:
     > For fastest hub resolution, also run: `ln -s "<resolved_path>" ~/wiki`
     > This makes `~/wiki/` always resolve immediately, even without reading config.
   - If a wiki already exists at the OLD hub location (previous config path or `~/wiki/` fallback):
     - Ask: "Move existing wiki data from `<old>` to `<new>`? (y/n)"
     - If yes: move contents (`mv <old>/* <new>/`), update `wikis.json` paths to reflect new base
     - If no: just update the config — user will move data manually
   - Report: "Hub path set to `<path>`. All wiki commands now use this location."

2. If no `<path>` provided (just `config hub-path`):
   - Read `~/.config/llm-wiki/config.json` if it exists
   - Report current hub path (use `resolved_path` if present, otherwise `hub_path`)
   - If `resolved_path` is missing from config, compute it now and write it back
   - Report: "Current hub path: `<path>`" or "No hub configured. Run `config hub-path <path>` to set one."

#### `config` (no subcommand)

Show all configuration:
- **Hub path**: current resolved path (and whether it's from config or default)
- **Config file**: `~/.config/llm-wiki/config.json` (exists / not found)
- **Topic wikis**: count from wikis.json
