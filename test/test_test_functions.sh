#!/bin/bash

source "$(dirname "$(readlink -f "$0")")"/../test.sh

define_funcs() {
  eval '
setup_test_suite() {
  echo setup_test_suite >>"$OUTFILE"
}

teardown_test_suite() {
  echo teardown_test_suite >>"$OUTFILE"
}

setup_test() {
  echo setup_test >>"$OUTFILE"
}

teardown_test() {
  echo teardown_test >>"$OUTFILE"
}
  '
}

unset_funcs() {
  unset setup_test_suite
  unset teardown_test_suite
  unset setup_test
  unset teardown_test
}

@test:
@body: {
  [ -z "$test_01_fail" ]
  echo test_01 >>"$OUTFILE"
}

@test:
@body: {
  [ -z "$test_02_fail" ]
  echo test_02 >>"$OUTFILE"
}

start_test "@run_tests should invoke tests and setup methods when there are no failures"
OUTFILE="$TEST_SCRIPT_DIR"/.test_test_functions.out
rm -rf "$OUTFILE"
define_funcs
( @run_tests 3>&1 )
unset_funcs

diff - "$OUTFILE" <<EOF
setup_test_suite
setup_test
test_01
teardown_test
setup_test
test_02
teardown_test
teardown_test_suite
EOF

start_test "@run_tests should invoke tests and setup methods when there are failures"
rm -rf "$OUTFILE"
test_02_fail=1
define_funcs
assert_failure 'push_exit_handler "unset _EXPLICIT_EXIT || true"; @run_tests 3>&1'
unset_funcs

diff - "$OUTFILE" <<EOF
setup_test_suite
setup_test
test_01
teardown_test
setup_test
teardown_test
teardown_test_suite
EOF
