# Templates System

All template files live under `vulpea/templates/` — two engines:

| Engine | Config in | Template dir | Trigger |
|--------|-----------|-------------|---------|
| **org-capture (doct)** | `vulpea-templates-system.org` | `full-file-templates/*.org` | `vulpea-create` → preview select → `org-capture` |
| **yasnippet** | `vulpea-templates-system.org` | `snippets/` | `TAB` inline expansion |

## org-capture (doct) — Preview

When creating a note via `vulpea-create`, a `completing-read` lets you pick a body template. The split-window preview shows the rendered output in `org-mode` (`outline-show-all` + `org-indent-mode`) with `%?` replaced by the note's actual title. You see exactly what will land in the file.

Templates in `vulpea/templates/full-file-templates/`:
- **plain** — Minimal: just places cursor for typing
- **notes** — General notes: `** Notes` with list
- **reference** — External sources: `:PROPERTIES:` (`:ROAM_REFS:`) + `** Summary`, `** Claims`, `** Connections`
- **task** — Action items: `** Objective` (checkbox) + `** Notes`
- **math** — Math/concepts: `** Definition`, `** Theorem`, `** Lemma`, `** Proof`, `** Properties`, `** Notes`
- **protocol** — Experimental methods: `** Purpose`, `** Materials`, `** Procedure`, `** Results`, `** Analysis`, `** Notes`

Templates contain **only body content** (no `*` heading, no `#+title:` metadata) — headingification creates `* Title` before the template is inserted.

Selection stores `:TEMPLATE:` and `:TEMPLATE_HASH:` properties on the note for schema validation.

## yasnippet

YASnippet snippets live under `snippets/`. Triggered with `TAB` after typing a snippet key (`yas-expand`).
