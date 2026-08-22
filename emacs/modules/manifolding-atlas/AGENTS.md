# Manifolding Atlas — Agent Context (remastered layout)

Architecture: core (engine) → infra (machinery) → domains (capabilities)
→ schema (data language) + templates (generation).

- Entry/config: `atlas.org`, `atlas-ui.org` (priority 10). Consult
  integration RETIRED — selection uses native manifolding-atlas-select.
- `core/`: vendored engine, filenames `-NN-<name>.org`, order -31..-13 fixed
- `infra/capture/org-prompts.org`: declarative prompt engine — schema
  outlines (level-1 KEY, level-2+ options incl. variants) auto-register;
  buffer-based picker (RET select / m mark / q cancel), 11 kinds; see
  schema/AGENTS.md for the format spec
- `domains/schema-reinforcement/schema-reinforcement.org`: sweeps keep
  MISSING PROMPTS fresh, index action = warning, registry audit
- `domains/routines/routines.org`: chains + session journaling +
  temporal streaks + compliance report
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

Path helpers: infra/paths.org is the single source of truth for every
in-module location (module/schema/templates/files/fast dirs) — nothing
else hardcodes modules/manifolding-atlas paths.
Keybindings: SPC v hydra in modules/keyboard.org.
