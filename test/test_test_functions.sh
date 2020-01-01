source "$(dirname "$(readlink -f "$0")")"/../test.sh

setup_test_suite() {
  echo setup_test_suite
}

teardown_test_suite() {
  echo teardown_test_suite
}

setup_test() {
  echo setup_test
}

teardown_test() {
  echo teardown_test
}

test_01() {
  [ -z "$test_01_fail" ]
  echo test_01
}

test_02() {
  [ -z "$test_02_fail" ]
  echo test_02
}

display_test_name "run_tests shoud invoke tests and setup methods when there are no failures"
run_tests

cat >test.out.expected <<EOF
setup_test_suite
setup_test
test_01
teardown_test
setup_test
test_02
teardown_test
teardown_test_suite
EOF
grep -v run_tests "$TESTOUT_FILE" | diff - test.out.expected

display_test_name "run_tests shoud invoke tests and setup methods when there are failures"
test_02_fail=1
! bash -c run_tests

cat >>test.out.expected <<EOF
setup_test_suite
setup_test
test_01
teardown_test
setup_test
teardown_test
teardown_test_suite
EOF
grep -v run_tests "$TESTOUT_FILE" | diff - test.out.expected
