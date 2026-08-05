# Properties/Dictionary — Dictionary-Specific Prompts

These prompts only fire for dictionary word notes (context `'(dictionary)`). They are collected via `(my/manifolding-atlas-collect-prompts-with-fast '(dictionary) '(file))` in `my/manifolding-atlas-dictionary-new-word`.

## Files

| File | Pri | Prompt | Property | Type |
|------|-----|--------|----------|------|
| `pos.org` | 17 | Part of Speech | `POS` | completing-read |
| `pronunciation.org` | 16 | IPA Pronunciation | `PRONUNCIATION` | read-string |
| `etymology.org` | 15 | Word Origin | `ETYMOLOGY` | completing-read |
| `register.org` | 14 | Formality Register | `REGISTER` | completing-read |
| `frequency.org` | 13 | Usage Frequency | `FREQUENCY` | completing-read |
| `synonyms.org` | 12 | Synonyms | `SYNONYMS` | read-string |
| `examples.org` | 11 | Example Sentence | `EXAMPLE` | read-string |

## Fast Mode Behavior

- **Level 0** (normal): All 7 dictionary prompts + all general prompts fire
- **Level 1** (skip general): All 7 dictionary prompts fire, general prompts skip
- **Level 2** (skip all): None fire (defaults returned)

Dictionary prompts always fire at levels 0 and 1. They are the "specialized" contexts in `my/manifolding-atlas-collect-prompts-with-fast`.

## Priority

Dictionary prompts use priorities 11-17, loading after general prompts (priorities 1-6). POS (priority 17) loads last → fires first. Examples (priority 11) loads first → fires last among dictionary prompts.

## Adding a New Dictionary Prompt

1. Create a new `.org` file in this directory
2. Call `(my/manifolding-atlas-register-prompt ...)` with `:contexts '(dictionary)`
3. Set `#+priority:` between 11-17 (insert at desired fire position)
4. No other changes needed — the dictionary plugin automatically collects all `dictionary`-context prompts
