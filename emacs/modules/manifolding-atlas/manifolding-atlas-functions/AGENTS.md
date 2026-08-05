# Manifolding Atlas Functions — Infrastructure

Infrastructure files loaded by manifolding-emacs. These provide the core building blocks used by plugins and prompts.

## Files

| File | Purpose | Key Functions/Vars |
|------|---------|-------------------|
| `note-creation.org` | Default create function, fast mode | `my/manifolding-atlas--fast-level`, `my/manifolding-atlas--pending-post-apply`, `manifolding-atlas-create-default-function` |
| `prompt-infrastructure.org` | Prompt collection, fast collector, missing prompts | `my/manifolding-atlas-collect-prompts`, `my/manifolding-atlas--collect-default-prompts`, `my/manifolding-atlas-collect-prompts-with-fast`, `my/manifolding-atlas--close-help` |
| `capture-entry-points.org` | doct template functions | `my/manifolding-atlas-capture-new-file`, `my/manifolding-atlas-capture-task-file`, `my/manifolding-atlas-capture-heading`, `my/manifolding-atlas-insert-heading`, `my/manifolding-atlas--create-file-wrapper` |
| `capture-infrastructure.org` | Capture flow control | `my/manifolding-atlas--choose-capture`, `my/manifolding-atlas--open-capture-for-note`, `my/manifolding-atlas--cleanup-after-capture` |
| `skeleton-preview.org` | Template preview rendering | Template path resolution, preview buffer generation |
| `heading-format.org` | Title/heading transformation | `my/manifolding-atlas--headingify-note-content` (advice on `manifolding-atlas--format-note-content`) |
| `link-utilities.org` | Link helpers | `my/manifolding-atlas-links--current-note-id`, `my/manifolding-atlas--buffer-note` |
| `vault-queries.org` | DB queries | Manifolding Atlas database utility functions |

## Note Creation Flow

1. **Entry point** (`capture-entry-points.org` or `dictionary.org`):
   - `my/manifolding-atlas-capture-new-file` or `my/manifolding-atlas-capture-task-file` or `my/manifolding-atlas-dictionary-new-word`
   - Prompts for title → file name → subdirectory → fast level

2. **Fast level** (`note-creation.org`):
   - `my/manifolding-atlas--fast-level()` returns 0/1/2
   - Affects which prompts fire

3. **Prompt collection** (`prompt-infrastructure.org`):
   - `my/manifolding-atlas-collect-prompts` runs all matching prompts and merges results
   - `my/manifolding-atlas-collect-prompts-with-fast` handles three-way fast mode splitting
   - `my/manifolding-atlas--collect-default-prompts` substitutes all inputs with defaults

4. **Note creation** (`manifolding-atlas-create`):
   - Creates the `.org` file and registers it in the manifolding-atlas SQLite DB
   - Headingification (`heading-format.org`) transforms `#+title:` → `* Title` before template insertion

5. **Template selection** (`capture-infrastructure.org` + `skeleton-preview.org`):
   - `my/manifolding-atlas--choose-capture` shows template list with live preview
   - Preview buffer shows rendered output with `%?` replaced by title

6. **Capture** (`org-capture`):
   - Opens the file for body editing with the chosen template
   - Stores `:TEMPLATE:` and `:TEMPLATE_HASH:` properties

7. **Post-apply** (`prompt-infrastructure.org`):
   - `my/manifolding-atlas--pending-post-apply` runs deferred functions after capture

## Key Functions Reference

### Prompt Collection
```elisp
(my/manifolding-atlas-collect-prompts 'file)                ;; collect file-context prompts
(my/manifolding-atlas-collect-prompts '(dictionary))         ;; collect dictionary-context prompts
(my/manifolding-atlas-collect-prompts-with-fast              ;; three-way fast mode
  '(dictionary) '(file))                         ;;   specialized + general contexts
(my/manifolding-atlas--collect-default-prompts 'file)        ;; force defaults for all prompts
```

### Fast Mode
```elisp
(my/manifolding-atlas--fast-level)  ;; returns 0 (normal), 1 (skip general), 2 (skip all)
```

### Capture Helpers
```elisp
(my/manifolding-atlas--create-file-wrapper title fname tags properties body)  ;; creates note
(my/manifolding-atlas--open-capture-for-note note)                            ;; opens org-capture
(my/manifolding-atlas--choose-capture)                                        ;; template selection
```

### Heading Format
```elisp
;; Advice on manifolding-atlas--format-note-content
;; Transforms: #+title: Foo  →  * Foo
;;             #+filetags: :tag:  →  :tag: inline
```
