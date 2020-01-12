# TODO: no está incluido en los tests, es un scratch
teardown_test_suite() {
  false
}

test_00() {
  start_test test_00
  true
  true
  false
}

source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

run_tests
