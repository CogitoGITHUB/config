#!/usr/bin/env bash
# manifolding-atlas REMASTER — RESUME (shell-only remainder)
# Content/reference work already done via editor tools.
# This script only: removes superseded dirs/files, retangles, validates.
set -euo pipefail

M="$HOME/.config/emacs/modules/manifolding-atlas"
cd "$M"

log(){ printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }
die(){ printf '\033[1;31mFATAL: %s\033[0m\n' "$*" >&2; exit 1; }

log "PHASE A assert resume state"
[ -f atlas.org ]            || die "atlas.org missing — run original script first"
[ -d domains ]              || die "domains/ missing"
[ -f schema/register.org ]  || die "schema/register.org missing"
[ -f properties/general/AGENTS.md ] || echo "note: properties/general already clean"
[ -f templates/full-file-templates/manifolding-atlas.el ] || echo "note: full-file-templates already removed"

log "PHASE B remove superseded trees/files (contents preserved elsewhere)"
rm -rf properties
rm -rf templates/full-file-templates
rm -f templates/manifolding-atlas-templates-system.org
rm -f readme.org

log "PHASE C retangle generated artifacts"
if command -v emacs >/dev/null 2>&1; then
  emacs --batch --eval "(progn (require 'org)(find-file \"domains/capture/capture.org\")(org-babel-tangle)(kill-buffer))" \
    && echo "retangled infra/elisp/capture.el" || echo "WARN: retangle failed (manual: M-x org-babel-tangle in domains/capture/capture.org)"
else
  echo "NOTE: emacs not on PATH — M-x org-babel-tangle in domains/capture/capture.org"
fi
[ -f infra/elisp/capture.el ] || echo "WARN: infra/elisp/capture.el missing"

log "PHASE D validation"
FAIL=0
for d in plugins properties manifolding-atlas-functions fast-captures \
         full-file-templates manifolding-atlas.org manifolding-atlas-ui.org \
         consult-manifolding-atlas.org manifolding-atlas-templates-system.org readme.org; do
  [ -e "$d" ] && { echo "OLD ENTRY STILL PRESENT: $d"; FAIL=1; }
done

for pat in 'manifolding-atlas-functions' 'plugins/fast-captures' 'fast-captures' \
           'full-file-templates' 'manifolding-atlas/properties' \
           '[0-9]+\.manifolding-atlas-[a-z-]+\.org' 'consult-manifolding-atlas\.org' \
           'manifolding-atlas-ui\.org' '00-register\.org' \
           'manifolding-atlas-capture\.el' 'manifolding-atlas-templates-system\.org'; do
  hits=$(grep -RIlE "$pat" --include='*.org' --include='*.md' --include='*.el' . 2>/dev/null |
         grep -v '\./domains/plugin-guide\.org' || true)
  [ -n "$hits" ] && { echo "STALE REF [$pat] in: $hits"; FAIL=1; }
done
if grep -RqlE 'manifolding-atlas-functions|plugins/|properties/|full-file-templates|fast-captures|[0-9]+\.manifolding-atlas|00-register\.org|manifolding-atlas-capture\.el|manifolding-atlas-templates-system\.org' \
      domains/plugin-guide.org 2>/dev/null; then
  echo "NOTE: domains/plugin-guide.org (disabled authoring doc) keeps legacy names by design"
fi

for f in atlas.org atlas-ui.org atlas-consult.org README.org AGENTS.md \
         core/-15-atlas.org core/-31-deps.org core/-13-consult.org \
         infra/capture/prompt-engine.org infra/capture/skeleton-preview.org \
         infra/fast/dispatcher.org infra/fast/journal.org infra/elisp/capture.el \
         domains/routines/routines.org domains/mastering/mastering.org \
         domains/schema/schema.org domains/schema-reinforcement/schema-reinforcement.org \
         schema/register.org schema/general/template.org schema/general/thinking.org \
         schema/general/prompts/advantages.org schema/routines/domain.org \
         templates/templates.org templates/files/atlas.el templates/files/notes.org; do
  [ -f "$f" ] || { echo "MISSING TARGET FILE: $f"; FAIL=1; }
done

dup=$(find . -name 'atlas.org' | wc -l)
[ "$dup" = "1" ] || { echo "DUPLICATE atlas.org ($dup)"; FAIL=1; }

echo "--- git status summary ---"
git status --short 2>/dev/null | head -50 || echo "(not a git repo)"

if [ "$FAIL" = "0" ]; then
  log "MIGRATION COMPLETE — all checks passed"
  rm -f -- "$0"
  echo "(this script self-deleted)"
else
  log "FINISHED WITH WARNINGS — see above; script kept for rerun"
fi
