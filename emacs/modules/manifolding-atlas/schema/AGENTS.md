# schema — the data language

register.org resets and owns `my/manifolding-atlas-prompt-registry`
(reset on reload prevents duplicates). Prompts self-register by existing
in this tree; contexts: file, heading, task, dictionary, recipe, contacts,
routine.

general/: required+optional state-* prompts (STATE_WORK, STATE_GENERAL,
STATE_INTELLIGENCE, STATE_OPERATIONAL, STATE_VALIDATION, STATE_SOURCE;
optional dependency/checklist), tags, todo, priority, schedule, aliases,
position, subdir, properties, mind-map, file-name, mastering, thinking
(THINKING_TYPES), template (TEMPLATE + TEMPLATE_HASH sync; defers to the
preview chooser during file creation).

general/prompts/: placeholder prompts awaiting use (advantages, blueprint,
context, counters, decisions, evidence, experiments, failures, hypotheses,
journal, laws, leverage, mastery, objectives, philosophy, quotes, signals,
sources).

Subdirs: dictionary/ (etymology, examples, frequency, pos, pronunciation,
register, synonyms), rules/ (file-override, level, scope, topic),
recipes/ (cook-time, prep-time, ready-in, servings), contacts/ (birthday,
email, nickname, note, phone), routines/ (domain, temporal).

Schema definitions themselves live in domains/schema/schema.org and
domains/routines/routines.org (routine/session schemas).

## Legacy: general prompt conventions

- Default value: "⚠ WARNING" (user can skip by accepting default)
- :to-plist returns nil when WARNING selected (no property set)
- Each file registers exactly one prompt
- Priority 1 for most files, 5-6 for state files
- State prompts marked "required" by the base schema show as violations
  in MISSING PROMPTS when skipped; optional ones produce no violation
