source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

start_test "The configuration file should be loaded from the default location"
unset VERBOSE
unset INCLUDE_GLOB
unset INCLUDE_PATH
unset CONFIG_FILE
unset CONFIG_DIR
cp "$TEST_SCRIPT_DIR"/test.sh.config.default "$TEST_SCRIPT_DIR"/../test.sh.config
load_config
rm "$TEST_SCRIPT_DIR"/../test.sh.config
[ "$VERBOSE" = 0 ]
[ "$INCLUDE_GLOB" = "*" ]
[ "$INCLUDE_PATH" = default ]

start_test "The configuration file should be loaded from CONFIG_FILE"
unset VERBOSE
unset INCLUDE_GLOB
unset INCLUDE_PATH
unset CONFIG_FILE
unset CONFIG_DIR
CONFIG_FILE="$TEST_SCRIPT_DIR"/test.sh.config.FILE
load_config
[ "$VERBOSE" = 0 ]
[ "$INCLUDE_GLOB" = "*" ]
[ "$INCLUDE_PATH" = CONFIG_FILE ]

start_test "The configuration file should be loaded from CONFIG_DIR"
unset VERBOSE
unset INCLUDE_GLOB
unset INCLUDE_PATH
unset CONFIG_FILE
unset CONFIG_DIR
cp "$TEST_SCRIPT_DIR"/test.sh.config.DIR "$TEST_SCRIPT_DIR"/test.sh.config
load_config
rm "$TEST_SCRIPT_DIR"/test.sh.config
[ "$VERBOSE" = 0 ]
[ "$INCLUDE_GLOB" = "*" ]
[ "$INCLUDE_PATH" = CONFIG_DIR ]

start_test "Configuration variables in the environment should be respected"
VERBOSE=verbose
INCLUDE_GLOB=include_glob
INCLUDE_PATH=include_path
unset CONFIG_FILE
unset CONFIG_DIR
load_config
[ "$VERBOSE" = verbose ]
[ "$INCLUDE_GLOB" = include_glob ]
[ "$INCLUDE_PATH" = include_path ]

start_test "Configuration variables in the environment should override the configuration file"
VERBOSE=verbose
INCLUDE_GLOB=include_glob
INCLUDE_PATH=include_path
unset CONFIG_FILE
unset CONFIG_DIR
CONFIG_FILE="$TEST_SCRIPT_DIR"/test.sh.config.default
load_config
[ "$VERBOSE" = verbose ]
[ "$INCLUDE_GLOB" = include_glob ]
[ "$INCLUDE_PATH" = include_path ]

start_test "Empty variables should be respected over defaults"
FAIL_FAST=
unset CONFIG_FILE
unset CONFIG_DIR
load_config
[ "$FAIL_FAST" = "" ]

start_test "Empty variables should be respected over configuration file"
FAIL_FAST=
unset CONFIG_FILE
unset CONFIG_DIR
CONFIG_FILE="$TEST_SCRIPT_DIR"/test.sh.config.default
load_config
[ "$FAIL_FAST" = "" ]
