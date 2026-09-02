#!/usr/bin/env python3
"""Check all .el/.org files in Manifolding-Emacs for paren balance and code block issues."""
import re
import sys
from pathlib import Path

def count_parens_ignore_strings_comments(text):
    """Count parens ignoring those inside strings and comments."""
    depth = 0
    i = 0
    in_string = False
    string_char = None
    in_comment = False
    n = len(text)
    while i < n:
        c = text[i]
        if in_comment:
            if c == '\n':
                in_comment = False
        elif in_string:
            if c == '\\' and i + 1 < n:
                i += 2
                continue
            elif c == string_char:
                in_string = False
                string_char = None
        else:
            if c == ';':
                in_comment = True
            elif c == '"':
                in_string = True
                string_char = '"'
            elif c == '(':
                depth += 1
            elif c == ')':
                depth -= 1
        i += 1
    return depth

def check_org_blocks(filepath):
    """Check that #+begin_src matches #+end_src."""
    issues = []
    in_block = False
    line_num = 0
    with open(filepath) as f:
        for line in f:
            line_num += 1
            if line.startswith('#+begin_src'):
                if in_block:
                    issues.append(f"{filepath}:{line_num}: nested #+begin_src (previous not closed)")
                in_block = True
            elif line.startswith('#+end_src'):
                if not in_block:
                    issues.append(f"{filepath}:{line_num}: #+end_src without matching #+begin_src")
                in_block = False
    if in_block:
        issues.append(f"{filepath}: unclosed #+begin_src at end of file")
    return issues

def main():
    root = Path("/data/data/com.termux/files/home/.config/emacs/Manifolding-Emacs")
    if not root.exists():
        print(f"Root not found: {root}")
        sys.exit(1)

    errors = 0
    for path in sorted(root.rglob("*.el")):
        text = path.read_text()
        depth = count_parens_ignore_strings_comments(text)
        if depth != 0:
            print(f"PAREN ERROR: {path}  diff={depth:+d}")
            errors += 1

    for path in sorted(root.rglob("*.org")):
        issues = check_org_blocks(path)
        if issues:
            for i in issues:
                print(i)
                errors += 1

    if errors == 0:
        print("All files OK")
    sys.exit(1 if errors else 0)

if __name__ == "__main__":
    main()
