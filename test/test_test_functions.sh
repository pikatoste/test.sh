source "$(dirname "$(readlink -f "$0")")"/../test.sh

SETUP_TEST_SUITE=${SETUP_TEST_SUITE:-0}
setup_test_suite() {
  SETUP_TEST_SUITE=$(( $SETUP_TEST_SUITE + 1 ))
}

SETUP_TEST=${SETUP_TEST:-0}
setup_test() {
  SETUP_TEST=$(( $SETUP_TEST + 1 ))
}

TEST_01=0
test_01() {
  TEST_01=$(( $TEST_01 + 1 ))
}

TEST_02=0
test_02() {
  TEST_02=$(( $TEST_02 + 1 ))
}

test_03_validate() {
  [ $SETUP_TEST_SUITE -eq 1 ]
  [ $SETUP_TEST -eq 1 ]
  # TODO: validate
#  [ $TEST_01 -eq 1 ]
#  [ $TEST_02 -eq 1 ]
}

display_test_name "run_tests shoud invoke tests and setup methods"
run_tests
