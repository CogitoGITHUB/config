# Emacs Config — Project Overview

## Architecture
- **Literate config:** `bootstrap.org` tangles to `init.el` + `early-init.el` via `org-babel-tangle`. Never edit the `.el` files directly.
- **Boot system:** `manifolding-emacs-boot` (in `lisp/manifolding-emacs.el`) processes all `.org` files under `modules/`. It extracts source blocks and `:PACKAGE:` / `:STRAIGHT:` / `:CATEGORY:` properties, generates `leaf` forms, and evaluates them.
- **Package method:** `leaf` — declarations use `:PACKAGE:` + `:STRAIGHT:` in org PROPERTIES drawers. `manifolding-emacs` generates `(leaf PACKAGE :straight (...) :require t :init ... :config ...)`.
- **Load order:** `modules/*.org` sorted by `#+priority:` (default 10, lower = earlier).

## Conventions
- **Namespace:** `my/` for user code, `my/manifolding-atlas--` for internal plugin functions.
- **No comments in code** — don't add explanatory comments to source blocks.
- **No blank line after headings** at any level in `.org` files.
- **No temp files in `/tmp/`** — use `/tmp/opencode/`.
- **Schema violations are silent** — `manifolding-atlas-db-schema-validation-action` is `'silent`. Violations tracked via MISSING PROMPTS, never interactive prompts.
- **Git commit/push:** use `git gg` (alias that adds all, commits, and pushes). Never stage/commit/push manually.

## Key Files
| File | Purpose |
|------|---------|
| `bootstrap.org` | Boot kernel — tangles to `init.el` / `early-init.el` |
| `modules/keyboard.org` | Modal keybinding system (hydras, modaled states) |
| `modules/manifolding-atlas/` | Main notes system (formerly `vulpea`, vendored + loader-managed). Full reference: `modules/manifolding-atlas/readme.org` |
| `modules/manifolding-atlas/manifolding-atlas.org` | Main notes system config (116 lines; engine vendored under `core/`) |
| `modules/manifolding-atlas/plugins/*.org` | Manifolding Atlas plugin modules |
| `modules/manifolding-atlas/properties/*.org` | Note property prompts (state, tags, etc.) |
| `modules/manifolding-atlas/manifolding-atlas-templates-system.org` | Template infrastructure: doct, yasnippet loading |
| `modules/manifolding-atlas/templates/` | All template files: `full-file-templates/`, `snippets/` |
| `modules/manifolding-atlas/templates/full-file-templates/{notes,plain,reference,task,math,protocol}.org` | Capture templates (body-only, no `*` heading — headingification creates it) |
| `modules/manifolding-atlas/templates/snippets/` | Yasnippet snippet files |
| `modules/arei.org` | Guile Scheme IDE (AREI) — requires `guile-ares-rs` installed system-wide |
| `modules/auctex.org` | LaTeX environment (xelatex, texlive env vars, 3-pass PDF export) |
| `modules/org-download.org` | Drag-drop files/images into org notes |
| `modules/org-web-tools.org` | Capture web pages as org entries |
| `modules/org-remark.org` | Annotate/highlight external content stored as manifolding-atlas notes |
| `modules/org-fragtog.org` | Auto-toggle LaTeX preview fragments |
| `modules/org-pdftools.org` | PDF integration for org |

## Quick Reference
- **Notes directory:** `~/test/` (`(my/notes-directory)` → `"/home/aoeu/test/"`)
- **Notes must be in a git repo** — `before-save-hook` blocks with `user-error` if no `.git`
- **manifolding-atlas.db:** at `~/test/admin/manifolding-atlas.db`, root-owned (`root:users 664`), excluded from git

## LaTeX / TeX Live

- **Engines:** `xelatex` (default), `pdflatex`, `latex`, `dvipng` — all in system profile
- **Guix system packages** (ManifoldOS `loaders/tex.scm`): `texlive-latex-bin`, `texlive-amsmath`, `texlive-amsfonts`, `texlive-graphics`, `texlive-hyperref`, `texlive-ulem`, `texlive-capt-of`, `texlive-wrapfig`, `texlive-tools`, `texlive-etoolbox`, `texlive-dvipng`, `texlive-preview`, `texlive-xetex`, `texlive-fontspec`
- **Env vars** set in `auctex.org` config:
  - `GUIX_TEXMF` = `/run/current-system/profile/share/texmf-dist:.../.guix-profile/share/texmf-dist`
  - `TEXINPUTS` = `.:.../.guix-profile/share/texmf-dist/tex//:` (for user-installed packages)
- **Org export:** `org-latex-pdf-process` uses 3-pass `xelatex` (auctex.org)
- **Preview (`C-c C-x C-l`):** requires a GUI Emacs frame (`display-graphic-p`); doesn't work in terminal
- **Modules:** `auctex.org` (xelatex config), `cdlatex.org` (fast math input), `org-fragtog.org` (auto-toggle), `org-pdftools.org` (PDF tools)

