# Properties/Recipes — Recipe-Specific Prompts

These prompts only fire for recipe notes (context `'(recipe)`). They are collected via `(my/manifolding-atlas-collect-prompts-with-fast '(recipe) '(file))` in `my/manifolding-atlas-recipe-create`.

## Files

| File | Pri | Prompt | Property | Type |
|------|-----|--------|----------|------|
| `servings.org` | 31 | Servings | `SERVINGS` | read-string |
| `prep-time.org` | 30 | Prep time | `PREP_TIME` | read-string |
| `cook-time.org` | 29 | Cook time | `COOK_TIME` | read-string |
| `ready-in.org` | 28 | Ready in | `READY_IN` | read-string |

## Fast Mode Behavior

- **Level 0** (normal): All 4 recipe prompts + all general prompts fire
- **Level 1** (skip general): All 4 recipe prompts fire, general prompts skip
- **Level 2** (skip all): None fire (defaults returned)

Recipe prompts always fire at levels 0 and 1. They are the "specialized" contexts in `my/manifolding-atlas-collect-prompts-with-fast`.

## Priority

Recipe prompts use priorities 28-31, loading after general (1-6) and dictionary (11-17). Servings (priority 31) loads last → fires first. Ready-in (priority 28) loads first → fires last among recipe prompts.

## Adding a New Recipe Prompt

1. Create a new `.org` file in this directory
2. Call `(my/manifolding-atlas-register-prompt ...)` with `:contexts '(recipe)`
3. Set `#+priority:` between 28-31 (insert at desired fire position)
4. No other changes needed — the recipes plugin automatically collects all `recipe`-context prompts