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

## Rules
- `global-auto-revert-mode 1` is in `bootstrap.org` — don't duplicate
- `inhibit-startup-screen t` is in `bootstrap.org`
- `use-short-answers t` is in `bootstrap.org`
- No `(provide ...)` or `(require ...)` needed — manifolding-emacs handles this
- No blank line after headings at any level in `.org` files
- **Compile cache:** modules are content-hash cached (`.local/cache/module-cache/`). Unchanged files skip org parsing entirely on boot/reload. `C-u M-x manifolding-emacs-reload` forces full recompile. If you change loader semantics, bump `manifolding-emacs-cache-salt`.
- **Message silence:** a global filter in `early-init.el` suppresses known chatter on `message`/`display-warning`/`lwarn`. Don't fight it — if YOUR new module prints something that vanishes, it matched the noise regexp; pick a different wording or extend `my/message-noise-regexp` deliberately.
- **Load auxiliary `.el` quietly:** `(load f nil 'no-message)` — never bare `load`, or "Loading …done" clutters `*Messages*`.
