FAIL_FAST=
SUBSHELL=always
source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

test_01() {
  true
}

start_test "Test config REENTER=0"
CURRENT_TEST_NAME= REENTER=0 run_tests
# TODO: check ... something
