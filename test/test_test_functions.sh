SUBSHELL=always

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

test_01() {
  [ -z "$test_01_fail" ]
  echo test_01 >>"$OUTFILE"
}

test_02() {
  [ -z "$test_02_fail" ]
  echo test_02 >>"$OUTFILE"
}

source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "run_tests shoud invoke tests and setup methods when there are no failures"
OUTFILE="$TEST_SCRIPT_DIR"/.test_test_functions.out
rm -rf "$OUTFILE"
define_funcs
( CURRENT_TEST_NAME= run_tests )
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

start_test "run_tests shoud invoke tests and setup methods when there are failures"
rm -rf "$OUTFILE"
test_02_fail=1
define_funcs
( ! CURRENT_TEST_NAME= subshell run_tests || false )
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
