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
source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

run_tests
