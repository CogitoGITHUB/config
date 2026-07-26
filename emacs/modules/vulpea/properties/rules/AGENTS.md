# Properties/Rules — Rule-Specific Prompts

These prompts fire when marking a heading as a rule via `my/vulpea-rules-mark-as-rule` (`SPC v k`). They use context `'(rule)`.

## Files

| File | Pri | Prompt | Field | Type |
|------|-----|--------|-------|------|
| `topic.org` | 24 | Rule topics | `RULE_TOPICS` (property) | completing-read-multiple |
| `scope.org` | 23 | Scope | Tag (`universal`/`general`/`focused`) | completing-read |
| `level.org` | 22 | Level | Tag (`L1`-`L10`) | completing-read |
| `file-override.org` | 21 | File override | `RULE_FILE` (property) | yes-or-no-p → completing-read |

## Behavior

- Prompts fire on existing headings (via `my/vulpea-collect-prompts '(rule)`)
- Properties are set via `org-entry-put`, tags via `org-set-tags`
- If scope is "auto" (default), it's auto-detected from topics + body condition
- If topics are blank, the rule is universal (no `RULE_TOPICS` property)
- The `drill` tag is always added automatically

## Priority

Rule prompts use priorities 21-24, loading after dictionary (11-17) and general (1/5/6). Topic (24) fires first, file-override (21) fires last.

## Adding a New Rule Prompt

1. Create `.org` file in this directory
2. Call `(my/vulpea-register-prompt ...)` with `:contexts '(rule)`
3. Set `#+priority:` between 21-25 (lower = earlier load = later fire)
4. No other changes needed — the rules plugin collects all `rule`-context prompts
