test_01() {
  set_test_name "test_01"
  false
}

test_02() {
  set_test_name "test_02"
  true
}

source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

! subshell "FAIL_FAST=1 SUBSHELL=always run_tests"
# TODO: verify that the [ignored] line is printed
