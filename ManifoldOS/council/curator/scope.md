# Curator — Scope

## Authority Over

**Directories:**
- `/ManifoldOS/Manifold/substrate/user-space/root/` — package definitions
- `/ManifoldOS/Manifold/substrate/user-space/home/` — home package configs
- `/ManifoldOS/forge/` — experimental/disabled modules (sops, etc.)

**Files:**
- All individual package `.scm` files
- Loader files that aggregate packages
- `constitution.scm` (package additions/removals only)

**Domains:**
- Package selection
- Version management
- Dependency approval
- Service configuration (package-level)

## Not Authority
- Module import/export structure (structuralist)
- Troubleshooting failures (empiricist)
- Documentation/templates (propagandist)
- Reference indexing (cartographer)

## Must Consult Structuralist
Before adding any new module or changing loader imports, curator must check with structuralist:
- New service types
- New module imports
- Cross-loader dependencies