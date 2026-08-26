# Manifolding-Emacs — agent context

This directory boots the entire config.  Three files matter:

| File | Role |
|------|------|
| `Manifolding-Emacs-Foundation.org` | SINGLE SOURCE OF TRUTH for early-init.el + foundation-init.el. `#+auto_tangle: t` → save regenerates both. Startup re-tangles via static seed init.el. |
| `manifolding-emacs.org` | The package manager itself (literate loader). Evaluated block-by-block, lexically, by `my/load-literate-loader` in foundation-init.el. No .el artifacts — this file is the only source. |
| `modules/` | Every feature of the config, compiled per-file at boot. See modules/README.org + modules/AGENTS.md. |

## Loading order

1. Emacs loads `early-init.el` (generated from Foundation's * Early Init section)
2. Emacs loads `init.el` (STATIC SEED — ~40 lines of machinery, never regenerated)
3. Seed tangles Foundation → `early-init.el` + `foundation-init.el`
4. Seed loads `foundation-init.el`
5. foundation-init.el: straight → org → leaf → literate loader → boot
6. Loader compiles every module in `modules/`

## Rules

- **Foundation.org**: all pre-boot configuration lives here.  Do NOT
  add a `:PACKAGE:`/`:STRAIGHT:` drawer (it is not a module).
- **loader.org**: blocks ≤20 lines, one concern each.  A broken block
  fails the boot LOUDLY with the section name in the message.
- **Never** put a speed-menu / read-multiple-choice prompt back into
  capture flows.  The property grid IS the speed setting.
- **Do not edit**: `lisp/manifolding-emacs/*.el` (retired), generated
  `early-init.el`/`foundation-init.el`, or `lisp/init.el` seed.
- **org-capture body buffers stay in modaled "insert" state** (see
  infrastructure.org hook) — only Atlas-Pick picker buffers use the
  "atlas-pick" modaled state.

## Known gotchas

- Transient launched from plain Lisp exits silently → always launch
  from inside a recursive-edit or command-loop iteration.
- Childless display-only transient groups get pruned.
- modaled states: keyboard.org defines them; atlas-pick state owns
  Atlas-Pick buffers; ordinary org-capture bodies stay in "insert".
