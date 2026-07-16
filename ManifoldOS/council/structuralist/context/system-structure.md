# Structuralist — Context Files

## Required References

### System Structure
- `constitution.scm` — entry point, reflects entire system shape
- `substrate/substrate.scm` — module composition
- `substrate/kernel-space/kernel-space.scm` — kernel module exports
- `substrate/user-space/root/root.scm` — root packages aggregator
- `substrate/user-space/home/home.scm` — home services aggregator

### Key Patterns
- Module naming: `(substrate <layer> <category> <name>)`
- Loader pattern: aggregate packages, export as list
- Service composition: append to services list in substrate.scm

### Dependency Graph
```
constitution.scm
  └── substrate.scm
       ├── kernel-space/*.scm
       └── user-space/
            ├── root/root.scm
            │    └── loaders/*.scm
            └── home/home.scm
                 └── loaders/*.scm
```