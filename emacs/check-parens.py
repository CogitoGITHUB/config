#!/usr/bin/env python3
import os
import sys

ROOT = os.path.expanduser(
    "~/.config/emacs/modules/manifolding-atlas")
MAX_BLOCK_LINES = 20


def scan_block(lines):
    depth = 0
    first_neg_line = None
    in_str = False
    in_comment = False
    i = 0
    n = len(lines)
    while i < n:
        c = lines[i]
        if in_comment:
            if c == "\n":
                in_comment = False
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
                first_neg_line = i
        i += 1
    return depth, first_neg_line


def main():
    bad_total = 0
    big_total = 0
    block_total = 0
    files = []
    for dirpath, _dirnames, filenames in os.walk(ROOT):
        for fn in sorted(filenames):
            if fn.endswith(".org"):
                files.append(os.path.join(dirpath, fn))
    files.sort()
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
            depth, neg = scan_block(body)
            if depth != 0 or neg is not None:
                msg = ("BAD   %s: block @org-line %d => depth %+d"
                       % (rel, b["start"], depth))
                if neg is not None:
                    msg += (", first extra ')' ~org-line %d"
                            % (b["start"] + neg))
                else:
                    msg += ", never closes"
                print(msg)
                bad_total += 1
                continue
            code_lines = sum(1 for l in b["code"] if l.strip())
            if code_lines > MAX_BLOCK_LINES:
                print("BIG   %s: block @org-line %d => %d code lines"
                      % (rel, b["start"], code_lines))
                big_total += 1
    print("%d blocks checked, %d bad parens, %d oversized (> %d lines)"
          % (block_total, bad_total, big_total, MAX_BLOCK_LINES))


if __name__ == "__main__":
    main()
