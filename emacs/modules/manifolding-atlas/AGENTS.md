# Manifolding Atlas — Notes System Context

> Full module reference (every file, every dir, load order): **`readme.org`** in this directory.

## Quick Facts
- **Notes directory:** `~/test/` (`(my/manifolding-atlas-root-dir)` returns `"/home/aoeu/test/"`)
- **Note files are EXTENSIONLESS** (e.g. `~/test/test`, `~/test/contacts/test`) — there are NO `.org` files in the vault. Org content lives in plain files; headingification and org-mode association come from content, not extension. Any file matcher MUST accept extensionless files (and `.org` for compat), never `.org`-only.
- **Database:** `~/test/admin/manifolding-atlas.db` (root-owned `root:users 664`, excluded from git via `.gitignore`)
- **DB sync:** Uses `fswatch` (external method), auto-sync mode enabled
- **Git remote:** `https://github.com/CogitoGITHUB/test.git`, branch `main` tracking `origin/main`

## Git Guards (plugins/git.org)
- `before-save-hook` — **blocks save** with `user-error` if no `.git` in notes directory
- `find-file-hook` — warns if no git repo when opening a notes file
- `dired-before-delete-hook` — prevents deleting untracked files without confirmation
- `after-save-hook` — auto `git add --all`, `git commit -m "auto: ..."`, async `git push`
- `my/manifolding-atlas-git--tracked-p` — checks `git ls-files --error-unmatch`
- Push errors are reported via `message` (not silently swallowed)

## Schema Validation (plugins/schemas.org)
- **Action:** `manifolding-atlas-db-schema-validation-action` = `'silent` — no warnings or prompts
- **Base schema** applies to ALL notes: requires `state-work`, `state-general`, `state-intelligence`, `state-operational`, `state-validation`, `state-source`; optional `state-dependency`, `state-checklist`
- **Task schema** applies to notes tagged `task`: inherits base + adds `todo`, `priority`
- **Template schemas** apply per-capture-template; validate `TEMPLATE_HASH` for staleness
- **Violations tracked via** `MISSING PROMPTS`, rebuilt on `org-capture-after-finalize-hook`
- All fields validate `"WARNING"` as `missing-required` violation
- `my/manifolding-atlas-schema-migrate-warnings` — deletes all `"WARNING"` property values from vault

## Prompt Registry (properties/00-register.org)
- `my/manifolding-atlas-prompt-registry` — list of prompt spec plists
- **Reset on reload:** `(setq my/manifolding-atlas-prompt-registry nil)` after `defvar` to prevent duplicate accumulation
- Each spec has: `:key`, `:name`, `:label`, `:prompt-fn`, `:contexts` (`'file` / `'heading` / `'task`), `:to-plist`, `:read-current-fn`, `:validate-fn`, `:merge-strategy`
- Fragment keys: `:tags`, `:properties`, `:body`, `:post-apply`, `:after`

## Rules System (plugins/rules.org)
- `:RULE: t` property marks headings as rules
- `:RULE_TOPICS:` space-separated list, first is primary topic
- `:RULE_FILE:` optional override for destination file
- Scope tags (`:universal:`, `:general:`, `:focused:`) and level tags (`:L1:`-`:L10:`)
- Pointer files use `#+transclude: [[id:UUID][Title]]` (not bare `[[id:...]]` links)
- Database table `rules` with columns: `note-id`, `topics`, `primary-topic`, `origin`, `routed-files`
- Key function: `my/manifolding-atlas-rules--write-pointer` appends transclude directive to topic file
- Binding: `SPC v` → Manifolding Atlas hydra → `k` = mark as rule, `K` = rule file, `R` = find rules
- `my/manifolding-atlas-find-rules` — browse only rule notes via manifolding-atlas-find

## Property Updates (plugins/properties-update.org)
- **Transient menu** bound to `SPC P` — `my/manifolding-atlas-update-properties`
- 14 toggle definitions covering tags, aliases, priority, scheduling, TODO, all state prompts
- `my/manifolding-atlas--meta-get-fallback` — advice bridging description lists with property drawer
- `my/manifolding-atlas--fix-violations` — sequential field prompt for missing/WARNING-valued fields
- `my/manifolding-atlas--apply-fragment` — handles `:todo`, `:tags`, `:properties`, `:body`, `:post-apply`

## Transclusion (plugins/transclusion.org)
- `my/manifolding-atlas-transclusion-add` — select note, insert `#+transclude: [[id:UUID][Title]] :level N`
- Auto-enables `org-transclusion-mode` in org buffers
- After save: removes and re-adds all transclusions in all org buffers
- Database table `transclude_links` with `source`, `dest` columns (foreign keys to `notes`, `ON DELETE CASCADE`)

## Root Dir (manifolding-atlas-functions/root-dir.org)
- `my/manifolding-atlas-root-dir` — centralized directory prompt, `(&optional root prompt)`
  - root defaults to `(my/manifolding-atlas-root-dir)`, prompt defaults to `"Subdirectory: "`
  - Type `.` or press Enter for root level
  - Select or type a subdirectory name to nest
  - Returns relative path from root (with trailing slash) or `""` for root itself

