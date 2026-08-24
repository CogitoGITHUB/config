#!/bin/sh
# Depth trace: shows paren depth at every defun in every elisp src block.
# Run: sh ~/.config/emacs/paren-scan.sh
for f in \
  "$HOME/.config/emacs/modules/manifolding-atlas/infra/capture/org-prompts.org" \
  "$HOME/.config/emacs/modules/manifolding-atlas/infra/capture/prompt-engine.org"
do
echo "=== $(basename "$f") ==="
awk '
/^[ \t]*#\+begin_src emacs-lisp/ {
  inblock=1; depth=0; start=NR
  printf "BLOCK L%d\n", NR; next
}
/^[ \t]*#\+end_src/ {
  if (inblock) {
    printf "L%d END depth=%d\n", NR, depth
    if (depth != 0) printf "*** IMBALANCE: %d\n", depth
    inblock=0
  }
  next
}
inblock {
  n=length($0); instr=0
  for (i=1;i<=n;i++) {
    c=substr($0,i,1)
    if (instr) { if(c=="\\"){i++} else if(c=="\"") instr=0; continue }
    if (c==";") break
    if (c=="\"") { instr=1; continue }
    if (c=="("||c=="[") depth++
    if (c==")"||c=="]") depth--
  }
  if ($0 ~ /defun/) printf "  L%d d=%d %.55s\n", NR, depth, $0
}
' "$f"
done
