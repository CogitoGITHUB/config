# schema — the data language

## Declarative prompt format (org-prompts engine)

Any `.org` here with NO src blocks and a level-1 heading shaped
`PROPERTY_KEY` is auto-registered by infra/capture/org-prompts.org.
Level-2 headings are the options. Edit headings to edit the prompt.

```org
* STATE_WORK
:PROPERTIES:
:CONTEXTS: file heading task   ; default: file heading
:REQUIRED: t                   ; optional
:KIND: live                    ; property|live|todo|multi|tags|tagopt|
:LIVE: state-work              ; topics|template|free|scoped|mastering
:LABEL: State: Work            ; optional
:ID: todo                      ; optional registry-key override
:TASK-DEFAULT: ACTIVE          ; optional extra task-context registration
:END:
** ACTIVE
** PAUSED
```

KIND semantics: property=plain value; live=value becomes ref-note link
(family from :LIVE:); scoped=free text + per-entity ref note; free=plain
text; todo=TODO keyword fragment; multi=CRM space-joined; tags=DB-completed
tag list; tagopt=choice written as tag (sentinel :DEFAULT: skips);
topics=RULE_TOPICS DB-completion; template=templates/files chooser +
TEMPLATE_HASH sync + defers during file capture. Every declarative prompt
also defines my/manifolding-atlas-prompt-<key> for direct callers.

Selection UI (default): prompts open their own org file in a normal
editable buffer — navigate/fold/edit freely, RET on any option heading
(level 2 or deeper: level-3+ headings are VARIANTS of the parent option)
selects that heading's title, m marks for multi, q cancels to WARNING.
Set my/manifolding-atlas-org-prompt-ui to 'minibuffer for completing-read.
Options therefore include every descendant heading of the key.

Converted to declarative: all state-* (live), priority, todo, thinking,
mastering, template, traps-external/internal, rules, routines/domain+temporal,
rules/scope+level+topic, dictionary/{pos,register,frequency,etymology,
examples,synonyms,pronunciation}, contacts/{note,nickname,email,phone,birthday}.

Still elisp (behavioral, not option lists): mind-map (target select),
tags (legacy duplicate? no — engine KIND tags covers new files; legacy file
kept), schedule, aliases, subdir, file-name, position (:after fragment),
rules/file-override (yes-no gate).

register.org resets and owns `my/manifolding-atlas-prompt-registry`
(reset on reload prevents duplicates). Prompts self-register by existing
in this tree. Schema definitions themselves live in
domains/schema/schema.org and domains/routines/routines.org
(routine/session schemas) — their extractors read this outline directly.

## Legacy: general prompt conventions

- Default value: "⚠ WARNING" (user can skip by accepting default)
- :to-plist returns nil when WARNING selected (no property set)
- Each file registers exactly one prompt
- Priority 1 for most files, 5-6 for state files
- State prompts marked "required" by the base schema show as violations
  in MISSING PROMPTS when skipped; optional ones produce no violation
