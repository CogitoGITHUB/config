# Propagandist — Context Files

## Required References

### Documentation Locations
- `council/templates/` — reusable templates
- `council/adding-packages/` — package addition patterns
- `manuals/` — user-facing guides
- `council/getting-started.org` — new user onboarding
- `council/org-mode-guide.org` — Emacs org-mode reference

### Template Locations
```
council/templates/
├── basic.org          → basic config template
├── infrastructure.org → infra template
└── npm-fod.org       → package template
```

### Documentation Patterns
```org
#+TITLE: Package Name
#+DESCRIPTION: What this package does

* Package Definition
  Source, version, dependencies

* Integration
  How it connects to system

* Usage
  How to use/configure
```

### Key Files to Maintain
- `council/index.org` — navigation
- `council/start.org` — orientation
- `manuals/*.md` — user guides

### Execution Triggers
1. structuralist requests docs → write architecture docs
2. curator adds package → write package docs
3. empiricist fixes bug → document solution in troubleshooting/
4. cartographer requests index → update navigation