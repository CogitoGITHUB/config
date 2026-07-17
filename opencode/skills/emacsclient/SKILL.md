---
name: emacsclient
description: Use when the user asks about Emacs integration, elisp evaluation, buffer management, or when opencode should interact with a running Emacs session via emacsclient. Also use when the emacs-mcp-server is unavailable.
---

# Emacsclient

The user runs Emacs as a daemon via shepherd. Socket at `/run/user/1000/emacs/server`.

## Basic usage

```bash
emacsclient --eval '(buffer-list)'
emacsclient --eval '(with-current-buffer (find-file-noselect "~/test/foo.org") (buffer-string))'
```

## Useful snippets

- `(frame-root-window)` — get current window
- `(buffer-name)` — current buffer name
- `(buffer-string)` — contents of current buffer
- `(with-current-buffer "foo.org" (buffer-string))` — read specific buffer
- `(projectile-project-root)` — get project root
- `(my/notes-directory)` — get user's notes directory (`~/test/`)
- `(org-agenda-list)` — show agenda
- `(next-error)` — jump to next flycheck error
- `(compile "make test")` — run compilation
