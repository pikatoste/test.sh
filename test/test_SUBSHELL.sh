FAIL_FAST=
source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

set_test_name "SUBSHELL should default to 'always' when not FAIL_FAST"
[[ $SUBSHELL = always ]]
FAIL_FAST=1

set_test_name "SUBSHELL should accept only valid values"
for i in never teardown always; do
  SUBSHELL=$i load_config
done
! CURRENT_TEST_NAME= SUBSHELL=pepe "$TEST_SCRIPT_DIR"/do_test_SUBSHELL.sh

set_test_name "When SUBSHELL=never teardown functions should be called"
CURRENT_TEST_NAME= SUBSHELL=never "$TEST_SCRIPT_DIR"/do_test_SUBSHELL.sh
OUTFILE="$TESTOUT_DIR"/do_test_SUBSHELL.sh.out
diff - "$OUTFILE" <<EOF
test_01
teardown_test
teardown_test_suite
EOF

set_test_name "When SUBSHELL=never a failure in teardown_test should terminate the test with failure"
! CURRENT_TEST_NAME= SUBSHELL=never "$TEST_SCRIPT_DIR"/do_test_SUBSHELL.sh teardown_test
OUTFILE="$TESTOUT_DIR"/do_test_SUBSHELL.sh.out
OUTFILE2="$TEST_SCRIPT_DIR"/.do_test_SUBSHELL.out
grep -v '\[test\.sh\]' "$OUTFILE" >"$OUTFILE2"
diff - "$OUTFILE2" <<EOF
test_01
teardown_test
teardown_test_suite
EOF
rm "$OUTFILE2"

set_test_name "When SUBSHELL=never a failure in teardown_test_suite should terminate the test with failure"
! CURRENT_TEST_NAME= SUBSHELL=never "$TEST_SCRIPT_DIR"/do_test_SUBSHELL.sh teardown_test_suite
OUTFILE="$TESTOUT_DIR"/do_test_SUBSHELL.sh.out
OUTFILE2="$TEST_SCRIPT_DIR"/.do_test_SUBSHELL.out
grep -v '\[test\.sh\]' "$OUTFILE" >"$OUTFILE2"
diff - "$OUTFILE2" <<EOF
test_01
teardown_test
teardown_test_suite
EOF
rm "$OUTFILE2"

set_test_name "When SUBSHELL=teardown teardown functions should be called"
CURRENT_TEST_NAME= SUBSHELL=teardown "$TEST_SCRIPT_DIR"/do_test_SUBSHELL.sh
OUTFILE="$TESTOUT_DIR"/do_test_SUBSHELL.sh.out
diff - "$OUTFILE" <<EOF
test_01
teardown_test
teardown_test_suite
EOF

set_test_name "When SUBSHELL=teardown a failure in teardown_test should not terminate the test with failure"
CURRENT_TEST_NAME= SUBSHELL=teardown "$TEST_SCRIPT_DIR"/do_test_SUBSHELL.sh teardown_test
OUTFILE="$TESTOUT_DIR"/do_test_SUBSHELL.sh.out
OUTFILE2="$TEST_SCRIPT_DIR"/.do_test_SUBSHELL.out
grep -v '\[test\.sh\]' "$OUTFILE" >"$OUTFILE2"
diff - "$OUTFILE2" <<EOF
test_01
teardown_test
teardown_test_suite
EOF
rm "$OUTFILE2"

set_test_name "When SUBSHELL=teardown a failure in teardown_test_suite should not terminate the test with failure"
CURRENT_TEST_NAME= SUBSHELL=teardown "$TEST_SCRIPT_DIR"/do_test_SUBSHELL.sh teardown_test_suite
OUTFILE="$TESTOUT_DIR"/do_test_SUBSHELL.sh.out
OUTFILE2="$TEST_SCRIPT_DIR"/.do_test_SUBSHELL.out
grep -v '\[test\.sh\]' "$OUTFILE" >"$OUTFILE2"
diff - "$OUTFILE2" <<EOF
test_01
teardown_test
teardown_test_suite
EOF
rm "$OUTFILE2"
