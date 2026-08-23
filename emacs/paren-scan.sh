#!/bin/sh
# Paren scanner v2 — reports the EXACT LINES of unmatched openers.
set -u

FILES="$@"
if [ -z "$FILES" ]; then
  FILES="$HOME/.config/emacs/modules/manifolding-atlas/infra/capture/org-prompts.org
$HOME/.config/emacs/modules/manifolding-atlas/infra/capture/prompt-engine.org"
fi

scan_one() {
  awk -v fname="$1" '
    /^[ \t]*#\+begin_src emacs-lisp/ {
      inblock=1; depth=0; instr=0; esc=0; top=0; next
    }
    /^[ \t]*#\+end_src/ {
      if (inblock) {
        if (depth != 0) {
          printf "%s:%d UNBALANCED (depth %d). Unmatched opener(s) at line(s):\n",
                 fname, NR, depth
          for (i=top; i>0; i--) printf "    line %d\n", opens[i]
          fail=1
        }
        inblock=0; top=0
      }
      next
    }
    inblock {
      n=length($0)
      for (i=1; i<=n; i++) {
        c=substr($0,i,1)
        if (instr) {
          if (esc) esc=0
          else if (c=="\\") esc=1
          else if (c=="\"") instr=0
          continue
        }
        if (c==";") break
        if (c=="\"") { instr=1; continue }
        if (c=="(" || c=="[" || c=="{") {
          depth++; top++; opens[top]=NR
        }
        if (c==")" || c=="]" || c=="}") {
          depth--
          if (top>0) top--
          else { printf "%s:%d EXTRA closer\n", fname, NR; fail=1 }
        }
      }
    }
    END { exit fail ? 1 : 0 }
  ' "$1"
}

FAIL=0
for f in $FILES; do
  [ -f "$f" ] || continue
  echo "== $f =="
  scan_one "$f" || FAIL=1
done
[ "$FAIL" = "0" ] && echo "ALL BALANCED"
exit $FAIL
