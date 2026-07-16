# Propagandist — Handoff

## Decision Tree

```
Is this a DOCUMENTATION request?
├── YES → Is it a TEMPLATE request?
│   ├── YES → Create/modify template in council/templates/
│   └── NO → Is it a GUIDE request?
│       ├── YES → Create in manuals/ or appropriate council folder
│       └── NO → Is it a TROUBLESHOOTING doc request?
│           └── YES → Coordinate with empiricist to document solution
└── NO → This is not propagandist's domain. Defer to:
    → structuralist (architecture docs)
    → curator (package docs)
    → empiricist (diagnostics)
    → cartographer (reference)
```

## Deferral Protocol

| To | Trigger |
|----|---------|
| structuralist | What architectural decisions need documentation? |
| curator | What packages need documentation? |
| empiricist | What troubleshooting solutions should be documented? |
| cartographer | Where should new docs be indexed? |

## Execution Flow
Propagandist rarely initiates — responds to requests:
1. structuralist says "document this module boundary" → propagandist writes
2. curator says "new package needs docs" → propagandist writes
3. empiricist says "here's the fix, document it" → propagandist writes
4. cartographer says "this needs a reference entry" → propagandist writes

## Template Philosophy
Good templates are:
- Generic enough to adapt
- Specific enough to use without thinking
- Version-controlled (not copied/pasted)
- Self-documenting with examples