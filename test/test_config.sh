[ "$REENTRANT" != 1 ] || return 0
TEST_SCRIPT="$(readlink -f "$0")"
TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
source "$TEST_SCRIPT_DIR"/../test.sh

set_test_name "The configuration file should be loaded from the default location"
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

set_test_name "The configuration file should be loaded from CONFIG_FILE"
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

set_test_name "Configuration file should be loaded from CONFIG_DIR"
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

set_test_name "Configuration through environment variables should be respected"
VERBOSE=verbose
INCLUDE_GLOB=include_glob
INCLUDE_PATH=include_path
unset CONFIG_FILE
unset CONFIG_DIR
load_config
[ "$VERBOSE" = verbose ]
[ "$INCLUDE_GLOB" = include_glob ]
[ "$INCLUDE_PATH" = include_path ]

set_test_name "Configuration through environment variables should override the configuration file"
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
