func1() {
  [[ $FAIL_FUNC != *\[$FUNCNAME\]* ]] || false
  func2
}

func2() {
  [[ $FAIL_FUNC != *\[$FUNCNAME\]* ]] || false
  func_assert
}

test_01() {
  [[ $FAIL_FUNC != *\[$FUNCNAME\]* ]] || false
  func1
}

teardown_test() {
  [[ $FAIL_FUNC != *\[$FUNCNAME\]* ]] || false
  true
}

teardown_test_suite() {
  [[ $FAIL_FUNC != *\[$FUNCNAME\]* ]] || false
  true
}

func_assert() {
  [[ $FAIL_FUNC != *\[$FUNCNAME\]* ]] || assert_true false
  true
}

setup_test() {
  [[ $FAIL_FUNC != *\[$FUNCNAME\]* ]] || false
  true
}

setup_test_suite() {
  [[ $FAIL_FUNC != *\[$FUNCNAME\]* ]] || false
  true
}

STACK_TRACE=no
PRUNE_PATH='*/'
source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

FAIL_FUNC=$1

if [[ $INLINE ]]; then
  start_test "do_test_error_reporting inline"
  test_01
  start_test "do_test_error_reporting inline maybe not reached"
else
  run_tests
fi
