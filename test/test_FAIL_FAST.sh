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

source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "Any command that fails in the body of a test function should make the test to fail"
rm -f "$TEST_SCRIPT_DIR"/.test_ok "$TEST_SCRIPT_DIR"/.test_fail
! CURRENT_TEST_NAME= subshell "run_tests test_fail" || false
[ -f "$TEST_SCRIPT_DIR"/.test_fail ]

start_test "When FAIL_FAST is true the first test failure should interrupt the script"
rm -f "$TEST_SCRIPT_DIR"/.test_ok "$TEST_SCRIPT_DIR"/.test_fail
! CURRENT_TEST_NAME= subshell "run_tests test_fail test_ok 3>/dev/null" || false
! [ -f "$TEST_SCRIPT_DIR"/.test_ok ] || false
[ -f "$TEST_SCRIPT_DIR"/.test_fail ]

start_test "When FAIL_FAST is false failures should not interrupt the script but signal failure at the end"
rm -f "$TEST_SCRIPT_DIR"/.test_ok "$TEST_SCRIPT_DIR"/.test_fail
! FAIL_FAST= SUBSHELL=always CURRENT_TEST_NAME= subshell "run_tests test_fail test_ok" || false
[ -f "$TEST_SCRIPT_DIR"/.test_ok ]
[ -f "$TEST_SCRIPT_DIR"/.test_fail ]
