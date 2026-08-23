# Manifolding Atlas — Agent Context (remastered layout)

Architecture: core (engine) → infra (machinery) → domains (capabilities)
→ schema (data language) + templates (generation).

- Entry/config: `atlas.org`, `atlas-ui.org` (priority 10). Consult
  integration RETIRED — selection uses native manifolding-atlas-select.
- `core/`: vendored engine, filenames `-NN-<name>.org`, order -31..-13 fixed
- `infra/capture/org-prompts.org`: declarative prompt engine — schema
  outlines (level-1 KEY, level-2+ options incl. variants) auto-register;
  11 kinds; see schema/AGENTS.md for the format spec
- Capture flows are ASYNC: collector queues buffer-UI prompts
  (`my/manifolding-atlas-collect-defer`), note is created first, then a
  session applies each pick directly to the note (bottom-strip picker,
  note on top). No recursive-edit anywhere in creation — nesting bugs
  from the old design are structurally impossible. Direct single-shot
  calls (`my/manifolding-atlas-prompt-<key>`) keep a standalone path.
- Picker grammar (session pickers): `m` apply/un-apply live to disk,
  `l` upgrade to live ref-note + capture its content, `a` avy-to-option,
  `RET` advance only when something was applied, `q` skip→WARNING,
  `b` step back / `B` revisit any answered prompt (applied value
  restored+highlighted), `Q`/`C-g` abort session and DELETE the draft.
  Fast modes o/e/u never open UI; fast mode `s` (SELECTION) multi-selects
  which registry keys fire interactively while the rest answer WARNING
  silently (`my/manifolding-atlas-org-prompt--custom-set`, includes a
  Body-Template entry that pre-runs the template chooser).
- Every prompt file self-heals a first `** WARNING` option (skip
  sentinel, plain text — no emoji anywhere). RET on it = skip; q/C-g
  too. Point lands on WARNING unless :TASK-DEFAULT: exists.
- Registration warns at boot if a declarative key shadows an existing
  function (`my/manifolding-atlas-prompt-template` collision class).
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

DB location: `~/test/admin/manifolding-atlas.db`, enforced by the
`manifolding-atlas-db` advice in atlas.org — a stale connection or a DB
left at the engine default (`user-emacs-directory/manifolding-atlas.db`)
is closed and relocated automatically on the next DB touch (any note
create/delete). Schema validation action is `'silent`: violations never
hit the minibuffer; MISSING PROMPTS + sweeps are the only surface.

Path helpers: infra/paths.org is the single source of truth for every
in-module location (module/schema/templates/files/fast dirs) — nothing
else hardcodes modules/manifolding-atlas paths.
Keybindings: SPC v hydra in modules/keyboard.org.