## Emacs MCP Server Integration

The emacs-mcp-server runs inside the Emacs daemon and exposes these tools to opencode:

| Tool | What it does |
|------|-------------|
| `eval-elisp` | Evaluate any Elisp in the live daemon — can access buffers, org-roam/manifolding-atlas, any loaded library |
| `get-diagnostics` | Returns diagnostics (flymake, etc.) from all open buffers |
| `org-agenda` | Query or manipulate the Org agenda |
| `org-search` | Search across Org files |
| `org-get-node` | Retrieve an Org node by ID or path |
| `org-capture` | Capture new notes into Org |
| `org-update-node` | Modify an existing Org node |
| `org-refile` | Refile a node to another heading |
| `org-archive` | Archive a node |
| `org-clock` | Clock in/out of Org tasks |

**emacsclient** can also be used directly. ⚠️ Its socket
`/run/user/1000/emacs/server` is frequently a **stale file** → "Connection
refused" even though the file exists. The **MCP socket is the reliable path**
(§below). Try `emacsclient --eval '(+ 1 2)'`; if it gives Connection refused,
use socat→MCP.

**Manifolding Atlas** (v2.5.0) is loaded and accessible via `eval-elisp`. Useful for querying org-roam notes programmatically (e.g., `(manifolding-atlas-db-query ...)`).

**AREI** (Guile Scheme IDE) loaded — `arei-port` 63225, `scheme-mode-hook` → `arei-mode`, `arei-mode-hook` → `sesman-start`. Requires `guile-ares-rs` running as RPC server.

**emacsclient socket:** always use explicit path → `emacsclient --socket-name /run/user/1000/emacs/server --eval '...'`

Daemon socket (emacsclient): `/run/user/1000/emacs/server` — may be stale/refused.

**MCP socket (RELIABLE):** `/home/aoeu/.config/emacs/.local/cache/emacs-mcp-server.sock` — talk to it with socat using the ABSOLUTE path (socat does NOT expand `~`). JSON-RPC 2.0, newline-delimited, `id` unique:
```bash
SOCK=/home/aoeu/.config/emacs/.local/cache/emacs-mcp-server.sock
socat - UNIX-CONNECT:$SOCK <<'EOF'
{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"eval-elisp","arguments":{"expression":"(+ 1 2)"}}}
EOF
```

If opencode doesn't surface the MCP tools (they're callable via `tools/call`),
use socat directly as above.

## Reloading config (no daemon restart)

`manifolding-emacs-boot` recompiles and reloads all modules. Run via the MCP
socket (reliable) — it takes 10-30s so send it and then poll for idle:
```bash
SOCK=/home/aoeu/.config/emacs/.local/cache/emacs-mcp-server.sock
# kick off (non-blocking; wrap in `timeout 30 socat` since it can hang while compiling)
socat - UNIX-CONNECT:$SOCK <<'EOF'
{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"eval-elisp","arguments":{"expression":"(manifolding-emacs-reload)"}}}
EOF
# poll until idle
socat - UNIX-CONNECT:$SOCK <<'EOF'
{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"eval-elisp","arguments":{"expression":"(float-time (current-idle-time))"}}}
EOF
# check errors
socat - UNIX-CONNECT:$SOCK <<'EOF'
{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"eval-elisp","arguments":{"expression":"(manifolding-emacs-errors-list)"}}}
EOF
```
Note: this can take time if `straight` needs to install new packages.

## Git SSL cert fix

Straight.el HTTPS clones fail with "CAfile: none" in the Emacs daemon because the Guix System CA bundle path isn't in Emacs's `process-environment`. Fix each session or add to a module's config:
```emacs-lisp
(when (file-exists-p "/etc/ssl/certs/ca-certificates.crt")
  (push "GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt" process-environment))
```

## Emacs Daemon

The Emacs daemon is managed by shepherd. To restart:

```bash
herd restart emacs-daemon
```

> ⚠️ The actual shepherd service name is NOT `emacs-daemon`
> (`herd restart emacs-daemon` → "service could not be found"). Confirm the
> real name with `herd status | grep emacs` (it's defined in
> `~/.config/ManifoldOS/system.scm`). For `modules/*.org` edits you usually
> don't need a restart at all — use the MCP reload (§Reloading config above).

The daemon socket is at `/run/user/1000/emacs/server`.

To test config changes without restarting the daemon:
```bash
emacs --batch --load ~/.config/emacs/init.el --eval '(message "ok")'
```

This loads the full config (straight, leaf, manifolding-emacs) and reports errors. Useful for catching mistakes before a full restart.

To test a specific package install:
```bash
emacs --batch --load ~/.config/emacs/init.el \
  --eval '(straight-use-package '\''(package-name :type git :host github :repo "user/repo"))'
```

To verify a package loaded:
```bash
emacs --batch --load ~/.config/emacs/init.el \
  --eval '(message "featurep: %s" (featurep '\''package-name))'
```
