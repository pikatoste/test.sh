# TODO: no está incluido en los tests, es un scratch
teardown_test_suite() {
  false
}

test_00() {
  set_test_name test_00
  true
  true
  false
}

[ "$REENTRANT" != 1 ] || return 0
TEST_SCRIPT=${TEST_SCRIPT:-"$(readlink -f "$0")"}
TEST_SCRIPT_DIR=${TEST_SCRIPT_DIR:-$(dirname "$TEST_SCRIPT")}
source "$TEST_SCRIPT_DIR"/../test.sh #|| return 0 #"$1"

run_tests
