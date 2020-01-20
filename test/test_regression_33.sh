#!/bin/bash

SUBSHELL=never
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "Regression #33: when an include file is matched by more than one glob in INCLUDE_PATH, it is included only once"
cat >"$TEST_SCRIPT_DIR"/include-regression-33.sh <<EOF
echo "regression #33"
EOF
cat >"$TEST_SCRIPT_DIR"/test-regression-33.sh <<EOF
source test.sh
run_tests
EOF
chmod a+x "$TEST_SCRIPT_DIR"/test-regression-33.sh
cp "$TESTSH" "$TEST_SCRIPT_DIR"
unset INCLUDE_GLOB
unset INCLUDE_PATH
( run_test_script ./test-regression-33.sh )
assert_equals 1 "$(grep "regression #33" "$TEST_SCRIPT_DIR"/testout/test-regression-33.sh.out | wc -l)"
rm "$TEST_SCRIPT_DIR"/include-regression-33.sh "$TEST_SCRIPT_DIR"/test-regression-33.sh "$TEST_SCRIPT_DIR"/test.sh
