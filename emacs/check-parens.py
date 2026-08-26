#!/usr/bin/env python3
"""Paren/block hygiene checker for the literate config.

Scans every emacs-lisp src block under the Org tree(s):
  - Manifolding-Emacs/          (loader.org + all modules)
  - bootstrap.org               (the init.el/early-init.el build step)

BAD  = unbalanced block (depth != 0, extra ')', or unterminated block)
BIG  = block over MAX_BLOCK_LINES code lines, unless the path matches
       BIG_EXEMPT (upstream-atomic / vendored code kept whole on purpose).

Exit status mirrors reality: CLEAN is only printed when bad_total == 0.
"""
import os
import sys

EMACS_DIR = os.path.expanduser("~/.config/emacs")
ROOTS = [
    os.path.join(EMACS_DIR, "Manifolding-Emacs"),
    os.path.join(EMACS_DIR, "bootstrap.org"),
]
MAX_BLOCK_LINES = 20

# Vendored / upstream-atomic / generated files: still paren-checked,
# but never flagged BIG.  Their giant single blocks are upstream code
# kept whole on purpose.
BIG_EXEMPT = (
    "/core/",                                # atlas vendored engine
    "/transclusion/transclusion.org",
    "/search/search.org",
    "/plugin-guide.org",
    "/contacts/contacts.org",
    "/manifolding-dashboard.org",            # vendored emacs-dashboard
    "/manifolding-emacs.org",                # the loader itself (atomic defuns)
)


def scan_block(lines):
    """Return (depth, first_neg_line, first_neg_col, trace).

    first_neg_line/col locate the first unbalanced ')'.
    trace: [(rel-line-1based, depth-at-EOL)] for every line whose
    ending depth differs from the previous line's ending depth."""
    depth = 0
    prev_line_depth = 0
    first_neg_line = None
    first_neg_col = None
    in_str = False
    in_comment = False
    i = 0
    n = len(lines)
    line = 1
    line_start = 0
    trace = []
    while i < n:
        c = lines[i]
        if c == "\n":
            # Newlines always advance the line counter / trace point.
            # Comments end at EOL — but elisp strings MAY span lines
            # (multi-line docstrings), so in_str deliberately persists.
            if depth != prev_line_depth:
                trace.append((line, depth))
                prev_line_depth = depth
            line += 1
            line_start = i + 1
            in_comment = False
            i += 1
            continue
        if in_comment:
            i += 1
            continue
        if in_str:
            if c == "\\":
                i += 2
                continue
            if c == '"':
                in_str = False
            i += 1
            continue
        if c == ";":
            in_comment = True
            i += 1
            continue
        if c == "?":
            if i + 1 < n and lines[i + 1] == "\\":
                i += 3
                continue
            i += 2
            continue
        if c == '"':
            in_str = True
            i += 1
            continue
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth < 0 and first_neg_line is None:
                first_neg_line = line
                first_neg_col = i - line_start + 1
        i += 1
    return depth, first_neg_line, first_neg_col, trace


def collect_files():
    """Yield (display-rel-path, absolute-path) for every .org file."""
    for root in ROOTS:
        if os.path.isfile(root):
            yield os.path.basename(root), root
        elif os.path.isdir(root):
            for dirpath, _dirnames, filenames in os.walk(root):
                for fn in sorted(filenames):
                    if fn.endswith(".org"):
                        p = os.path.join(dirpath, fn)
                        yield os.path.relpath(p, EMACS_DIR), p


def main():
    argv = sys.argv[1:]
    show_big = "--big" in argv or "--all" in argv

    bad_total = 0
    big_total = 0
    block_total = 0
    big_lines = []
    files = sorted(collect_files())
    for rel, path in files:
        with open(path, encoding="utf-8") as fh:
            content = fh.read()
        raw_lines = content.split("\n")
        blocks = []
        cur = None
        for idx, line in enumerate(raw_lines):
            if "#+begin_src emacs-lisp" in line:
                cur = {"start": idx + 1, "code": []}
            elif "#+end_src" in line:
                if cur is not None:
                    blocks.append(cur)
                    cur = None
            elif cur is not None:
                cur["code"].append(line)
        if cur is not None:
            print("BAD   %s: unterminated block starting @org-line %d"
                  % (rel, cur["start"]))
            bad_total += 1
            block_total += 1
        for b in blocks:
            block_total += 1
            body = "\n".join(b["code"])
            depth, neg, neg_col, trace = scan_block(body)
            if depth != 0 or neg is not None:
                msg = ("BAD   %s: block @org-line %d => depth %+d"
                       % (rel, b["start"], depth))
                if neg is not None:
                    msg += (", first extra ')' ~org-line %d col ~%d"
                            % (b["start"] + neg, neg_col))
                else:
                    msg += ", never closes"
                print(msg)
                for (ln, dp) in trace:
                    org_line = b["start"] + ln
                    src = b["code"][ln - 1] if 0 < ln <= len(b["code"]) else ""
                    print("      depth %+d after org-line %d: %s"
                          % (dp, org_line, src.strip()[:70]))
                bad_total += 1
                continue
            code_lines = sum(1 for l in b["code"] if l.strip())
            if code_lines > MAX_BLOCK_LINES and not any(
                    p in path for p in BIG_EXEMPT):
                big_lines.append(
                    "BIG   %s: block @org-line %d => %d code lines"
                    % (rel, b["start"], code_lines))
                big_total += 1
    if show_big:
        for line in big_lines:
            print(line)
    print("%d blocks checked, %d bad parens, %d oversized (> %d lines)"
          % (block_total, bad_total, big_total, MAX_BLOCK_LINES))
    if bad_total == 0:
        print("CLEAN")


if __name__ == "__main__":
    main()
