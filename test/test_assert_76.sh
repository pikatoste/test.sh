#!/bin/bash

my_func() {
  echo called >"$OUT"
}

source "$(dirname "$(readlink -f "$0")")"/../test.sh

OUT="$TEST_SCRIPT_DIR"/.test_assert_76.out

start_test "#74: assert_equals never evaluates its arguments"
rm -f "$OUT"
assert_equals my_func my_func
[[ ! -f "$OUT" ]]
echo -n $(assert_equals 2 "\""'$(ls|wc -l)')
# TODO: check that there's no eval parsing error

start_test "#74: failures in assertion functions don't reevaluate the expression"
rm -f "$OUT"
subshell "assert_true \"! my_func\"" || true
diff - "$OUT" <<EOF
called
EOF
rm -f "$OUT"
subshell "assert_false my_func" || true
diff - "$OUT" <<EOF
called
EOF
