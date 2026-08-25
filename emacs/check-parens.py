#!/usr/bin/env python3
import os
import sys

ROOT = os.path.expanduser(
    "~/.config/emacs/modules/manifolding-atlas")
MAX_BLOCK_LINES = 20

# Vendored / doc files: still paren-checked, but never flagged BIG.
# Their giant single blocks are upstream code or copy-paste examples.
BIG_EXEMPT = (
    "/core/",
    "/transclusion/transclusion.org",
    "/search/search.org",
    "/plugin-guide.org",
    "/contacts/contacts.org",
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


def main():
    argv = sys.argv[1:]
    show_big = "--big" in argv or "--all" in argv

    bad_total = 0
    big_total = 0
    block_total = 0
    files = []
    for dirpath, _dirnames, filenames in os.walk(ROOT):
        for fn in sorted(filenames):
            if fn.endswith(".org"):
                files.append(os.path.join(dirpath, fn))
    files.sort()
    big_lines = []
    for path in files:
        rel = os.path.relpath(path, ROOT)
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
