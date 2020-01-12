source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

start_test "Files should be included from the default locations"
cp "$TEST_SCRIPT_DIR"/_include_test1.sh "$TEST_SCRIPT_DIR"/../include_test.sh
cp "$TEST_SCRIPT_DIR"/_include_test2.sh "$TEST_SCRIPT_DIR"/include_test.sh
load_includes
include_test1
include_test2
rm "$TEST_SCRIPT_DIR"/../include_test.sh
rm "$TEST_SCRIPT_DIR"/include_test.sh
unset include_test1
unset include_test2

start_test "Files should be included from the default directories with the configured INCLUDE_GLOB"
unset -f include_test1
unset -f include_test2
cp "$TEST_SCRIPT_DIR"/_include_test1.sh "$TEST_SCRIPT_DIR"/../__include_test.sh
cp "$TEST_SCRIPT_DIR"/_include_test2.sh "$TEST_SCRIPT_DIR"/__include_test.sh
INCLUDE_GLOB="__include*.sh"
unset INCLUDE_PATH
load_config
load_includes
include_test1
include_test2
rm "$TEST_SCRIPT_DIR"/../__include_test.sh
rm "$TEST_SCRIPT_DIR"/__include_test.sh
unset include_test1
unset include_test2

start_test "Files should be included from the configured INCLUDE_PATH"
unset -f include_test1
unset -f include_test2
INCLUDE_PATH="$TEST_SCRIPT_DIR/_include*.sh"
load_includes
include_test1
include_test2
unset include_test1
unset include_test2

test_01() {
  true
}

start_test "Included files should not be reported when reincluded"
cp "$TEST_SCRIPT_DIR"/_include_test1.sh "$TEST_SCRIPT_DIR"/../include_test.sh
cp "$TEST_SCRIPT_DIR"/_include_test2.sh "$TEST_SCRIPT_DIR"/include_test.sh
CURRENT_TEST_NAME= subshell run_tests
# TODO: check output
rm "$TEST_SCRIPT_DIR"/../include_test.sh
rm "$TEST_SCRIPT_DIR"/include_test.sh
unset include_test1
unset include_test2
