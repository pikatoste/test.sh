source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

OUT="$TESTOUT_DIR"/do_$(basename "$TESTOUT_FILE")

start_test "The error message should identify the source, line, command and exit code when there are no subshells"
! CURRENT_TEST_NAME= SUBSHELL=never STACK_TRACE=no PRUNE_PATH='*/' "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh func2 || false
grep "Error in func2(do_test_error_reporting.sh:7): 'false' exited with status 1" "$OUT"
! CURRENT_TEST_NAME= SUBSHELL=never STACK_TRACE=no PRUNE_PATH='*/' "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh func1 || false
grep "Error in func1(do_test_error_reporting.sh:2): 'false' exited with status 1" "$OUT"
! CURRENT_TEST_NAME= SUBSHELL=never STACK_TRACE=no PRUNE_PATH='*/' "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh test_01 || false
grep "Error in test_01(do_test_error_reporting.sh:12): 'false' exited with status 1" "$OUT"

start_test "The error message should identify the source, line, command and exit code when there are subshells"
! CURRENT_TEST_NAME= SUBSHELL=always STACK_TRACE=no PRUNE_PATH='*/' "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh func2 || false
grep "Error in func2(do_test_error_reporting.sh:7): 'false' exited with status 1" "$OUT"
! CURRENT_TEST_NAME= SUBSHELL=always STACK_TRACE=no PRUNE_PATH='*/' "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh func1 || false
grep "Error in func1(do_test_error_reporting.sh:2): 'false' exited with status 1" "$OUT"
! CURRENT_TEST_NAME= SUBSHELL=always STACK_TRACE=no PRUNE_PATH='*/' "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh test_01 || false
grep "Error in test_01(do_test_error_reporting.sh:12): 'false' exited with status 1" "$OUT"

start_test "The error message should identify the source, line, command and exit code when triggered in teardown_test"
! CURRENT_TEST_NAME= SUBSHELL=never    STACK_TRACE=no PRUNE_PATH='*/' INLINE=     "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh teardown_test || false
grep "Error in teardown_test(do_test_error_reporting.sh:17): 'false' exited with status 1" "$OUT"
  CURRENT_TEST_NAME= SUBSHELL=teardown STACK_TRACE=no PRUNE_PATH='*/' INLINE=     "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh teardown_test
grep "Error in teardown_test(do_test_error_reporting.sh:17): 'false' exited with status 1" "$OUT"
! CURRENT_TEST_NAME= SUBSHELL=never    STACK_TRACE=no PRUNE_PATH='*/' INLINE=true "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh teardown_test || false
grep "Error in teardown_test(do_test_error_reporting.sh:17): 'false' exited with status 1" "$OUT"
  CURRENT_TEST_NAME= SUBSHELL=teardown STACK_TRACE=no PRUNE_PATH='*/' INLINE=true "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh teardown_test
grep "Error in teardown_test(do_test_error_reporting.sh:17): 'false' exited with status 1" "$OUT"

start_test "The error message should identify the source, line, command and exit code when triggered in teardown_test_suite"
! CURRENT_TEST_NAME= SUBSHELL=never    STACK_TRACE=no PRUNE_PATH='*/' INLINE=     "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh teardown_test_suite || false
grep "Error in teardown_test_suite(do_test_error_reporting.sh:21): 'false' exited with status 1" "$OUT"
  CURRENT_TEST_NAME= SUBSHELL=teardown STACK_TRACE=no PRUNE_PATH='*/' INLINE=     "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh teardown_test_suite
grep "Error in teardown_test_suite(do_test_error_reporting.sh:21): 'false' exited with status 1" "$OUT"
! CURRENT_TEST_NAME= SUBSHELL=never    STACK_TRACE=no PRUNE_PATH='*/' INLINE=true "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh teardown_test_suite || false
# TODO: investigar este caso raruno, el comando reportado pasa a ser '[[ $FAIL_FUNC != $FUNCNAME ]]' en lugar de 'false'
grep "Error in teardown_test_suite(do_test_error_reporting.sh:21): '.*' exited with status 1" "$OUT"
  CURRENT_TEST_NAME= SUBSHELL=teardown STACK_TRACE=no PRUNE_PATH='*/' INLINE=true "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh teardown_test_suite
grep "Error in teardown_test_suite(do_test_error_reporting.sh:21): 'false' exited with status 1" "$OUT"

# TODO: errors from asserts are broken, and superbroken in the case of shubshells
start_test "The error message should identify the source, line, command and exit code when triggered in assert"
! CURRENT_TEST_NAME= SUBSHELL=never  STACK_TRACE=no PRUNE_PATH='*/' "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh func_assert || false
grep "Error in expect_true(test.sh:.*): 'false' exited with status 1" "$OUT"
! CURRENT_TEST_NAME= SUBSHELL=always STACK_TRACE=full PRUNE_PATH='*/' "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh func_assert || false
grep "Error in source(test.sh:.*): 'false' exited with status 1" "$OUT"
