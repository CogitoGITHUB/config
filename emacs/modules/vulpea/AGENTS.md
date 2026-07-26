# Vulpea — Notes System Context

## Quick Facts
- **Notes directory:** `~/test/` (`(my/notes-directory)` returns `"/home/aoeu/test/"`)
- **Database:** `~/test/vulpea.db` (root-owned `root:users 664`, excluded from git via `.gitignore`)
- **DB sync:** Uses `fswatch` (external method), auto-sync mode enabled
- **Git remote:** `https://github.com/CogitoGITHUB/test.git`, branch `main` tracking `origin/main`

## Git Guards (plugins/git.org)
- `before-save-hook` — **blocks save** with `user-error` if no `.git` in notes directory
- `find-file-hook` — warns if no git repo when opening a notes file
- `dired-before-delete-hook` — prevents deleting untracked files without confirmation
- `after-save-hook` — auto `git add --all`, `git commit -m "auto: ..."`, async `git push`
- `my/vulpea-git--tracked-p` — checks `git ls-files --error-unmatch`
- Push errors are reported via `message` (not silently swallowed)

## Schema Validation (plugins/schemas.org)
- **Action:** `vulpea-db-schema-validation-action` = `'silent` — no warnings or prompts
- **Base schema** applies to ALL notes: requires `state-work`, `state-general`, `state-intelligence`, `state-operational`, `state-validation`, `state-source`; optional `state-dependency`, `state-checklist`
- **Task schema** applies to notes tagged `task`: inherits base + adds `todo`, `priority`
- **Template schemas** apply per-capture-template; validate `TEMPLATE_HASH` for staleness
- **Violations tracked via** `MISSING PROMPTS.org`, rebuilt on `org-capture-after-finalize-hook`
- All fields validate `"WARNING"` as `missing-required` violation
- `my/vulpea-schema-migrate-warnings` — deletes all `"WARNING"` property values from vault

## Prompt Registry (properties/00-register.org)
- `my/vulpea-prompt-registry` — list of prompt spec plists
- **Reset on reload:** `(setq my/vulpea-prompt-registry nil)` after `defvar` to prevent duplicate accumulation
- Each spec has: `:key`, `:name`, `:label`, `:prompt-fn`, `:contexts` (`'file` / `'heading` / `'task`), `:to-plist`, `:read-current-fn`, `:validate-fn`, `:merge-strategy`
- Fragment keys: `:tags`, `:properties`, `:body`, `:post-apply`, `:after`

## Rules System (plugins/rules.org)
- `:RULE: t` property marks headings as rules
- `:RULE_TOPICS:` space-separated list, first is primary topic
- `:RULE_FILE:` optional override for destination file
- Scope tags (`:universal:`, `:general:`, `:focused:`) and level tags (`:L1:`-`:L10:`)
- Pointer files use `#+transclude: [[id:UUID][Title]]` (not bare `[[id:...]]` links)
- Database table `rules` with columns: `note-id`, `topics`, `primary-topic`, `origin`, `routed-files`
- Key function: `my/vulpea-rules--write-pointer` appends transclude directive to topic file
- Binding: `SPC v` → Vulpea hydra → `k` = mark as rule, `K` = rule file, `R` = find rules
- `my/vulpea-find-rules` — browse only rule notes via vulpea-find

## Property Updates (plugins/properties-update.org)
- **Transient menu** bound to `SPC P` — `my/vulpea-update-properties`
- 14 toggle definitions covering tags, aliases, priority, scheduling, TODO, all state prompts
- `my/vulpea--meta-get-fallback` — advice bridging description lists with property drawer
- `my/vulpea--fix-violations` — sequential field prompt for missing/WARNING-valued fields
- `my/vulpea--apply-fragment` — handles `:todo`, `:tags`, `:properties`, `:body`, `:post-apply`

## Transclusion (plugins/transclusion.org)
- `my/vulpea-transclusion-add` — select note, insert `#+transclude: [[id:UUID][Title]] :level N`
- Auto-enables `org-transclusion-mode` in org buffers
- After save: removes and re-adds all transclusions in all org buffers
- Database table `transclude_links` with `source`, `dest` columns (foreign keys to `notes`, `ON DELETE CASCADE`)

## Root Dir (vulpea-functions/root-dir.org)
- `my/vulpea-root-dir` — centralized directory prompt, `(&optional root prompt)`
  - root defaults to `(my/notes-directory)`, prompt defaults to `"Subdirectory: "`
  - Type `.` or press Enter for root level
  - Select or type a subdirectory name to nest
  - Returns relative path from root (with trailing slash) or `""` for root itself

## Fast Mode (0-3)
- `a` = **0 normal** — all prompts fire, body template opens
- `o` = **1 skip general** — specialized prompts (dictionary/rules/note) fire, general (file) prompts skip, body opens
- `e` = **2 skip all** — all prompts return defaults (WARNING), body template still opens
- `u` = **3 quick** — all prompts default to WARNING, **no** body template, just "Open file?" after creation

## Note Creation
- **Heading format:** notes use `* Title` instead of `#+title: Title` — `my/vulpea--headingify-note-content` advice transforms `vulpea--format-note-content` output. The heading is created by headingification BEFORE the template body is inserted.
- **Default parameters:** `vulpea-create-default-function` prompts for subdir, file-level prompts, file name
- **Capture flow:** `vulpea-create` → `org-capture` for body editing via chosen capture template
- **Templates:** all under `templates/` — `full-file-templates/` (doct), `snippets/`
- **Full templates:** 6 files in `templates/full-file-templates/`: `plain`, `notes`, `reference`, `task`, `math`, `protocol`
- **Template content:** body-only — NO `*` heading or `#+title:` metadata (heading is already created by headingification). Templates use `**` sub-headings and `%?` cursor placeholder.
- **Template preview:** when selecting a template, the preview pane shows the rendered output in `org-mode` (outline expanded, `org-indent-mode` on) with `%?` replaced by the note's title — you see exactly what will land in the file
- **All state prompts required** at create time (skipping sets `"WARNING"` → tracked via MISSING PROMPTS.org)
- **Dictionary prompts always store `"WARNING"`** as property value when skipped (accepted default or fast mode), never nil

## Key Bindings (from keyboard.org)
- `SPC v` — opens Vulpea hydra with all vulpea commands
- In Vulpea hydra: `k` mark rule, `K` rule file, `R` find rules
- In Vulpea hydra: `v` find note, `V` insert link, `r` rename link
- In Vulpea hydra: `h` capture heading, `c` insert at point, `H` heading→note
- In Vulpea hydra: `f` fix warnings, `P` update props, `u` vulpea ui
- In Vulpea hydra: `y` transclude
- `SPC P` — update properties (transient menu, also in hydra)
- `I` in org state — `vulpea-insert`

## Bootstrap Order
1. `early-init.el` — visual setup, Guix load paths (from `bootstrap.org`)
2. `init.el` — straight.el → org → leaf → manifolding-emacs-boot (from `bootstrap.org`)
3. `modules/*.org` processed by manifolding-emacs, sorted by `#+priority:`

## Notes
- `MISSING PROMPTS.org` is auto-generated, lives in notes directory
- `broken-links.org` and `deleted-files.org` are admin files generated by the links plugin
- Don't edit `vulpea.db` directly — it's managed by vulpea's SQLite layer
- `vulpea-db-sync-verbose` is `nil` — sync is silent