## Recipes (plugins/recipes.org)
- Manual recipe notes (NO URL fetch / NO source) — you author ingredients + directions by hand
- Default subdir `recipes/` (unlike the normal `my/manifolding-atlas-choose-subdir` which is root-based)
- Note tagged `recipe`; body template `templates/full-file-templates/recipes.org` carries recipe-specific properties: `SERVINGS`, `PREP_TIME`, `COOK_TIME`, `READY_IN`
- `my/manifolding-atlas-recipe-create` — prompt title, slug, recipe properties + body
- `my/manifolding-atlas-recipes-edit-servings` — rescale ingredient quantities to new servings
- Schema: `recipe` schema on tag `recipe` validates the recipe-specific properties
- Binding: `SPC v` → Manifolding Atlas hydra → `R` group (recipe create/edit)

## Fast Mode (0-3)
- `a` = **0 normal** — all prompts fire, body template opens
- `o` = **1 skip general** — specialized prompts (dictionary/rules/note) fire, general (file) prompts skip, body opens
- `e` = **2 skip all** — all prompts return defaults (WARNING), body template still opens
- `u` = **3 quick** — all prompts default to WARNING, **no** body template, just "Open file?" after creation

## Note Creation
- **Heading format:** notes use `* Title` instead of `#+title: Title` — `my/manifolding-atlas--headingify-note-content` advice transforms `manifolding-atlas--format-note-content` output. The heading is created by headingification BEFORE the template body is inserted.
- **Default parameters:** `manifolding-atlas-create-default-function` prompts for subdir, file-level prompts, file name
- **Capture flow:** `manifolding-atlas-create` → `org-capture` for body editing via chosen capture template
- **Templates:** all under `templates/` — `full-file-templates/` (doct), `snippets/`
- **Full templates:** 7 files in `templates/full-file-templates/`: `plain`, `notes`, `reference`, `task`, `math`, `protocol`, `recipes`
- **Template content:** body-only — NO `*` heading or `#+title:` metadata (heading is already created by headingification). Templates use `**` sub-headings and `%?` cursor placeholder.
- **Template preview:** when selecting a template, the preview pane shows the rendered output in `org-mode` (outline expanded, `org-indent-mode` on) with `%?` replaced by the note's title — you see exactly what will land in the file
- **All state prompts required** at create time (skipping sets `"WARNING"` → tracked via MISSING PROMPTS)
- **Dictionary prompts always store `"WARNING"`** as property value when skipped (accepted default or fast mode), never nil

## Live Properties (plugins/live-properties.org)

Concept-based property values are Org links to ref notes, not raw strings.

| Ref type | Behavior | Properties |
|---|---|---|
| `'closed` | Shared canonical note at `admin/refs/<type>/<slug>.org`, deduped | STATE_*, POS, ETYMOLOGY, REGISTER, FREQUENCY, SCOPE, LEVEL, MIND_MAP_PLACEMENT |
| `'scoped` | Per-entity note, no dedup, created via `:post-apply` | PRONUNCIATION, SYNONYMS, EXAMPLES, ALIASES |
| `nil` | Plain string, no link | ADDED, SCHEDULED, DEADLINE, FILE_NAME, TODO, PRIORITY, TAGS (heading-line) |

Key functions: `my/manifolding-atlas--ensure-ref-note` (closed), `my/manifolding-atlas--create-scoped-note` (scoped), `my/manifolding-atlas--canonicalize` (slug). WARNING stays plain string. Tags/TODO/PRIORITY stay Org-native.

Live refs also get a `#+transclude: [[id:REFID][VALUE]]` directive inserted right under their owning note's heading (via `my/manifolding-atlas--add-live-transcludes`, advised on `manifolding-atlas-create`), so ref-note content shows inline through org-transclusion. `my/manifolding-atlas--ref-link-value` matches `[[id:ID][LABEL]]` only; plain values are skipped.

## Key Bindings (from keyboard.org)
- `SPC v` — opens Manifolding Atlas hydra with all manifolding-atlas commands
- In Manifolding Atlas hydra: `k` mark rule, `K` rule file, `R` find rules
- In Manifolding Atlas hydra: `v` find note, `V` insert link, `r` rename link
- In Manifolding Atlas hydra: `h` capture heading, `c` insert at point, `H` heading→note
- In Manifolding Atlas hydra: `f` fix warnings, `P` update props, `u` manifolding-atlas ui
- In Manifolding Atlas hydra: `y` transclude
- `SPC P` — update properties (transient menu, also in hydra)
- `I` in org state — `manifolding-atlas-insert`

## Bootstrap Order
1. `early-init.el` — visual setup, Guix load paths (from `bootstrap.org`)
2. `init.el` — straight.el → org → leaf → manifolding-emacs-boot (from `bootstrap.org`)
3. `modules/*.org` processed by manifolding-emacs, sorted by `#+priority:`

## Notes
- `MISSING PROMPTS` is auto-generated, lives in `~/test/admin/`
- `broken-links` and `deleted-files` are admin files generated by the links plugin, in `~/test/admin/`
- Don't edit `manifolding-atlas.db` directly — it's managed by manifolding-atlas's SQLite layer
- `manifolding-atlas-db-sync-verbose` is `nil` — sync is silent
