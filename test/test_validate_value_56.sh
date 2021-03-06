#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "validate_value() should print a comma-separated list of allowes values (#56)"
OUT="$TEST_SCRIPT_DIR"/testout/do_test_validate_value.sh.out
( ! STACK_TRACE=jeronimo COLOR=no run_test_script do_test_validate_value.sh >"$OUT" 2>&1 ) || false
assert_equals \
  "[test.sh] configuration exception: invalid value of variable STACK_TRACE: 'jeronimo', allowed values: no, full" \
  "$(grep -a "invalid value" "$OUT")" \
  "wrong validation message"
