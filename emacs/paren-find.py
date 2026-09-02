#!/usr/bin/env python3
"""Find the exact lines that contribute to final imbalance."""
import sys
from pathlib import Path

def process_char(c, i, in_string, string_char, in_comment, n):
    """Process a single char, return new state."""
    if in_comment:
        if c == '\n':
            return False, None, False, 1
        return in_string, string_char, in_comment, 0
    if in_string:
        if c == '\\' and i + 1 < n:
            return False, None, False, 2
        if c == string_char:
            return False, None, False, 1
        return True, string_char, False, 1
    if c == ';':
        return False, None, True, 1
    if c == '"':
        return True, '"', False, 1
    return False, None, False, 1

def line_balance(line):
    """Return (delta_depth, last_paren_char, last_paren_idx_in_line)."""
    depth = 0
    in_string = False
    string_char = None
    in_comment = False
    i = 0
    last = None
    while i < len(line):
        c = line[i]
        prev_state = (in_string, string_char, in_comment)
        in_string, string_char, in_comment, advance = process_char(c, i, in_string, string_char, in_comment, len(line))
        if not prev_state[0] and not prev_state[2]:  # not in string/comment
            if c == '(':
                depth += 1
                last = ('(', i, depth)
            elif c == ')':
                depth -= 1
                last = (')', i, depth)
        i += advance
    return depth, last

if __name__ == "__main__":
    fp = Path(sys.argv[1])
    lines = fp.read_text().split('\n')
    total = sum(line_balance(l)[0] for l in lines)
    print(f"Total balance: {total}")

    # Find line where the running balance first becomes non-zero for the first time after being zero
    running = 0
    suspicious = []
    for i, line in enumerate(lines, 1):
        bal, last = line_balance(line)
        prev = running
        running += bal
        if prev == 0 and running != 0 and i > 1:
            suspicious.append((i, prev, running, line[:100]))
        if abs(running) > abs(total) and i > 10:
            suspicious.append((i, prev, running, line[:100]))
            if len(suspicious) >= 5:
                break

    for s in suspicious[:10]:
        print(f"  Line {s[0]}: balance {s[1]} -> {s[2]}: {s[3]}")
