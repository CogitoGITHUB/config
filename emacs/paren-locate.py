#!/usr/bin/env python3
"""Find the exact line with paren imbalance."""
import sys
from pathlib import Path

def count_parens_ignore_strings_comments(text):
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

def find_imbalance_line(filepath):
    """Find the deepest nesting point or final imbalance."""
    text = Path(filepath).read_text()
    depth = 0
    max_depth = 0
    max_line = 0
    line = 1
    i = 0
    n = len(text)
    in_string = False
    string_char = None
    in_comment = False

    while i < n:
        c = text[i]
        if c == '\n':
            line += 1
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
                if depth > max_depth:
                    max_depth = depth
                    max_line = line
            elif c == ')':
                depth -= 1
        i += 1
    return max_line, max_depth, depth

if __name__ == "__main__":
    fp = sys.argv[1]
    ml, md, fd = find_imbalance_line(fp)
    print(f"{fp}: deepest depth {md} at line {ml}, final depth {fd}")
