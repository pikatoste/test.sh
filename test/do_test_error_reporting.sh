func1() {
  [[ $FAIL_FUNC != $FUNCNAME ]] || false
  func2
}

func2() {
  [[ $FAIL_FUNC != $FUNCNAME ]] || false
  func_assert
}

test_01() {
  [[ $FAIL_FUNC != $FUNCNAME ]] || false
  func1
}

teardown_test() {
  [[ $FAIL_FUNC != $FUNCNAME ]] || false
}

teardown_test_suite() {
  [[ $FAIL_FUNC != $FUNCNAME ]] || false
}

func_assert() {
  [[ $FAIL_FUNC != $FUNCNAME ]] || assert_true false
}

source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

FAIL_FUNC=$1

if [[ $INLINE ]]; then
  start_test "do_test_error_reporting inline"
  test_01
  start_test "do_test_error_reporting inline maybe not reached"
else
  run_tests
fi
