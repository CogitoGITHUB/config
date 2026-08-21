# Manifolding Atlas — Agent Context (remastered layout)

Architecture: core (engine) → infra (machinery) → domains (capabilities)
→ schema (data language) + templates (generation).

- Entry/config: `atlas.org`, `atlas-ui.org`, `atlas-consult.org` (priority 10)
- `core/`: vendored engine, filenames `-NN-<name>.org`, order -31..-13 fixed
- `infra/capture/`: entry-points, infrastructure, heading-format,
  link-utilities, note-creation, prompt-engine (registry + MISSING PROMPTS),
  root-dir, skeleton-preview (capture-path/hash), vault-queries
- `infra/fast/`: dispatcher auto-discovers sibling org files; journal/todo/
  observations implement `my/manifolding-atlas-quick-*`; templates/default.org
- `infra/elisp/capture.el`: tangled artifact of domains/capture/capture.org
- `domains/<name>/<name>.org`: one capability each (+ plugin-guide.org reference)
- `schema/register.org`: prompt registry (reset on reload); `general/`
  (state-*, tags, todo, priority, schedule, aliases, position, subdir,
  properties, mind-map, file-name, mastering, thinking, template),
  `general/prompts/` (placeholder prompts), dictionary/, rules/, recipes/,
  contacts/, routines/
- `templates/files/`: body-only capture templates + atlas.el (doct)

Conventions unchanged: `my/` namespace, no comments in src blocks, no blank
line after headings, extensionless vault notes in `~/test/`, DB never
hand-edited, reload via `M-x manifolding-emacs-reload`.

Path helpers live in: domains/schema/schema.org (prompt/template dirs),
infra/capture/skeleton-preview.org (capture-dir), templates/templates.org
(templates root). Keybindings: SPC v hydra in modules/keyboard.org.
