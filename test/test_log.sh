source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

set_test_name "The log file should contain test stdout and stderr"
# run in a different test script to avoid the race condition on the log output
CURRENT_TEST_NAME= "$TEST_SCRIPT_DIR"/do_test_log.sh

grep ^output$ "$(dirname "$TESTOUT_FILE")"/do_test_log.sh.out
grep ^stderr$ "$(dirname "$TESTOUT_FILE")"/do_test_log.sh.out
