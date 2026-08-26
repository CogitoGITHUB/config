# Modules — Structure & Conventions

## File Format

Each module is an `.org` file with a `* Heading` containing a `PROPERTIES` drawer:

```org
* Package Name — Description
:PROPERTIES:
:PACKAGE:  package-name
:STRAIGHT: (package-name :type git :host github :repo "user/repo")
:CATEGORY: category
:END:

** Config
#+begin_src emacs-lisp
(setq package-name-option 'value)
(package-name-mode 1)
#+end_src
```

- `:PACKAGE:` — the package symbol for `leaf`
- `:STRAIGHT:` — straight.el recipe (omit for built-in packages, just use `:CATEGORY:`)
- `:CATEGORY:` — grouping category (e.g. `core`, `editing`, `notes`, `git`, `filetree`)

## Critical: `:STRAIGHT:` must be a SINGLE line

Org PROPERTIES drawers do NOT support multi-line values reliably.
manifolding-emacs only reads the first line of `:STRAIGHT:`.

**WRONG** (multi-line):
```org
:STRAIGHT: (mcp-server :type git :host github :repo "rhblind/emacs-mcp-server"
            :files ("*.el" "tools/*.el"))
```

**RIGHT** (single line):
```org
:STRAIGHT: (mcp-server :type git :host github :repo "rhblind/emacs-mcp-server" :files ("*.el" "tools/*.el"))
```

### `:files` for subdirectory elisp

If a package's `.el` files are in a subdirectory (e.g. `lisp/`), add `:files` to the straight recipe:
```org
:STRAIGHT: (arei :type git :host nil :repo "https://git.sr.ht/~abcdw/emacs-arei" :files ("lisp/*.el"))
```
Without `:files`, straight only picks up `.el` files from the repo root.

## Block tags

Source blocks under a `:PACKAGE:` heading are wrapped into the `leaf` form's keywords based on their Org tag:

| Tag       | Leaf keyword | When to use |
|-----------|-------------|-------------|
| `:init:`  | `:init`     | Variables the package reads at load time (before `require`) |
| `:config:`| `:config`   | Main configuration (after `require`) |
| no tag    | `:config`   | Same as `:config:` — default |

Example:
```org
** Pre-init :init:
#+begin_src emacs-lisp
(setq package-name-some-var t)
#+end_src

** Main config :config:
#+begin_src emacs-lisp
(setq package-name-option "value")
#+end_src
```

`with-eval-after-load` is NOT needed inside `:config:` blocks — leaf's `:config` already runs after `require`. Using it is redundant but harmless.

## Literate Authoring Rules

- **One concern per heading, one heading per block.** A `leaf` form for one package is one heading. An interactive command is one heading. Never merge unrelated setup into one block.
- **Blocks stay under ~15–20 lines.** If a block grows past that, decompose into helper functions each deserving their own heading.
- **Every heading gets substantive prose before code** — why it exists, not what the code obviously does.
- **Granularity = error isolation.** Each heading maps to a unit that can fail independently and be meaningfully reported by the three-tier error system.
- **No mixed concerns in one block.** Package install is its own heading; hooks/keybindings/functions are child headings underneath.
- **When in doubt, over-split.** A 3-line block with one sentence of prose is a correctly-sized unit.
- **Org structure mirrors call structure.** Helpers extracted from a giant defun become child headings (`***`/`****`) *under* the command's heading, ordered before it — readers see the pieces, then the orchestrator. Shared builders used by multiple commands go in their own sibling section.

Full rules: see root `AGENTS.md` → Literate Org-Mode Authoring.

## Paren Discipline (hard-won — read before splitting blocks)

Splitting or editing elisp inside org blocks is where configs die. These rules are mandatory:

- **Close where you open.** Every form's closing paren goes on the line where its last argument ends — NEVER compensated by an extra closer at the function tail. A tail-compensated file "balances" but parses wrong: `(key ...)` silently becomes a second value-form of the previous `let` binding, and only RUNTIME catches it.
- **`let`/`let*` binding pairs close immediately after their value.** `(ans (read-multiple-choice ...))` — the pair's closer comes right after the rmc form, before the next binding starts. Count: bindings-list open → N pairs → bindings-list close → body → let closer → defun closer.
- **Multi-line docstrings are strings spanning lines.** Any paren-aware tooling (or your brain) must track string-state ACROSS newlines. Comments end at EOL; strings do not.
- **When extracting a defun from a bigger block, recount THAT defun's closers in isolation** — don't trust the surrounding balance.
- **Never hand-count a hairy form twice with different results and pick the answer you like.** Restructure the form instead (e.g. hoist a nested `let` binding into a separate `setq`) so the counting becomes trivial.

## Verification Workflow (mandatory after editing any module)

```bash
# 1. After EVERY file (not at the end of a batch):
python3 ~/.config/emacs/check-parens.py | grep -E "BAD|CLEAN"
#    Expect CLEAN. BAD output includes per-line depth traces — read them.

# 2. Full listing when needed:
python3 ~/.config/emacs/check-parens.py --big
#    Vendored/engine/doc files (core/, transclusion, search.org,
#    plugin-guide.org, contacts.org) are exempt from BIG via BIG_EXEMPT
#    in the script — keep that list current.

# 3. Final gate — the loader is the only real judge:
emacs --batch --load ~/.config/emacs/init.el --eval '(message "ok")'
#    Then EXERCISE the changed commands in the daemon. Balance ≠ correctness:
#    a tail-compensated block passes the checker and still explodes at runtime.
```

Known scanner truths (check-parens.py): elisp strings span lines (state persists across `\n`); comments reset at EOL; `?x`/`?\\x` char literals are skipped; BIG reports exclude `BIG_EXEMPT`; BAD reports include per-line depth traces — trust the trace over mental arithmetic.

## Rules
- `global-auto-revert-mode 1` is in `bootstrap.org` — don't duplicate
- `inhibit-startup-screen t` is in `bootstrap.org`
- `use-short-answers t` is in `bootstrap.org`
- No `(provide ...)` or `(require ...)` needed — manifolding-emacs handles this
- No blank line after headings at any level in `.org` files
- **Compile cache:** modules are content-hash cached (`.local/cache/module-cache/`). Unchanged files skip org parsing entirely on boot/reload. `C-u M-x manifolding-emacs-reload` forces full recompile. If you change loader semantics, bump `manifolding-emacs-cache-salt`.
- **Message silence:** a global filter in `early-init.el` suppresses known chatter on `message`/`display-warning`/`lwarn`. Don't fight it — if YOUR new module prints something that vanishes, it matched the noise regexp; pick a different wording or extend `my/message-noise-regexp` deliberately.
- **Load auxiliary `.el` quietly:** `(load f nil 'no-message)` — never bare `load`, or "Loading …done" clutters `*Messages*`.
