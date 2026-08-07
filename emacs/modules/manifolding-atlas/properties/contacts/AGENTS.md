# Properties/Contacts — Contact-Specific Prompts

These prompts only fire for contact notes (context `'(contact)`). They are
collected via `(my/manifolding-atlas-collect-prompts-with-fast '(contact) '())`
in `my/manifolding-atlas-contacts-new`. General (`file`) prompts never fire for
contacts.

## Files

| File | Pri | Prompt | Property |
|------|-----|--------|----------|
| `email.org` | 26 | Email | `EMAIL` |
| `phone.org` | 25 | Phone | `PHONE` |
| `nickname.org` | 24 | Nickname | `NICKNAME` |
| `birthday.org` | 23 | Birthday | `BIRTHDAY` |
| `note.org` | 22 | Note | `NOTE` |

Properties are plain strings — org-contacts reads them directly from the
property drawer (no ref links). `"WARNING"` is the accepted skip default.

## Priority

Contact prompts use priorities 21-26, loading after general (1-6) and
dictionary (11-17). Email (26) loads last → fires first. Note (22) loads
first → fires last.

## Adding a New Contact Prompt

1. Create a new `.org` file in this directory
2. Call `(my/manifolding-atlas-register-prompt ...)` with `:contexts '(contact)`
3. Set `#+priority:` between 21-26
4. No other changes needed — the contacts plugin collects all `contact`-context prompts
