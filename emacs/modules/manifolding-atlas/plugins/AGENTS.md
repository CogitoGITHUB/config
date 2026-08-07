# Manifolding Atlas Plugins

Each plugin is an `.org` file under `modules/manifolding-atlas/plugins/`. They are loaded by manifolding-emacs along with all other modules.

## Files

| File | Purpose |
|------|---------|
| `0.manifolding-atlas-plugin-guide.org` | Reference documentation (not a real plugin) |
| `backup-git.org` | Backup and restore notes |
| `capture-plugin.org` | Org-capture integration, template selection |
| `citation.org` | Citation management (bibtex, Zotero) |
| `dictionary.org` | Dictionary word notes — word entry, fast mode, dictionary regeneration |
| `backup-git.org` | Git auto-commit, push guards, save hooks |
| `links.org` | Broken link detection, link renaming, deleted file tracking |
| `manifold.org` | ManifoldOS integration |
| `properties-update.org` | Transient menu for updating note properties |
| `protocols.org` | Protocol handler registration |
| `rules.org` | Heading-based rule system with routing |
| `schemas.org` | DB schema validation, MISSING PROMPTS generation |
| `recipes.org` | Recipe notes — manual (no URL/source), default subdir `recipes/`, `my/manifolding-atlas-recipe-create`, `my/manifolding-atlas-recipes-edit-servings` |
| `transclusion.org` | Org-transclusion integration |
| `manifolding-atlas-capture.el` | Elisp helper loaded alongside capture |

## Adding a New Plugin

1. Create `.org` file in `plugins/`
2. Use `my/` namespace for all functions (e.g. `my/manifolding-atlas-my-plugin--internal`)
3. Register keybindings in `keyboard.org` (look for the Manifolding Atlas hydra `SPC v`)
4. If the plugin needs DB tables, add them in the plugin's init block
5. No `(provide ...)` or explicit loading needed — manifolding-emacs handles it

## Key Plugin Details

### dictionary.org
- `my/manifolding-atlas-dictionary-new-word` — main entry point (`SPC v w n`)
- Uses `(my/manifolding-atlas-collect-prompts-with-fast '(dictionary) '(file))` for prompt collection
- Regenerates `dictionary.pws` after each word creation
- Dictionary-specific prompts live in `properties/dictionary/`

### schemas.org
- `manifolding-atlas-db-schema-validation-action` is `'silent` — no interactive warnings
- Base schema applies to ALL notes (requires 6 state fields, optional 2)
- Violations tracked via MISSING PROMPTS, rebuilt on `org-capture-after-finalize-hook`

### backup-git.org
- `before-save-hook` blocks save with `user-error` if no `.git`
- After save: auto `git add --all && git commit -m "auto: ..."` + async push
- Untracked files in `dired` get a confirmation prompt before delete

### rules.org
- Headings marked `:RULE: t` become rules
- `:RULE_TOPICS:` space-separated, first is primary
- Pointer files use `#+transclude:` (not bare links)
- Binding: `SPC v k` (mark rule), `SPC v K` (rule file), `SPC v R` (find rules)

### recipes.org
- **Manual authoring only** — no URL fetch, no source/source-url property
- Notes tagged `recipe`, default subdir `recipes/` (fixed, unlike `choose-subdir`)
- `my/manifolding-atlas-recipe-create` — slugify title, collect prompt context `(recipe)`, open capture
- `my/manifolding-atlas-recipes-edit-servings` — wraps `org-chef-edit-servings` on the recipe at point
- Recipe-specific properties (`SERVINGS`, `PREP_TIME`, `COOK_TIME`, `READY_IN`) come from the body template `templates/full-file-templates/recipes.org`
- Binding: `SPC v` → hydra → `R` group
