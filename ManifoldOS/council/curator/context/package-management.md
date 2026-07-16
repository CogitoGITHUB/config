# Curator — Context Files

## Required References

### Package Management
- `substrate/user-space/root/` — all root packages organized by category
- `substrate/user-space/home/home.scm` — home environment packages
- `substrate/user-space/root/loaders/` — package aggregators by category
- `forge/` — experimental/disabled packages

### Key Package Patterns
```scheme
(define-module (substrate user-space root shell bash)
  #:use-module (guix packages)
  #:use-module (guix build-system gnu)
  #:export (bash))

(define-public bash
  (package
    (name "bash")
    ;; ... ))
```

### Adding Packages
1. Create module in appropriate category under `user-space/root/`
2. Add to relevant loader in `user-space/root/loaders/`
3. Test with: `guile -c "(use-modules (substrate user-space root shell bash))"`
4. Add to constitution.scm if new service

### Common Categories
- shell/ — shells and terminal tools
- networking/ — network tools
- desktop/ — desktop environments
- editors/ — text editors
- security/ — security tools
- programming-languages/ — language runtimes