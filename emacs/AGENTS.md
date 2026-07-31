# Emacs Config — Project Overview

## Architecture
- **Literate config:** `bootstrap.org` tangles to `init.el` + `early-init.el` via `org-babel-tangle`. Never edit the `.el` files directly.
- **Boot system:** `manifolding-emacs-boot` (in `lisp/manifolding-emacs.el`) processes all `.org` files under `modules/`. It extracts source blocks and `:PACKAGE:` / `:STRAIGHT:` / `:CATEGORY:` properties, generates `leaf` forms, and evaluates them.
- **Package method:** `leaf` — declarations use `:PACKAGE:` + `:STRAIGHT:` in org PROPERTIES drawers. `manifolding-emacs` generates `(leaf PACKAGE :straight (...) :require t :init ... :config ...)`.
- **Load order:** `modules/*.org` sorted by `#+priority:` (default 10, lower = earlier).

## Conventions
- **Namespace:** `my/` for user code, `my/vulpea--` for internal plugin functions.
- **No comments in code** — don't add explanatory comments to source blocks.
- **No blank line after headings** at any level in `.org` files.
- **No temp files in `/tmp/`** — use `/tmp/opencode/`.
- **Schema violations are silent** — `vulpea-db-schema-validation-action` is `'silent`. Violations tracked via MISSING PROMPTS, never interactive prompts.
- **Git commit/push:** use `git gg` (alias that adds all, commits, and pushes). Never stage/commit/push manually.

## Key Files
| File | Purpose |
|------|---------|
| `bootstrap.org` | Boot kernel — tangles to `init.el` / `early-init.el` |
| `modules/keyboard.org` | Modal keybinding system (hydras, modaled states) |
| `modules/vulpea/vulpea.org` | Main notes system config (810 lines) |
| `modules/vulpea/plugins/*.org` | Vulpea plugin modules |
| `modules/vulpea/properties/*.org` | Note property prompts (state, tags, etc.) |
| `modules/vulpea/vulpea-templates-system.org` | Template infrastructure: doct, yasnippet loading |
| `modules/vulpea/templates/` | All template files: `full-file-templates/`, `snippets/` |
| `modules/vulpea/templates/full-file-templates/{notes,plain,reference,task,math,protocol}.org` | Capture templates (body-only, no `*` heading — headingification creates it) |
| `modules/vulpea/templates/snippets/` | Yasnippet snippet files |
| `modules/arei.org` | Guile Scheme IDE (AREI) — requires `guile-ares-rs` installed system-wide |
| `modules/auctex.org` | LaTeX environment (xelatex, texlive env vars, 3-pass PDF export) |
| `modules/org-download.org` | Drag-drop files/images into org notes |
| `modules/org-web-tools.org` | Capture web pages as org entries |
| `modules/org-remark.org` | Annotate/highlight external content stored as vulpea notes |
| `modules/org-fragtog.org` | Auto-toggle LaTeX preview fragments |
| `modules/org-pdftools.org` | PDF integration for org |

## Quick Reference
- **Notes directory:** `~/test/` (`(my/notes-directory)` → `"/home/aoeu/test/"`)
- **Notes must be in a git repo** — `before-save-hook` blocks with `user-error` if no `.git`
- **vulpea.db:** at `~/test/vulpea.db`, root-owned (`root:users 664`), excluded from git

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
| `eval-elisp` | Evaluate any Elisp in the live daemon — can access buffers, org-roam/vulpea, any loaded library |
| `get-diagnostics` | Returns diagnostics (flymake, etc.) from all open buffers |
| `org-agenda` | Query or manipulate the Org agenda |
| `org-search` | Search across Org files |
| `org-get-node` | Retrieve an Org node by ID or path |
| `org-capture` | Capture new notes into Org |
| `org-update-node` | Modify an existing Org node |
| `org-refile` | Refile a node to another heading |
| `org-archive` | Archive a node |
| `org-clock` | Clock in/out of Org tasks |

**emacsclient** can also be used directly: `emacsclient --eval '(elisp-expr)'` — preferred for quick one-off expressions. Use the MCP tools above for structured operations.

**Vulpea** (v2.5.0) is loaded and accessible via `eval-elisp`. Useful for querying org-roam notes programmatically (e.g., `(vulpea-db-query ...)`).

**AREI** (Guile Scheme IDE) loaded — `arei-port` 63225, `scheme-mode-hook` → `arei-mode`, `arei-mode-hook` → `sesman-start`. Requires `guile-ares-rs` running as RPC server.

**emacsclient socket:** always use explicit path → `emacsclient --socket-name /run/user/1000/emacs/server --eval '...'`

Daemon socket: `/run/user/1000/emacs/server`
MCP socket: `~/.config/emacs/.local/cache/emacs-mcp-server.sock`

## Reloading config (no daemon restart)

`manifolding-emacs-boot` recompiles and reloads all modules. Run via emacsclient:
```bash
emacsclient --socket-name /run/user/1000/emacs/server --eval '(manifolding-emacs-boot)'
```

If running from opencode MCP, use `eval-elisp` tool instead. Note: this can take time if `straight` needs to install new packages.

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
