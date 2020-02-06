#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "Failing teardown functions should not break the test"
run_test_script do_test_teardown_fail.sh

start_test "Teardown functions should execute in errexit context"
OUT=$LOG_DIR/do_test_teardown_fail.sh.out
assert_equals 0 "$(grep -c "never reached" "$OUT" || true)" "teardown function in ignored errexit context"

start_test "Teardown functions should print a warning in the main output when they fail"
OUT="$TEST_SCRIPT_DIR"/.do_test_teardown_fail.sh.mainout
( COLOR=no run_test_script do_test_teardown_fail.sh >"$OUT" )
diff - "$OUT" <<EOF
* test_01
WARN: teardown_test failed
WARN: teardown_test_suite failed
EOF
rm "$OUT"
