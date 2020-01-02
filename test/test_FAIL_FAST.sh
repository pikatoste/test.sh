source "$(dirname "$(readlink -f "$0")")"/../test.sh

test_ok() {
  touch "$TEST_SCRIPT_DIR"/.test_ok
  TEST_OK=1
  true
}

test_fail() {
  touch "$TEST_SCRIPT_DIR"/.test_fail
  TEST_FAIL=1
  false
  true
}

[ $# -eq 0 ] || { run_tests "$@"; exit 0; }

set_test_name "Any command that fails in the body of a test function should make the test to fail"
rm -f "$TEST_SCRIPT_DIR"/.test_ok "$TEST_SCRIPT_DIR"/.test_fail
! bash -c "$0 test_fail"
[ -f "$TEST_SCRIPT_DIR"/.test_fail ]

set_test_name "FAIL_FAST should interrupt the script at the first test failure"
rm -f "$TEST_SCRIPT_DIR"/.test_ok "$TEST_SCRIPT_DIR"/.test_fail
! bash -c "$0 test_fail test_ok"
! [ -f "$TEST_SCRIPT_DIR"/.test_ok ]
[ -f "$TEST_SCRIPT_DIR"/.test_fail ]

set_test_name "not FAIL_FAST should run all tests but signal failure at the end"
rm -f "$TEST_SCRIPT_DIR"/.test_ok "$TEST_SCRIPT_DIR"/.test_fail
! FAIL_FAST=0 bash -c "$0 test_fail test_ok"
[ -f "$TEST_SCRIPT_DIR"/.test_ok ]
[ -f "$TEST_SCRIPT_DIR"/.test_fail ]
