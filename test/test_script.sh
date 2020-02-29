#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "When executed, test.sh should output the version and github project"
OUT=$TEST_TMP/out
"$TESTSH" >"$OUT"
assert_success 'grep test.sh\ version "$OUT"'
assert_success 'grep See\ https://github.com/pikatoste/test.sh "$OUT"'
