#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

OUT="$LOG_DIR"/do_$(basename "$LOG_FILE")

start_test "The error message should identify the source, line, command and exit code when there are no subshells"
! SUBSHELL=never run_test_script do_test_error_reporting.sh [func2] || false
grep "Error in func2(do_test_error_reporting.sh:8): 'false' exited with status 1" "$OUT"
! SUBSHELL=never run_test_script do_test_error_reporting.sh [func1] || false
grep "Error in func1(do_test_error_reporting.sh:3): 'false' exited with status 1" "$OUT"
! SUBSHELL=never run_test_script do_test_error_reporting.sh [test_01] || false
grep "Error in test_01(do_test_error_reporting.sh:13): 'false' exited with status 1" "$OUT"

start_test "The error message should identify the source, line, command and exit code when there are subshells"
! SUBSHELL=always run_test_script do_test_error_reporting.sh [func2] || false
grep "Error in func2(do_test_error_reporting.sh:8): 'false' exited with status 1" "$OUT"
! SUBSHELL=always run_test_script do_test_error_reporting.sh [func1] || false
grep "Error in func1(do_test_error_reporting.sh:3): 'false' exited with status 1" "$OUT"
! SUBSHELL=always run_test_script do_test_error_reporting.sh [test_01] || false
grep "Error in test_01(do_test_error_reporting.sh:13): 'false' exited with status 1" "$OUT"

