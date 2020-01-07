TEST_SCRIPT="$(readlink -f "$0")"
TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
"$TEST_SCRIPT_DIR"/../test.sh
# TODO: check output
