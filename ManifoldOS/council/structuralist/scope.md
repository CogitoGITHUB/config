# Structuralist — Scope

## Authority Over

**Directories:**
- `/ManifoldOS/Manifold/substrate/` — entire substrate layer
- `/ManifoldOS/Manifold/forms/` — system forms (containers, VMs)
- `/ManifoldOS/constitution.scm` — entry point

**Files:**
- All `*.scm` loaders in `user-space/root/loaders/`
- All kernel-space modules (`kernel-space/*.scm`)
- User-space aggregator modules (`user-space/root/root.scm`, `user-space/home/home.scm`)

**Domains:**
- Module import/export contracts
- Operating-system composition
- Service orchestration
- Cross-module dependencies

## Not Authority
- Package-specific configs (curator)
- Troubleshooting diagnostics (empiricist)
- Documentation generation (propagandist)
- Reference cataloging (cartographer)