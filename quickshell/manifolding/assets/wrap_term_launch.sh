#!/usr/bin/env sh

cat ~/.local/state/manifolding/sequences.txt 2>/dev/null

exec "$@"
