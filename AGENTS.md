# Config — Agent Reference

When the user asks to add, modify, or reconfigure something:

## Emacs modules

**Reference:** `~/.config/emacs/modules/AGENTS.md`
**Location:** `~/.config/emacs/modules/<name>.org`
**Daemon control:** `herd restart emacs-daemon`
**Test:** `emacs --batch --load ~/.config/emacs/init.el --eval '(message "ok")'`

Each module is an `.org` file. `:STRAIGHT:` must be a single line.
Use `:init:` tag for pre-require vars, `:config:` tag (or no tag) for main config.

## ManifoldOS system packages

**Reference:** `~/.config/ManifoldOS/Manifold/Agents.org`
**Config:** `~/.config/ManifoldOS/system.scm`
**Substrate:** `~/.config/ManifoldOS/Manifold/substrate/`
**Packages dir:** `substrate/user-space/root/<category>/`
**Loaders dir:** `substrate/user-space/root/loaders/<category>.scm`
**Reconfigure:** `sudo guix system reconfigure ~/.config/ManifoldOS/system.scm --allow-downgrades` (needs `sudo` for `/var/guix/profiles/` write access; `--allow-downgrades` because channel commit may diverge)

**Always run reconfigure in the "reshape system" Herdr tab** — first check `herdr_get_layout` to see if a tab named `reshape system` already exists. If not, create it with `herdr_manage_tabs`. Then `herdr_herdr_rpc` with `pane.send_input` to type the command, then `herdr_send_keys` with `["enter"]` to submit, then read the pane output with `herdr_read_pane` to confirm it started building. Never run inline.

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

# Emacs — daemon lifecycle and interaction

## Directory setup

