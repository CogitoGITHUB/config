# Properties — Prompt Registry System

All prompts register via `my/manifolding-atlas-register-prompt` into `my/manifolding-atlas-prompt-registry`.

## Registry (00-register.org)

- `my/manifolding-atlas-prompt-registry` — list of prompt spec plists
- `my/manifolding-atlas-register-prompt` — takes `&key :key :name :label :contexts :prompt-fn :to-plist :read-current-fn :validate-fn :merge-strategy`
- Uses `push`, so **last-loaded = first in registry = fires first**
- Reset on reload: `(setq my/manifolding-atlas-prompt-registry nil)` after `defvar`

## Prompt Spec Fields

| Key | Purpose |
|-----|---------|
| `:key` | Unique symbol identifier |
| `:name` | Symbol for help file lookup |
| `:label` | Display name |
| `:contexts` | List of context symbols — prompt only fires when collected with matching context |
| `:prompt-fn` | Function that prompts the user, returns a value |
| `:to-plist` | `(lambda (val context) ...)` — returns fragment plist (`:tags`, `:properties`, `:body`, `:post-apply`, `:after`, `:todo`) |
| `:read-current-fn` | Read existing value from a note |
| `:validate-fn` | Validate the value against schema |
| `:merge-strategy` | How to merge multi-value results |

## Fragment Keys (from `:to-plist`)

| Key | Type | Merging |
|-----|------|---------|
| `:tags` | list of strings | Appended |
| `:properties` | alist `(("KEY" . "val"))` | Appended, empty values removed |
| `:body` | string | Concatenated |
| `:post-apply` | list of functions | Applied in order to created note |
| `:after` | string | Used as `:after` in `manifolding-atlas-create` |
| `:todo` | string | Sets heading TODO state (stored in `my/manifolding-atlas--creation-todo`) |
| `:file-name` | string | Overrides file name |

## Load Order & Priority

- `#+priority:` in each `.org` file (default 10, lower = earlier)
- `sort` is NOT stable — avoid priority ties
- Existing priorities: 00-register=-1, general=1/5/6, dictionary=11-17
- New categories: use priorities 21+ to load after all existing prompts

## Contexts

| Context | When used |
|---------|-----------|
| `'file` | All file-level note creation |
| `'heading` | Heading-level creation |
| `'task` | Task notes (tagged `task`) |
| `'dictionary` | Dictionary word notes |
| `'recipe` | Recipe notes (tagged `recipe`, created via `recipe-create`) |
| `'contacts` | Contact notes numbering|

## Fast Mode Levels

- `my/manifolding-atlas--fast-level` returns 0/1/2
- Level 0: all prompts fire
- Level 1: specialized prompts fire, general (`file`) prompts skip
- Level 2: all prompts skip (defaults returned)
- Use `(my/manifolding-atlas-collect-prompts-with-fast '(specialized) '(file))` for automatic three-way handling
