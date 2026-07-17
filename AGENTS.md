# Config — Agent Reference

When the user asks to add, modify, or reconfigure something:

## Emacs modules

**Reference:** `~/.emacs.d/modules/AGENTS.md`
**Location:** `~/.emacs.d/modules/<name>.org`
**Daemon control:** `herd restart emacs-daemon`
**Test:** `emacs --batch --load ~/.emacs.d/init.el --eval '(message "ok")'`

Each module is an `.org` file. `:STRAIGHT:` must be a single line.
Use `:init:` tag for pre-require vars, `:config:` tag (or no tag) for main config.

## ManifoldOS system packages

**Reference:** `~/.config/ManifoldOS/Manifold/Agents.org`
**Config:** `~/.config/ManifoldOS/system.scm`
**Substrate:** `~/.config/ManifoldOS/Manifold/substrate/`
**Packages dir:** `substrate/user-space/root/<category>/`
**Loaders dir:** `substrate/user-space/root/loaders/<category>.scm`
**Reconfigure:** `guix system reconfigure ~/.config/ManifoldOS/system.scm`

### Adding a package (chain pattern)

Packages follow a chain: leaf → category → loader → root.

Example — adding `guile-ares-rs`:
1. Leaf: `substrate/user-space/root/programming-languages/lisp/guile.scm` — import from upstream with `#:re-export` not `#:export`
2. Category: `substrate/user-space/root/programming-languages/lisp.scm` — `#:re-export (guile-ares-rs)`
3. Loader: `substrate/user-space/root/loaders/programming-languages.scm` — add to `root-programming-languages-packages`

**Key rule:** `#:re-export` for re-exporting upstream symbols, `define-public` for local definitions, never use bare `#:export` without a matching `define-public`.

### Git SSL certs in Guix System

Git's `process-environment` often lacks CA cert paths when spawned from daemons. Fix: add to Emacs config or before git ops:
```bash
GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt git clone ...
```
In Emacs: `(push "GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt" process-environment)`

The CA bundle: `~` → `/etc/ssl/certs/ca-certificates.crt` → `/gnu/store/...-ca-certificate-bundle/etc/ssl/certs/ca-certificates.crt`

## Emacs MCP (via emacs-mcp-server)

Connection: `emacs-mcp-server` provides tools to interact with the running Emacs daemon (no `emacsclient` needed, though that's also available).

**Available tools:**
- `eval-elisp` — evaluate any Elisp in the running Emacs
- `get-diagnostics` — diagnostics from open buffers
- `org-agenda` — agenda views
- `org-search` — search Org files
- `org-get-node` — get Org node by ID/path
- `org-capture`, `org-update-node`, `org-refile`, `org-archive` — full Org node lifecycle
- `org-clock` — clock in/out

**Vulpea:** available (v2.5.0). Can query org-roam notes via `eval-elisp` with vulpea functions.

**emacsclient fallback:** `emacsclient --eval '(...)` for simple elisp without MCP overhead.

Socket: `~/.emacs.d/.local/cache/emacs-mcp-server.sock`

## Herdr — terminal workspace manager for AI agents

**Config:** `~/.config/herdr/config.toml`
**Socket:** `~/.config/herdr/herdr.sock`
**Plugins:** `herdr plugin install <owner>/<repo>` from GitHub repos tagged `herdr-plugin`
**Agent skill:** `npx skills add ogulcancelik/herdr --skill herdr -g`
**Version:** 0.7.4 (Guix package at `shell/herdr.scm` — binary download, update version + sha256)
**Hash compute:** `guix hash <file>` (NOT `-rx` — that's for git sources)

### Herdr MCP server (islam3zzat/herdr-mcp)

Installed at `~/.local/share/herdr-mcp/` (built from source, `node_modules` symlinked into `dist/`).

**Read tools:**
| Tool | What it does |
|------|-------------|
| `list_agents` | All agents with status (working/blocked/done/idle) and agent_id |
| `get_layout` | Full workspace → tab → pane tree with split geometry |
| `read_pane` | Terminal output of any pane (visible/recent/detection sources) |
| `wait_for_agent_status` | Block until agent reaches a status (event-driven, timeout reported) |
| `wait_for_output` | Block until pane output matches substring/regex |

**Action tools:**
| Tool | What it does |
|------|-------------|
| `send_to_agent` | Type text into a live agent's terminal (submit flag for newline) |
| `send_keys` | Named keys (enter, c-c, escape, etc.) to any pane |
| `start_agent` | Launch a coding agent (claude, codex, opencode, etc.) in a new pane |
| `edit_layout` | split/move/swap/resize/zoom/close panes (refuses to close agent panes) |
| `manage_tabs` | create/rename/focus/close tabs and workspaces (refuses if agents inside) |
| `manage_worktrees` | Git worktree integration (list/create/open/remove) |
| `notify_user` | Desktop notification via herdr's toast system |
| `herdr_rpc` | Raw escape hatch to any socket method (server.stop refused) |

### Herdr socket API (protocol 16)

Unix socket at `~/.config/herdr/herdr.sock`, newline-delimited JSON. Full schema: `herdr api schema --json`.

Key namespaces: `workspace.*`, `tab.*`, `pane.*`, `agent.*`, `layout.*`, `plugin.*`, `events.*`, `worktree.*`, `integration.*`.

### Herdr plugins

Community plugins from GitHub repos tagged `herdr-plugin`. 150+ available.
Manifest: `herdr-plugin.toml` with actions, event hooks, panes, link handlers.
Install: `herdr plugin install <owner>/<repo>`
List: `herdr plugin list`

### Guix packaging for herdr

Herdr is a custom binary download package at `substrate/user-space/root/shell/herdr.scm`.
Build system: `trivial-build-system` — downloads the GitHub release binary and copies to /bin.
Update: bump version, download new binary, compute hash with `guix hash <file>`, reconfigure.

## opencode config

**Config:** `~/.config/opencode/opencode.jsonc`
**Themes:** `~/.config/opencode/themes/`
**TUI:** `~/.config/opencode/tui.json`
**Skills:** `~/.config/opencode/skills/<name>/SKILL.md`
**Restart:** always restart opencode after changes