All Emacs config lives in `~/.config/emacs/`. The daemon auto-detects it
(XDG base directory — Emacs 27+ falls back to `~/.config/emacs/` when
`~/.emacs.d/` doesn't exist). **No symlink needed, no `--init-directory`.**

```bash
# Verify
ls -d ~/.config/emacs/
```
`~/.emacs.d/` should never exist (Emacs won't create it as long as
`~/.config/emacs/` is present).

The daemon is started via `emacs --fg-daemon` (NOT managed by shepherd).
Server socket at `/run/user/1000/emacs/server`. MCP socket at
`~/.config/emacs/.local/cache/emacs-mcp-server.sock` (separate thread,
dies with daemon).

## Daemon lifecycle

### Starting
```bash
# Clean start (kill existing first)
kill -KILL $(pgrep -f "emacs.*fg-daemon" | head -1) 2>/dev/null
sleep 2
rm -f /run/user/1000/emacs/server
rm -f ~/.config/emacs/.local/cache/emacs-mcp-server.sock
nohup emacs --fg-daemon > /tmp/emacs-daemon.log 2>&1 &
```

### Waiting for boot to finish
```bash
# Poll for socket + check no compile messages
for i in $(seq 1 60); do
  if [ -S /run/user/1000/emacs/server ] 2>/dev/null; then
    if ! tail -1 /tmp/emacs-daemon.log 2>/dev/null | grep -q "compiling"; then
      break
    fi
  fi
  sleep 5
done
```

### Health check after start
```bash
# 1. Check for load errors in log
grep -ciE "(error|void|cannot.*load|wrong)" /tmp/emacs-daemon.log

# 2. Verify manifolding-emacs loaded
emacsclient --socket-name /run/user/1000/emacs/server --eval '(featurep '\''manifolding-emacs)'

# 3. Check manifolding-emacs boot errors
emacsclient --socket-name /run/user/1000/emacs/server --eval '(manifolding-emacs-errors-list)'
emacsclient --socket-name /run/user/1000/emacs/server --eval '(manifolding-emacs-warnings-list)'

# 4. Quick sanity
emacsclient --socket-name /run/user/1000/emacs/server --eval '(+ 1 2)'
# Should print 3
```

### Restart after config changes
If you changed `bootstrap.org`, `tangle` it first, then restart:
```bash
emacs --batch --find-file ~/.config/emacs/bootstrap.org --eval '(org-babel-tangle)'
kill -KILL $(pgrep -f "emacs.*fg-daemon" | head -1)
sleep 2; rm -f /run/user/1000/emacs/server
nohup emacs --fg-daemon > /tmp/emacs-daemon.log 2>&1 &
```

### Detecting why restart is needed
- Changed `bootstrap.org` or `init.el` → **must restart** (tanglers/loaders changed)
- Changed `lisp/manifolding-emacs*.el` → **just reload** (`manifolding-emacs-reload`)
- Changed a `modules/*.org` file → **just reload**
- Changed `.el` file in `straight/repos/` → **just reload**
- Changed Guix system packages → **must restart** (Emacs needs to see new binaries)

### What happens during boot
1. `init.el` loads: straight bootstrap → org → leaf → leaf-keywords
2. `manifolding-emacs` loaded from `lisp/manifolding-emacs/`
3. `manifolding-emacs-boot` called: compiles ALL `modules/*.org` files
4. After boot: `global-auto-revert-mode`, recentf saved, daemon sits idle
5. MCP server thread starts (after init.el finishes)
6. Any errors are stored in `manifolding-emacs-errors-list` and `manifolding-emacs-warnings-list`

---

## Interacting with the running daemon

You have **three** ways to talk to the live Emacs daemon.
Use them in this order of preference depending on what you need.

---

## 1. emacsclient (fastest, simplest elisp)

Best for one-liners, state checks, calling custom functions, vulpea queries.
No JSON, no encoding issues, just elisp.

```bash
# Quick eval — result printed to stdout
emacsclient --socket-name /run/user/1000/emacs/server --eval '(+ 1 2)'
=> 3

# Check feature status
emacsclient --socket-name /run/user/1000/emacs/server --eval '(featurep '\''manifolding-emacs-vars)'

# Get a path
emacsclient --socket-name /run/user/1000/emacs/server --eval '(expand-file-name "~/.config/emacs/modules/")'

# Call a custom command
emacsclient --socket-name /run/user/1000/emacs/server --eval '(manifolding-emacs-reload)'
```

**Socket path:** `/run/user/1000/emacs/server` (always use the full `--socket-name`).

### emacsclient patterns

**Non-blocking eval (`-n` flag)** — essential for operations that take time:
```bash
# Submit a reload, don't wait for completion
emacsclient -n --socket-name /run/user/1000/emacs/server --eval '(manifolding-emacs-reload)'

# Submit a long eval, return immediately
emacsclient -n --socket-name $SOCK --eval '(long-running-computation)'
```
**Without `-n`:** emacsclient blocks until eval finishes (timeout risk in tool calls).

**Blocking eval (no `-n`)** — when you need the result:
```bash
# Get a value (blocks until daemon is free)
PID=$(emacsclient --socket-name $SOCK --eval '(emacs-pid)')

# Check feature (blocks)
emacsclient --socket-name $SOCK --eval '(featurep (quote manifolding-emacs))'

# Check errors (blocks)
emacsclient --socket-name $SOCK --eval '(manifolding-emacs-errors-list)'
```

**Detecting daemon busy-ness:**
```bash
# Idle time — if > 5s, daemon is free
emacsclient --socket-name $SOCK --eval '(float-time (current-idle-time))'
# Returns float like 12.34 (seconds since last user input / compilation finished)

# If compiling: idle time is low (< 2s). Wait and retry.
```

**Shell quoting for complex elisp:**
```bash
# Simple: single quotes around elisp, double quotes inside
emacsclient --socket-name $SOCK --eval '(format "hello %s" (user-login-name))'

# Moderate: escape inner single quotes for quoting symbols
emacsclient --socket-name $SOCK --eval '(featurep (quote manifolding-emacs))'
#                                      \_____/\_________________/\_____/
#                                       bash       elisp            bash
#                                       literal    literal           literal

# Complex: use a temp file
cat > /tmp/script.el << 'EOF'
(cl-prettyprint
  (mapcar (lambda (f) (cons f (featurep f)))
          '(manifolding-emacs-vars manifolding-emacs-errors
            manifolding-emacs-compiler manifolding-emacs-doctor)))
EOF
emacsclient --socket-name $SOCK --eval "`cat /tmp/script.el`"
```

**`-n` vs no `-n` decision table:**
| Situation | Use `-n`? | Why |
|-----------|----------|-----|
| `(manifolding-emacs-reload)` | Yes | Takes 10-30s, don't block |
| `(featurep '...)` | No | Instant, need result |
| `(manifolding-emacs-errors-list)` | No | Instant check |
| `(vulpea-db-query ...)` | Depends | Fast if db hot, slow if cold |
| `(+ 1 2)` | No | Instant sanity check |
| When daemon might be compiling | Yes | Avoid timeout waiting for busy main thread |

---

## 2. Emacs MCP server (15 tools over JSON-RPC)

The `emacs-mcp-server` runs as a thread inside the Emacs daemon. It is **always available**
when the daemon is running, listening on a Unix socket. The protocol is JSON-RPC 2.0 with
newline-delimited JSON — use `socat` to talk to it.

**Socket:** `~/.config/emacs/.local/cache/emacs-mcp-server.sock`

### Protocol basics

```bash
# Send a JSON-RPC request
printf '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"TOOL","arguments":{...}}}\n' \
  | socat - UNIX-CONNECT:~/.config/emacs/.local/cache/emacs-mcp-server.sock
```

Every response looks like:
```json
{"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":"<result>"}],"isError":false}}
```

**Critical rules:**
1. Every request MUST end with `\n` (newline) — the MCP server reads line-delimited JSON
2. `id` must be unique per request (doesn't need to increment, just unique)
3. Strings with quotes in `expression` need JSON escaping: `\"` for inner double-quotes
4. **The MCP server blocks when the Emacs main thread is busy.** During `manifolding-emacs-compile-directory`, eval-elisp hangs until compilation finishes. `tools/list` works (separate thread) but `tools/call` for eval-elisp blocks on the main thread.
5. **How to deal with a busy daemon:** Use `emacsclient -n` to submit non-blocking work, or poll with `(current-idle-time)` to detect when it's free.
6. **MCP dies when daemon dies.** No daemon = no MCP socket. Always check connectivity first.
7. All tools return JSON in `result.content[0].text`. For string results, the text IS the result value. For structured results (org-agenda, org-search, etc.), the text is a JSON string you must parse.

### Handling JSON escaping in bash

This is the #1 pain point. For simple expressions, no escaping needed:
```bash
printf '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"eval-elisp","arguments":{"expression":"(+ 1 2)"}}}\n' | socat - UNIX-CONNECT:$SOCK
```

For expressions with inner quotes, use printf with octal escapes or heredocs:
```bash
# Hard way — escape all inner quotes
printf '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"eval-elisp","arguments":{"expression":"(message \"hello from mcp\")"}}}\n' | socat - UNIX-CONNECT:$SOCK

# Better way — use a heredoc to avoid quote confusion
SOCK=~/.config/emacs/.local/cache/emacs-mcp-server.sock
socat - UNIX-CONNECT:$SOCK <<'EOF'
{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"eval-elisp","arguments":{"expression":"(format \"feature %s: %s\" 'manifolding-emacs-vars (featurep 'manifolding-emacs-vars))"}}}
EOF
```

### All 15 tools: complete reference

#### eval-elisp
Execute arbitrary Elisp in the daemon. **Destructive** — can modify daemon state.
```bash
payload() { printf '{"jsonrpc":"2.0","id":%d,"method":"tools/call","params":{"name":"eval-elisp","arguments":{"expression":%s}}}\n' "$1" "$2"; }

# Simple integer
payload 1 '"(+ 1 2)"' | socat - UNIX-CONNECT:$SOCK
# => {"result":{"content":[{"type":"text","text":"3"}],"isError":false}}

# String result
payload 2 '"(buffer-name)"' | socat - UNIX-CONNECT:$SOCK
# => text contains the buffer name

# Complex expression (use heredoc for readability)
socat - UNIX-CONNECT:$SOCK <<'EOF'
{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"eval-elisp","arguments":{"expression":"(cl-prettyprint (mapcar (lambda (f) (cons f (featurep f))) '(manifolding-emacs-vars manifolding-emacs-errors manifolding-emacs-compiler)))"}}}
EOF
```

**Gotchas:**
- Returns only the **printed representation** of the result. If the result is nil, you get `nil`.
- If the expression signals an error, `isError` is true and text contains the error message.
- Long outputs may be truncated by socat's timeout. Increase timeout or use `timeout 10 socat ...`.
- The expression runs in the **scratch buffer** context (not the user's current context).

#### get-diagnostics
Read-only. Returns flycheck/flymake diagnostics from all buffers.
```bash
socat - UNIX-CONNECT:$SOCK <<'EOF'
{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"get-diagnostics","arguments":{}}}
EOF
```
Optional filters:
```bash
# Specific file only
{"method":"tools/call","params":{"name":"get-diagnostics","arguments":{"file_path":"/home/aoeu/.emacs.d/init.el","severity":"error"}}}
```
Severities: `error`, `warning`, `info`.

#### org-agenda
Return agenda views as structured JSON data.
```bash
# Day view
{"method":"tools/call","params":{"name":"org-agenda","arguments":{"view":"day"}}}

# TODO list
{"method":"tools/call","params":{"name":"org-agenda","arguments":{"view":"todo"}}}

# Tags search
{"method":"tools/call","params":{"name":"org-agenda","arguments":{"view":"tags","match":"+work-home/!TODO"}}}
```

**Gotcha:** When `mcp-server-emacs-tools-org-auto-id` is t (default), matched headings
that lack an ID are assigned one as a side effect.

#### org-search
Search headings using org match syntax. Returns summaries (no bodies).
```bash
{"method":"tools/call","params":{"name":"org-search","arguments":{"match":"+work-home/!TODO","limit":10}}}
```

#### org-get-node
Fetch full heading content by ID or by file+outline_path.
```bash
# By ID (preferred)
{"method":"tools/call","params":{"name":"org-get-node","arguments":{"id":"abc123-def456"}}}

# By file + outline path
{"method":"tools/call","params":{"name":"org-get-node","arguments":{"file":"/home/aoeu/.emacs.d/modules/projectile.org","outline_path":["PROJECTILE — Project Interaction Library"]}}}

# File only (returns pre-heading content)
{"method":"tools/call","params":{"name":"org-get-node","arguments":{"file":"/home/aoeu/.emacs.d/modules/projectile.org"}}}
```

#### org-list-templates
List capture or roam-capture templates with prompts.
```bash
{"method":"tools/call","params":{"name":"org-list-templates","arguments":{"type":"capture"}}}
# or: "roam-capture"
```

#### org-list-tags
List tags with usage counts (sorted descending).
```bash
{"method":"tools/call","params":{"name":"org-list-tags","arguments":{"scope":"agenda"}}}
```

#### org-capture
Create a new org entry. Prefer `template_key` from org-list-templates.
```bash
{"method":"tools/call","params":{"name":"org-capture","arguments":{"template_key":"t","template_variables":{"Title":"Buy milk"},"tags":["shopping"]}}}
```
Direct mode (no template):
```bash
{"method":"tools/call","params":{"name":"org-capture","arguments":{"file":"/home/aoeu/test/new.org","title":"New Note","body":"Content here"}}}
```

#### org-update-node
Modify an existing heading. Identify by `id` or `file`+`outline_path`.
```bash
{"method":"tools/call","params":{"name":"org-update-node","arguments":{"id":"abc123","title":"New Title","add_tags":["updated"],"remove_properties":["OLD_PROP"]}}}

# Clear scheduled/deadline: pass JSON null
{"method":"tools/call","params":{"name":"org-update-node","arguments":{"id":"abc123","scheduled":null}}}
```

#### org-refile
Move heading under another heading.
```bash
{"method":"tools/call","params":{"name":"org-refile","arguments":{"source":{"id":"abc123"},"target":{"id":"def456"}}}}
```

#### org-archive
Archive heading to its ARCHIVE target.
```bash
{"method":"tools/call","params":{"name":"org-archive","arguments":{"id":"abc123"}}}
# Optional target override: "file::headline" format
```

#### org-clock
Clock operations.
```bash
# Clock in
{"method":"tools/call","params":{"name":"org-clock","arguments":{"action":"in","id":"abc123"}}}
# Clock out / cancel (no id needed, acts on current clock)
{"method":"tools/call","params":{"name":"org-clock","arguments":{"action":"out"}}}
{"method":"tools/call","params":{"name":"org-clock","arguments":{"action":"cancel"}}}
```

#### org-roam-search
Search roam nodes by title, alias, tag, or ref.
```bash
{"method":"tools/call","params":{"name":"org-roam-search","arguments":{"query":"projectile","tags":["project"],"limit":5}}}
```

#### org-roam-get-node
Fetch roam node with backlinks and forward links.
```bash
{"method":"tools/call","params":{"name":"org-roam-get-node","arguments":{"id":"abc123","include_body":true,"include_backlinks":true,"include_forward_links":false,"backlink_limit":20}}}
```

#### org-roam-capture
Create a new roam node. `title` is required.
```bash
# With template
{"method":"tools/call","params":{"name":"org-roam-capture","arguments":{"template_key":"d","title":"New Note"}}}
# Direct mode
{"method":"tools/call","params":{"name":"org-roam-capture","arguments":{"title":"New Note","body":"#+begin_src emacs-lisp\n(+ 1 2)\n#+end_src","tags":["emacs"]}}}
```

### When to use MCP socket vs emacsclient

| Situation | Tool | Reason |
|-----------|------|--------|
| Quick state check (featurep, variable value) | emacsclient | Zero overhead, simple |
| Org capture/refile/clock | MCP socket | Structured JSON params |
| Org search/agenda with complex match | MCP socket | Match syntax as string param |
| Elisp with complex quoting | emacsclient | No JSON escaping needed |
| Vulpea/org-roam queries | emacsclient | Custom functions, complex elisp |
| Diagnostics | MCP socket | Structured file/severity grouping |
| Long-running daemon operation | emacsclient -n | Non-blocking |
| Daemon is busy compiling | emacsclient (will block) or wait | MCP eval also blocks on main thread |

## Daemon-based testing strategy

### 1. Batch test (no daemon needed) — for compile-only checks
```bash
# Fast: test if init.el loads without errors
emacs --batch --load ~/.config/emacs/init.el --eval '(message "ok")' 2>&1

# Faster: test just manifolding-emacs parsing
emacs --batch \
  --eval '(add-to-list (quote load-path) (expand-file-name "~/.config/emacs/lisp/manifolding-emacs/"))' \
  --eval '(require (quote manifolding-emacs))' \
  --eval '(manifolding-emacs-concatenate-source-blocks (expand-file-name "~/.config/emacs/modules/projectile.org"))' \
  --eval '(message "ok")' 2>&1

# Fastest: test a specific elisp function
emacs --batch --eval '(message "%s" (+ 1 2))' 2>&1
```

**Use batch for:** Config syntax checks, manifolding-emacs parsing tests,
straight recipe validation, leaf form generation. Anything that doesn't need
a terminal or running state.

**Batch vs daemon comparison:** Batch starts fresh every time (no stale state)
but can't test runtime behavior (keybindings, modes, terminal interaction).

### 2. Daemon state check — for runtime verification
```bash
# Check feature loaded
emacsclient --socket-name $SOCK --eval '(featurep (quote projectile))'

# Check mode active
emacsclient --socket-name $SOCK --eval '(and (boundp (quote projectile-mode)) projectile-mode)'

# Check variable value
emacsclient --socket-name $SOCK --eval 'projectile-completion-system'
```

### 3. Full terminal test (ht) — for TUI/keystroke verification
```bash
SID=$(ht run --size 120x40 --name tui-test emacs -Q -nw --load /tmp/test.el | jq -r '.id')
ht send --wait-text "done" --timeout 10s --view --format plain "$SID" "<C-x><C-e>(message \"done\")<Enter>"
ht kill "$SID" && ht remove "$SID"
```

### Decision flow
```
Need to test something?
├─ Is it a compile/syntax check?
│   └─ Use `emacs --batch --load init.el --eval ...`
├─ Is it a runtime state check?
│   └─ Use `emacsclient --eval ...`
├─ Is it a keystroke/TUI/terminal interaction?
│   └─ Use `ht send --wait-text --view ...`
└─ Is it a full boot test (config changed)?
    └─ Restart daemon + check log + emacsclient health check
```

---

## 3. Headless terminal (`ht`) — full TUI testing

**Binary:** `/gnu/store/70c4sw4q852f41psxzcmcjr46p833jki-headless-terminal-0.3.0/bin/ht`
(also accessible as `ht` if PATH is set up)

Use `ht` when you need to test the **full terminal pipeline**: PTY → Emacs → output.
emacsclient/MCP can't test keystroke routing, `input-decode-map`, terminal escape sequences,
or TUI behavior. `ht` runs a real PTY session.

**Architecture:** `ht` starts a daemon (auto-managed), runs commands in PTY sessions,
and lets you send keystrokes / wait for conditions / view output programmatically.

### Session lifecycle

```bash
# 1. Start a session (returns JSON with session ID)
ht run --size 120x40 --name mytest emacs -nw
# => {"id":"a1b2c3d4","name":"mytest",...}

# 2. Work with the session using its ID
ht send a1b2c3d4 "<C-x><C-c>"

# 3. Stop and clean up
ht stop a1b2c3d4
ht remove a1b2c3d4
```

### Full command reference

#### `ht run` — start a session
```text
ht run [--size WxH] [--cwd DIR] [--env K=V] [--name N] [--json] <cmd> [args...]
```
- `--size 120x40` — terminal size (default 80x24). **CRITICAL for Emacs** — use `--size 120x40` so Emacs doesn't wrap
- `--cwd DIR` — working directory
- `--env K=V` — set environment variable (can repeat)
- `--name N` — human-readable name
- `--json` — output session info as JSON (useful for scripting)

#### `ht send` — send keystrokes (THE main command)
```text
ht send [--wait-idle DUR] [--wait-text PAT [--regex]] [--wait-cursor R,C]
        [--wait-exit] [--timeout 5s] [--view] [--raw]
        [--format plain|ansi|html] [--json] <sid> <keys...>
```

**Wait conditions:**
- `--wait-idle 500ms` — wait until terminal is idle for given duration
- `--wait-text "pattern"` — wait for the exact text to appear on screen
- `--wait-text --regex "pat*tern"` — wait for regex match
- `--wait-cursor 10,5` — wait for cursor at row 10, column 5
- `--wait-exit` — wait for the process to terminate
- You can combine multiple wait conditions (all must be met)

**Output options:**
- `--view` — take a screen snapshot after all waits pass. **Essential** for seeing results.
- `--format plain` — strip ANSI escape codes (best for grep/parse)
- `--format ansi` — preserve ANSI (default)
- `--format html` — render as HTML

**Timing:**
- `--timeout 30s` — fail if waits don't pass within this time (default 5s)
- Without `--wait-*`, send returns immediately after keystrokes are queued

**Key notation (vim-style, case-insensitive):**

| Notation | Meaning |
|----------|---------|
| `<Esc>` | Escape key |
| `<CR>` | Carriage Return (same as Enter) |
| `<Enter>` | Enter/Return |
| `<Tab>` | Tab |
| `<Space>` | Space |
| `<BS>` | Backspace |
| `<Del>` | Delete |
| `<Ins>` | Insert |
| `<Up>` `<Down>` `<Left>` `<Right>` | Arrow keys |
| `<Home>` `<End>` | Home/End |
| `<PageUp>` `<PageDown>` | Page Up/Down |
| `<F1>` – `<F12>` | Function keys |
| `<C-x>` | Ctrl + x (lowercase) |
| `<M-x>` | Meta/Alt + x |
| `<S-Tab>` | Shift + Tab |
| `<C-M-x>` | Ctrl + Meta + x |
| `<C-S-x>` | Ctrl + Shift + x |
| `hello` | Literal text "hello" |
| `<C-s>hello<Enter>` | Ctrl+s (isearch forward), "hello", Enter |

**Critical notation rules:**
- `<Esc>` NOT `Escape` or `escape`
- `<C-x>` lowercase x only (Emacs convention)
- Modifier order is always `<C-M-S-x>` regardless of actual keyboard
- Multiple keys are concatenated: `"<C-s>hello<Enter>"`

**`--raw` mode:**
Pass raw bytes instead of key notation. Useful for testing terminal escape sequences:
```bash
ht send --raw a1b2 "\e[3~"  # Send delete character escape sequence
ht send --raw a1b2 $'hello\nworld\n'  # Send literal text with newlines
```

#### `ht view` — snapshot current screen
```text
ht view <sid>
```
Returns the current terminal content. Use after `ht send --view` or to check state.

#### `ht wait` — block until condition met
```text
ht wait <sid> <conditions...>
```
Conditions: `exit`, `idle`, `text PAT`, `regex PAT`, `cursor R,C`
```bash
ht wait a1b2 exit                 # Wait for process termination
ht wait a1b2 idle 2s              # Wait for 2 seconds of terminal silence
ht wait a1b2 text "Loading..."    # Wait for text to appear
ht wait a1b2 regex "Error.*line"  # Wait for regex match
ht wait a1b2 cursor 5,10          # Wait for cursor at specific position
```

#### `ht watch` — live stream output
```text
ht watch <sid>
```
Ctrl-C to exit.

#### `ht list` — list all sessions
```text
ht list [--json]
```
Returns JSON array of session objects with id, name, pid, state, cols, rows, cmd, exit_code.

#### `ht stop` / `ht kill` — end a session
```text
ht stop <sid>    # SIGTERM (graceful shutdown)
ht kill <sid>    # SIGKILL (immediate)
```

#### `ht remove` — remove exited session
```text
ht remove <sid>
```
Reclaims the session ID. Only works for sessions with state `exited`.

#### `ht daemon` — manage the daemon
```text
ht daemon [stop]
```
Normally auto-started. Only needed to stop the daemon manually.

#### `ht debug` — foreground diagnostic mode
```text
ht debug <cmd...>
```
Runs a command with VT diagnostics in the foreground. No daemon, no session.
Prints final snapshot on exit. Useful for testing terminal behavior.

### Efficient test workflows

#### Fast isolated test (minimal Emacs)
```bash
SID=$(ht run --size 120x40 --name fasttest \
  emacs -Q -nw --load /tmp/test.el | jq -r '.id')

# Send keys, wait for result, view output
ht send --wait-text "done" --timeout 10s --view --format plain "$SID" "<C-x><C-e>(message \"done\")<Enter>"

ht kill "$SID" && ht remove "$SID"
```

#### Full config test (slow, compiles everything)
```bash
SID=$(ht run --size 120x40 --name fulltest \
  emacs -nw --debug-init 2>/tmp/emacs-ht.log | jq -r '.id')

# Wait for boot to finish (scroll past init output)
ht wait "$SID" idle 10s --timeout 180s

# Test a keybinding
ht send --wait-idle 500ms --view --format plain "$SID" "<C-h>t"

ht kill "$SID" && ht remove "$SID"
```

#### Scripting pattern with timeout safety
```bash
ht_safe_send() {
  local sid=$1 cmd=$2 desc=$3
  echo "--- $desc ---"
  ht send --wait-idle 500ms --timeout 30s --view --format plain "$sid" "$cmd" 2>&1 || echo "(TIMEOUT/ERROR)"
}
ht_safe_send "$SID" "<Esc>:!echo hello<Enter>" "shell command test"
```

### Known issues

1. **Emacs with full init is SLOW** — straight compilation, org-babel tangling, manifolding-emacs boot all take time. Always use generous `--timeout` (60-180s) and `--wait-idle`.
2. **--wait-idle vs --wait-text** — `--wait-idle` is safer for Emacs since there's less output to match, but `--wait-text "pattern"` is more precise. Use `--wait-text` when you know exactly what to expect.
3. **Session cleanup** — always `ht kill` + `ht remove` after test. Orphan sessions accumulate.
4. **Output truncation** — `ht view` may truncate very long output. Use `--view` in send for targeted snapshots.
5. **No display support** — Emacs in `-nw` only. GUI tests are impossible.
6. **Modifier keys** — Some complex modifier combinations may not work. Test with simple keys first.

---

## 4. Herdr — terminal workspace manager

**Config:** `~/.config/herdr/config.toml`
**Socket:** `~/.config/herdr/herdr.sock`
**Plugins:** `herdr plugin install <owner>/<repo>` from GitHub repos tagged `herdr-plugin`
**Agent skill:** `npx skills add ogulcancelik/herdr --skill herdr -g`
**Version:** 0.7.4 (Guix package at `shell/herdr.scm` — binary download, update version + sha256)
**Hash compute:** `guix hash <file>` (NOT `-rx` — that's for git sources)

### Herdr MCP server (islam3zzat/herdr-mcp)

Installed at `~/.local/share/herdr-mcp/` (built from source, `node_modules` symlinked into `dist/`).

The `herdr_*` tools are **always available** in opencode's tool list. USE THEM.

### Complete tool reference

#### Reading/observation tools

| Tool | Inputs | What it does |
|------|--------|-------------|
| `herdr_list_agents` | (none) | All agents with status (working/blocked/done/idle) and agent_id |
| `herdr_get_layout` | (none) | Full workspace → tab → pane tree with split geometry, roles, CWD |
| `herdr_read_pane` | `pane_id`, `source` (visible/recent/detection), `lines` | Terminal output of any pane |
| `herdr_wait_for_agent_status` | `agent_id`, `until` (status list), `timeout_seconds` | Block until agent reaches status, event-driven (not polling) |
| `herdr_wait_for_output` | `pane_id`, `match` (text/regex), `timeout_seconds` | Block until pane output matches |

#### Action tools

| Tool | Inputs | What it does |
|------|--------|-------------|
| `herdr_send_to_agent` | `agent_id`, `text`, `submit` (bool) | Type text into a live agent's terminal |
| `herdr_send_keys` | `pane_id`, `keys` (array of named keys) | Send named keys (enter, c-c, escape, up) to any pane |
| `herdr_start_agent` | `name`, `argv`, `cwd` | Launch a coding agent in a new pane split from focused |
| `herdr_edit_layout` | `action`, `pane_id`, `tab_id`, `direction`, `to` | split/move/swap/resize/zoom/close panes |
| `herdr_manage_tabs` | `kind` (tab/workspace), `action`, `id`, `label` | create/rename/focus/close tabs and workspaces |
| `herdr_manage_worktrees` | `action` (list/create/open/remove), `branch`, `path` | Git worktree integration |
| `herdr_notify_user` | `title`, `body` | Desktop notification via herdr's toast system |
| `herdr_herdr_rpc` | `method`, `params` | Raw escape hatch to any socket method |

### Key patterns

#### Reading agent output (diagnosing why an agent is stuck)
```bash
# 1. List agents to find the agent_id
herdr_list_agents
# => agent_id: "w1H:p1", status: "working"

# 2. Read what the agent is seeing
herdr_read_pane pane_id="w1H:p1" source="visible" lines=60
# => full terminal output

# 3. For scrollback (recent history, not just visible area)
herdr_read_pane pane_id="w1H:p1" source="recent" lines=200
```

#### Sending input safely
```bash
# Type text but don't submit (let human review first)
herdr_send_to_agent agent_id="w1H:p1" text="git status" submit=false

# Type and submit (triggers agent response)
herdr_send_to_agent agent_id="w1H:p1" text="explain the git diff" submit=true
```

#### Waiting for agents vs waiting for output
```bash
# Wait for agent to reach a terminal state
herdr_wait_for_agent_status agent_id="w1H:p1" until=["done","blocked","idle"] timeout_seconds=120

# Wait for specific output in any pane (including shells, not just agents)
herdr_wait_for_output pane_id="w1H:p2" match="tests passed" timeout_seconds=60
```

#### Pane layout management
```bash
# Split pane to right
herdr_edit_layout action="split" tab_id="w1H:t1" direction="right"

# Move pane to a new tab
herdr_edit_layout action="move" pane_id="w1H:p2" to="new_tab"

# Swap two panes
herdr_edit_layout action="swap" pane_id="w1H:p1" target_pane_id="w1H:p2"

# Zoom a pane full-tab (toggle)
herdr_edit_layout action="zoom" pane_id="w1H:p1"

# Close a shell pane (DESCTRUCTIVE — kills session)
herdr_edit_layout action="close_pane" pane_id="w1H:p2"
```

**Safety:** Closing agent panes is REFUSED. Close shell panes only. Use `manage_tabs` to
close tabs — also refused if agents are inside.

#### Tab and workspace management
```bash
# Create a new tab in current workspace
herdr_manage_tabs kind="tab" action="create" label="debug"

# Rename a tab
herdr_manage_tabs kind="tab" action="rename" id="w1H:t2" label="testing"

# Focus a specific tab
herdr_manage_tabs kind="tab" action="focus" id="w1H:t2"

# Create a new workspace
herdr_manage_tabs kind="workspace" action="create" label="experiments"

# Close workspace (REFUSED if agents inside)
herdr_manage_tabs kind="workspace" action="close" id="w1H"
```

#### Git worktree isolation
```bash
# List existing worktrees
herdr_manage_worktrees action="list"

# Create a new worktree for a branch
herdr_manage_worktrees action="create" branch="feature-x"

# Open a worktree in a new workspace
herdr_manage_worktrees action="open" branch="feature-x"

# Remove a worktree
herdr_manage_worktrees action="remove" workspace_id="w1H"
```

### Herdr socket API (raw)

Unix socket at `~/.config/herdr/herdr.sock`, newline-delimited JSON. Full schema: `herdr api schema --json`.

Key namespaces: `workspace.*`, `tab.*`, `pane.*`, `agent.*`, `layout.*`, `plugin.*`, `events.*`, `worktree.*`, `integration.*`.

### Herdr plugins

Community plugins from GitHub repos tagged `herdr-plugin`. 150+ available.
Manifest: `herdr-plugin.toml` with actions, event hooks, panes, link handlers.
Install: `herdr plugin install <owner>/<repo>`
List: `herdr plugin list`

### Guix packaging for herdr

Package at `substrate/user-space/root/shell/herdr.scm`.
Build: `trivial-build-system` — download GitHub release binary, copy to /bin.
Update: bump version, download new binary, compute hash with `guix hash <file>`, reconfigure.

---

## opencode config & plugins

**Config:** `~/.config/opencode/opencode.jsonc`
**Themes:** `~/.config/opencode/themes/`
**TUI:** `~/.config/opencode/tui.json`
**Skills:** `~/.config/opencode/skills/<name>/SKILL.md`
**Restart:** always restart opencode after changes

### MCP servers configured

| Server | Type | What it provides |
|--------|------|-----------------|
| `context7` | local (npx) | Library docs lookup (tools: `context7_query-docs`, `context7_resolve-library-id`) |
| `filesystem` | local (npx) | Full filesystem access (tools: `filesystem_*`) |
| `sequential-thinking` | local (npx) | Multi-step reasoning (tool: `sequential-thinking_sequentialthinking`) |
| `github` | local (npx) | GitHub API access |
| `emacs` | local (socat) | Connects to emacs-mcp-server socket — tools NOT currently surfaced but callable via socat |
| `herdr` | local (node) | Terminal workspace manager (tools: `herdr_*`) |

### Plugin system

```bash
opencode plugin install <name>   # Install a plugin
opencode plugin list             # List installed plugins
opencode plugin remove <name>    # Remove a plugin
```

### Herdr MCP tools (always available = `herdr_*` tools)

These tools are always in the tool list — USE THEM:
- `herdr_list_agents` — find agent IDs and statuses
- `herdr_get_layout` — full workspace/tab/pane tree
- `herdr_read_pane` — read terminal output of any pane
- `herdr_send_to_agent` — type text into a live agent
- `herdr_send_keys` — send named keys (c-c, escape, enter)
- `herdr_start_agent` — launch a coding agent in a new pane
- `herdr_wait_for_agent_status` — block until agent reaches a status
- `herdr_wait_for_output` — block until pane output matches
- `herdr_edit_layout` — split/move/swap/resize panes
- `herdr_manage_tabs` — create/rename/focus/close tabs
- `herdr_manage_worktrees` — git worktree integration
- `herdr_notify_user` — desktop notification
- `herdr_herdr_rpc` — raw socket call

### Herdr plugins

Currently none installed. Available: 150+ community plugins from GitHub repos tagged `herdr-plugin`. Install with:
```bash
herdr plugin install <owner>/<repo>
```
