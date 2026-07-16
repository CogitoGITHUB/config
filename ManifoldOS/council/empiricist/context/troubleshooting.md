# Empiricist — Context Files

## Required References

### Troubleshooting Tools
- `council/troubleshooting/` — documented solutions
- `guix system reconfigure` — primary reconfiguration command
- `guix system build` — dry-run testing
- `guix system roll-back` — emergency recovery

### Common Failure Patterns

**Module import failures:**
```
no code for module (substrate kernel-space linux)
```
→ Check load-path in constitution.scm
→ Verify module file exists at expected path

**Package not found:**
```
 unbound variable
 hint: Did you forget `(use-modules ...)'?
```
→ Module not imported in the file using the variable
→ Check loader imports

**Build failures:**
→ Check kernel arguments in linux.scm
→ Check nonguix channel enabled
→ Check #:parallel-build? #f for low-RAM systems

### Diagnostic Commands
```bash
# Test module loads
guile -c "(use-modules (substrate substrate))"

# Dry-run build
guix system build --dry-run /ManifoldOS/constitution.scm

# Check generations
guix system list-generations

# Rollback
guix system roll-back
```

### Emergency Protocol
1. Boot previous generation: `guix system roll-back`
2. Identify change: compare constitution.scm to previous
3. Isolate: comment out suspicious imports
4. Test: `guix system build --dry-run`