#!/bin/bash
TMPDIR="$(dirname "$(readlink -f "$0")")"/tmp
mkdir -p "$TMPDIR"
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "#74: Use TMPDIR for temporary files"
save_stack
TMPFILE_COUNT=$(find "$TMPDIR" -type f -o -type p | wc -l)
rm -f "$STACK_FILE"
assert_equals 2 "$TMPFILE_COUNT" "Expected two temporary files in $TMPDIR"
rm -rf "$TMPDIR"