start_test "The error message should identify the source, line, command and exit code when triggered in teardown_test"
SUBSHELL=never    INLINE=     run_test_script do_test_error_reporting.sh [teardown_test]
grep "Error in teardown_test(do_test_error_reporting.sh:18): 'false' exited with status 1" "$OUT"
[[ $(grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT" | wc -l) = 1 ]]
SUBSHELL=teardown INLINE=     run_test_script do_test_error_reporting.sh [teardown_test]
grep "Error in teardown_test(do_test_error_reporting.sh:18): 'false' exited with status 1" "$OUT"
[[ $(grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT" | wc -l) = 1 ]]
SUBSHELL=never    INLINE=true run_test_script do_test_error_reporting.sh [teardown_test]
grep "Error in teardown_test(do_test_error_reporting.sh:18): 'false' exited with status 1" "$OUT"
[[ $(grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT" | wc -l) = 2 ]]
SUBSHELL=teardown INLINE=true run_test_script do_test_error_reporting.sh [teardown_test]
grep "Error in teardown_test(do_test_error_reporting.sh:18): 'false' exited with status 1" "$OUT"
[[ $(grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT" | wc -l) = 2 ]]

start_test "The error message should identify the source, line, command and exit code when triggered in teardown_test_suite"
SUBSHELL=never    INLINE=     run_test_script do_test_error_reporting.sh [teardown_test_suite]
grep "Error in teardown_test_suite(do_test_error_reporting.sh:23): 'false' exited with status 1" "$OUT"
SUBSHELL=teardown INLINE=     run_test_script do_test_error_reporting.sh [teardown_test_suite]
grep "Error in teardown_test_suite(do_test_error_reporting.sh:23): 'false' exited with status 1" "$OUT"
SUBSHELL=never    INLINE=true run_test_script do_test_error_reporting.sh [teardown_test_suite]
# aparente error en bash: el comando reportado pasa a ser '[[ $FAIL_FUNC != $FUNCNAME ]]' en lugar de 'false'
grep "Error in teardown_test_suite(do_test_error_reporting.sh:23): '.*' exited with status 1" "$OUT"
SUBSHELL=teardown INLINE=true run_test_script do_test_error_reporting.sh [teardown_test_suite]
grep "Error in teardown_test_suite(do_test_error_reporting.sh:23): 'false' exited with status 1" "$OUT"

start_test "The error message should identify the source, line, command and exit code when triggered in assert"
! SUBSHELL=never  run_test_script do_test_error_reporting.sh [func_assert] || false
grep "Error in expect_true(test.sh:.*): 'false' exited with status 1" "$OUT"
! SUBSHELL=always STACK_TRACE=full run_test_script do_test_error_reporting.sh [func_assert] || false
grep "Error in source(test.sh:.*): 'false' exited with status 1" "$OUT"

start_test "The error message should identify the source, line, command and exit code when triggered in setup_test_suite"
! SUBSHELL=never    INLINE=     run_test_script do_test_error_reporting.sh [setup_test_suite] || false
grep "Error in setup_test_suite(do_test_error_reporting.sh:38): 'false' exited with status 1" "$OUT"
[[ $(grep "Error in setup_test_suite(do_test_error_reporting.sh:38): '.*' exited with status 1" "$OUT" | wc -l) = 1 ]]
! SUBSHELL=never    INLINE=true run_test_script do_test_error_reporting.sh [setup_test_suite] || false
grep "Error in setup_test_suite(do_test_error_reporting.sh:38): 'false' exited with status 1" "$OUT"
[[ $(grep "Error in setup_test_suite(do_test_error_reporting.sh:38): '.*' exited with status 1" "$OUT" | wc -l) = 1 ]]

start_test "The error message should identify the source, line, command and exit code when triggered in setup_test"
! SUBSHELL=never    INLINE=     run_test_script do_test_error_reporting.sh [setup_test] || false
grep "Error in setup_test(do_test_error_reporting.sh:33): 'false' exited with status 1" "$OUT"
[[ $(grep "Error in setup_test(do_test_error_reporting.sh:33): '.*' exited with status 1" "$OUT" | wc -l) = 1 ]]
! SUBSHELL=never    INLINE=true run_test_script do_test_error_reporting.sh [setup_test] || false
grep "Error in setup_test(do_test_error_reporting.sh:33): 'false' exited with status 1" "$OUT"
[[ $(grep "Error in setup_test(do_test_error_reporting.sh:33): '.*' exited with status 1" "$OUT" | wc -l) = 1 ]]

start_test "Teardown semantics should be enforced when both teardown_test and teardon_test_suite fail"
SUBSHELL=never    INLINE=     run_test_script do_test_error_reporting.sh [teardown_test][teardown_test_suite]
# aparente error en bash: el comando reportado pasa a ser '[[ $FAIL_FUNC != $FUNCNAME ]]' en lugar de 'false'
grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT"
grep "Error in teardown_test_suite(do_test_error_reporting.sh:23): '.*' exited with status 1" "$OUT"
[[ $(grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT" | wc -l) = 1 ]]
SUBSHELL=teardown INLINE=     run_test_script do_test_error_reporting.sh [teardown_test][teardown_test_suite]
grep "Error in teardown_test(do_test_error_reporting.sh:18): 'false' exited with status 1" "$OUT"
grep "Error in teardown_test_suite(do_test_error_reporting.sh:23): 'false' exited with status 1" "$OUT"
[[ $(grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT" | wc -l) = 1 ]]
SUBSHELL=always   INLINE=     run_test_script do_test_error_reporting.sh [teardown_test][teardown_test_suite]
grep "Error in teardown_test(do_test_error_reporting.sh:18): 'false' exited with status 1" "$OUT"
grep "Error in teardown_test_suite(do_test_error_reporting.sh:23): 'false' exited with status 1" "$OUT"
[[ $(grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT" | wc -l) = 1 ]]
SUBSHELL=never    INLINE=true run_test_script do_test_error_reporting.sh [teardown_test][teardown_test_suite]
# aparente error en bash: el comando reportado pasa a ser '[[ $FAIL_FUNC != $FUNCNAME ]]' en lugar de 'false'
grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT"
grep "Error in teardown_test_suite(do_test_error_reporting.sh:23): '.*' exited with status 1" "$OUT"
[[ $(grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT" | wc -l) = 2 ]]
SUBSHELL=teardown INLINE=true run_test_script do_test_error_reporting.sh [teardown_test][teardown_test_suite]
grep "Error in teardown_test(do_test_error_reporting.sh:18): 'false' exited with status 1" "$OUT"
grep "Error in teardown_test_suite(do_test_error_reporting.sh:23): 'false' exited with status 1" "$OUT"
[[ $(grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT" | wc -l) = 2 ]]
SUBSHELL=always   INLINE=true run_test_script do_test_error_reporting.sh [teardown_test][teardown_test_suite]
grep "Error in teardown_test(do_test_error_reporting.sh:18): 'false' exited with status 1" "$OUT"
grep "Error in teardown_test_suite(do_test_error_reporting.sh:23): 'false' exited with status 1" "$OUT"
[[ $(grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT" | wc -l) = 2 ]]

start_test "Teardown semantics should be enforced when the test, teardown_test and teardon_test_suite fail"
! SUBSHELL=never    INLINE=     run_test_script do_test_error_reporting.sh [test_01][teardown_test][teardown_test_suite] || false
grep "Error in test_01(do_test_error_reporting.sh:13): 'false' exited with status 1" "$OUT"
# aparente error en bash: el comando reportado pasa a ser '[[ $FAIL_FUNC != $FUNCNAME ]]' en lugar de 'false'
grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT"
grep "Error in teardown_test_suite(do_test_error_reporting.sh:23): '.*' exited with status 1" "$OUT"
[[ $(grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT" | wc -l) = 1 ]]
! SUBSHELL=teardown INLINE=     run_test_script do_test_error_reporting.sh [test_01][teardown_test][teardown_test_suite] || false
grep "Error in test_01(do_test_error_reporting.sh:13): 'false' exited with status 1" "$OUT"
grep "Error in teardown_test(do_test_error_reporting.sh:18): 'false' exited with status 1" "$OUT"
grep "Error in teardown_test_suite(do_test_error_reporting.sh:23): 'false' exited with status 1" "$OUT"
[[ $(grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT" | wc -l) = 1 ]]
! SUBSHELL=always   INLINE=     run_test_script do_test_error_reporting.sh [test_01][teardown_test][teardown_test_suite] || false
grep "Error in test_01(do_test_error_reporting.sh:13): 'false' exited with status 1" "$OUT"
grep "Error in teardown_test(do_test_error_reporting.sh:18): 'false' exited with status 1" "$OUT"
grep "Error in teardown_test_suite(do_test_error_reporting.sh:23): 'false' exited with status 1" "$OUT"
[[ $(grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT" | wc -l) = 1 ]]
! SUBSHELL=never    INLINE=true run_test_script do_test_error_reporting.sh [test_01][teardown_test][teardown_test_suite] || false
grep "Error in test_01(do_test_error_reporting.sh:13): 'false' exited with status 1" "$OUT"
# aparente error en bash: el comando reportado pasa a ser '[[ $FAIL_FUNC != $FUNCNAME ]]' en lugar de 'false'
grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT"
grep "Error in teardown_test_suite(do_test_error_reporting.sh:23): '.*' exited with status 1" "$OUT"
[[ $(grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT" | wc -l) = 1 ]]
! SUBSHELL=teardown INLINE=true run_test_script do_test_error_reporting.sh [test_01][teardown_test][teardown_test_suite] || false
grep "Error in test_01(do_test_error_reporting.sh:13): 'false' exited with status 1" "$OUT"
grep "Error in teardown_test(do_test_error_reporting.sh:18): 'false' exited with status 1" "$OUT"
grep "Error in teardown_test_suite(do_test_error_reporting.sh:23): 'false' exited with status 1" "$OUT"
[[ $(grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT" | wc -l) = 1 ]]
! SUBSHELL=always   INLINE=true run_test_script do_test_error_reporting.sh [test_01][teardown_test][teardown_test_suite] || false
grep "Error in test_01(do_test_error_reporting.sh:13): 'false' exited with status 1" "$OUT"
grep "Error in teardown_test(do_test_error_reporting.sh:18): 'false' exited with status 1" "$OUT"
grep "Error in teardown_test_suite(do_test_error_reporting.sh:23): 'false' exited with status 1" "$OUT"
[[ $(grep "Error in teardown_test(do_test_error_reporting.sh:18): '.*' exited with status 1" "$OUT" | wc -l) = 1 ]]
