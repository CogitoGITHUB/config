# Properties/General — Universal Prompts

These prompts apply to ALL notes (context `'file`). They fire during any file-level creation.

## Files

| File | Prompt | Property/Tag | Type |
|------|--------|--------------|------|
| `state-work.org` | Work state | `STATE_WORK` | completing-read (required) |
| `state-general.org` | General state | `STATE_GENERAL` | completing-read (required) |
| `state-intelligence.org` | Intelligence state | `STATE_INTELLIGENCE` | completing-read (required) |
| `state-operational.org` | Operational state | `STATE_OPERATIONAL` | completing-read (required) |
| `state-validation.org` | Validation state | `STATE_VALIDATION` | completing-read (required) |
| `state-source.org` | Source state | `STATE_SOURCE` | completing-read (required) |
| `state-dependency.org` | Dependency state | `STATE_DEPENDENCY` | completing-read (optional) |
| `state-checklist.org` | Checklist state | `STATE_CHECKLIST` | completing-read (optional) |
| `tags.org` | Tags | Tags | completing-read (multiple) |
| `todo.org` | TODO state | `my/manifolding-atlas--creation-todo` | completing-read |
| `priority.org` | Priority | `PRIORITY` | completing-read |
| `schedule.org` | Scheduled/Deadline | `SCHEDULED`, `DEADLINE` | completing-read |
| `aliases.org` | Aliases | `ALIASES` | read-string |
| `position.org` | Position | `POSITION` | completing-read |
| `subdir.org` | Subdirectory | File path | read-directory-name |
| `properties.org` | Extra properties | User-specified | completing-read |
| `mind-map.org` | Mind map | `MIND_MAP` | completing-read |
| `file-name.org` | File name override | `:file-name` fragment | read-string |

## Required vs Optional

State prompts marked "required" by the base schema will show as violations in MISSING PROMPTS if set to `"⚠ WARNING"` (skipped). Optional state prompts (dependency, checklist) produce no violation.

## Conventions

- Default value: `"⚠ WARNING"` (user can skip by accepting default)
- `:to-plist` returns `nil` when WARNING selected (no property set)
- Each file registers exactly one prompt
- Priority 1 for most files, 5-6 for state files (load after basic prompts, but before dictionary)
