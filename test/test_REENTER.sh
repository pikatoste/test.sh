FAIL_FAST=
SUBSHELL=always
source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

test_01() {
  true
}

start_test "Subshells should not resource files when REENTER is false"
CURRENT_TEST_NAME= REENTER= run_tests
# TODO: check ... something
