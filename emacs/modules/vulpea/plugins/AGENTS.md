# Vulpea Plugins

Each plugin is an `.org` file under `modules/vulpea/plugins/`. They are loaded by manifolding-emacs along with all other modules.

## Files

| File | Purpose |
|------|---------|
| `0.vulpea-plugin-guide.org` | Reference documentation (not a real plugin) |
| `backup.org` | Backup and restore notes |
| `capture-plugin.org` | Org-capture integration, template selection |
| `citation.org` | Citation management (bibtex, Zotero) |
| `dictionary.org` | Dictionary word notes — word entry, fast mode, dictionary regeneration |
| `git.org` | Git auto-commit, push guards, save hooks |
| `links.org` | Broken link detection, link renaming, deleted file tracking |
| `manifold.org` | ManifoldOS integration |
| `properties-update.org` | Transient menu for updating note properties |
| `protocols.org` | Protocol handler registration |
| `rules.org` | Heading-based rule system with routing |
| `schemas.org` | DB schema validation, MISSING PROMPTS.org generation |
| `transclusion.org` | Org-transclusion integration |
| `vulpea-capture.el` | Elisp helper loaded alongside capture |

## Adding a New Plugin

1. Create `.org` file in `plugins/`
2. Use `my/` namespace for all functions (e.g. `my/vulpea-my-plugin--internal`)
3. Register keybindings in `keyboard.org` (look for the Vulpea hydra `SPC v`)
4. If the plugin needs DB tables, add them in the plugin's init block
5. No `(provide ...)` or explicit loading needed — manifolding-emacs handles it

## Key Plugin Details

### dictionary.org
- `my/vulpea-dictionary-new-word` — main entry point (`SPC v w n`)
- Uses `(my/vulpea-collect-prompts-with-fast '(dictionary) '(file))` for prompt collection
- Regenerates `dictionary.pws` after each word creation
- Dictionary-specific prompts live in `properties/dictionary/`

### schemas.org
- `vulpea-db-schema-validation-action` is `'silent` — no interactive warnings
- Base schema applies to ALL notes (requires 6 state fields, optional 2)
- Violations tracked via MISSING PROMPTS.org, rebuilt on `org-capture-after-finalize-hook`

### git.org
- `before-save-hook` blocks save with `user-error` if no `.git`
- After save: auto `git add --all && git commit -m "auto: ..."` + async push
- Untracked files in `dired` get a confirmation prompt before delete

### rules.org
- Headings marked `:RULE: t` become rules
- `:RULE_TOPICS:` space-separated, first is primary
- Pointer files use `#+transclude:` (not bare links)
- Binding: `SPC v k` (mark rule), `SPC v K` (rule file), `SPC v R` (find rules)
