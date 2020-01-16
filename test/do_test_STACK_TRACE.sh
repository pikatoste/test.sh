func1() {
  func2
}

func2() {
  false
}

test_01() {
  func1
}

FAIL_FAST=
SUBSHELL=always
source "$(dirname "$(readlink -f "$0")")"/../test.sh

run_tests
