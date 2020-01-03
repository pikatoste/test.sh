TEST_SCRIPT="$(readlink -f "$0")"
TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
source "$TEST_SCRIPT_DIR"/../test.sh

set_test_name "The log file should contain test stdout and stderr"
"$TEST_SCRIPT_DIR"/do_test_log.sh
#echo output
#echo stderr >&2

# Allow for the log file writer subprocess to do its job
#sleep 1
grep ^output$ "$(dirname "$TESTOUT_FILE")"/do_test_log.sh.out
grep ^stderr$ "$(dirname "$TESTOUT_FILE")"/do_test_log.sh.out
