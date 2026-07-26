# Vulpea Functions — Infrastructure

Infrastructure files loaded by manifolding-emacs. These provide the core building blocks used by plugins and prompts.

## Files

| File | Purpose | Key Functions/Vars |
|------|---------|-------------------|
| `note-creation.org` | Default create function, fast mode | `my/vulpea--fast-level`, `my/vulpea--pending-post-apply`, `vulpea-create-default-function` |
| `prompt-infrastructure.org` | Prompt collection, fast collector, missing prompts | `my/vulpea-collect-prompts`, `my/vulpea--collect-default-prompts`, `my/vulpea-collect-prompts-with-fast`, `my/vulpea--close-help` |
| `capture-entry-points.org` | doct template functions | `my/vulpea-capture-new-file`, `my/vulpea-capture-task-file`, `my/vulpea-capture-heading`, `my/vulpea-insert-heading`, `my/vulpea--create-file-wrapper` |
| `capture-infrastructure.org` | Capture flow control | `my/vulpea--choose-capture`, `my/vulpea--open-capture-for-note`, `my/vulpea--cleanup-after-capture` |
| `skeleton-preview.org` | Template preview rendering | Template path resolution, preview buffer generation |
| `heading-format.org` | Title/heading transformation | `my/vulpea--headingify-note-content` (advice on `vulpea--format-note-content`) |
| `link-utilities.org` | Link helpers | `my/vulpea-links--current-note-id`, `my/vulpea--buffer-note` |
| `vault-queries.org` | DB queries | Vulpea database utility functions |

## Note Creation Flow

1. **Entry point** (`capture-entry-points.org` or `dictionary.org`):
   - `my/vulpea-capture-new-file` or `my/vulpea-capture-task-file` or `my/vulpea-dictionary-new-word`
   - Prompts for title → file name → subdirectory → fast level

2. **Fast level** (`note-creation.org`):
   - `my/vulpea--fast-level()` returns 0/1/2
   - Affects which prompts fire

3. **Prompt collection** (`prompt-infrastructure.org`):
   - `my/vulpea-collect-prompts` runs all matching prompts and merges results
   - `my/vulpea-collect-prompts-with-fast` handles three-way fast mode splitting
   - `my/vulpea--collect-default-prompts` substitutes all inputs with defaults

4. **Note creation** (`vulpea-create`):
   - Creates the `.org` file and registers it in the vulpea SQLite DB
   - Headingification (`heading-format.org`) transforms `#+title:` → `* Title` before template insertion

5. **Template selection** (`capture-infrastructure.org` + `skeleton-preview.org`):
   - `my/vulpea--choose-capture` shows template list with live preview
   - Preview buffer shows rendered output with `%?` replaced by title

6. **Capture** (`org-capture`):
   - Opens the file for body editing with the chosen template
   - Stores `:TEMPLATE:` and `:TEMPLATE_HASH:` properties

7. **Post-apply** (`prompt-infrastructure.org`):
   - `my/vulpea--pending-post-apply` runs deferred functions after capture

## Key Functions Reference

### Prompt Collection
```elisp
(my/vulpea-collect-prompts 'file)                ;; collect file-context prompts
(my/vulpea-collect-prompts '(dictionary))         ;; collect dictionary-context prompts
(my/vulpea-collect-prompts-with-fast              ;; three-way fast mode
  '(dictionary) '(file))                         ;;   specialized + general contexts
(my/vulpea--collect-default-prompts 'file)        ;; force defaults for all prompts
```

### Fast Mode
```elisp
(my/vulpea--fast-level)  ;; returns 0 (normal), 1 (skip general), 2 (skip all)
```

### Capture Helpers
```elisp
(my/vulpea--create-file-wrapper title fname tags properties body)  ;; creates note
(my/vulpea--open-capture-for-note note)                            ;; opens org-capture
(my/vulpea--choose-capture)                                        ;; template selection
```

### Heading Format
```elisp
;; Advice on vulpea--format-note-content
;; Transforms: #+title: Foo  →  * Foo
;;             #+filetags: :tag:  →  :tag: inline
```
