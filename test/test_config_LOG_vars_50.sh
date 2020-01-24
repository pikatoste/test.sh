#!/bin/bash

source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "LOG_DIR_NANME"
run_test_script do_test_config_LOG_vars.sh "LOG_DIR_NAME=config_LOG_vars"
LOG=$TEST_SCRIPT_DIR/config_LOG_vars/do_test_config_LOG_vars.sh.out
diff - "$LOG" <<EOF
lorem ipsum
EOF
rm "$LOG"

start_test "LOG_DIR"
run_test_script do_test_config_LOG_vars.sh 'LOG_DIR="$TEST_SCRIPT_DIR"/config_LOG_vars'
LOG=$TEST_SCRIPT_DIR/config_LOG_vars/do_test_config_LOG_vars.sh.out
diff - "$LOG" <<EOF
lorem ipsum
EOF
rm "$LOG"

start_test "LOG_NAME"
run_test_script do_test_config_LOG_vars.sh 'LOG_NAME=config_LOG_vars.log'
LOG=$TEST_SCRIPT_DIR/$LOG_DIR_NAME/config_LOG_vars.log
diff - "$LOG" <<EOF
lorem ipsum
EOF
rm "$LOG"

start_test "LOG_FILE"
run_test_script do_test_config_LOG_vars.sh "LOG_FILE=${TMPDIR:-/tmp}/config_LOG_vars.log"
LOG=${TMPDIR:-/tmp}/config_LOG_vars.log
diff - "$LOG" <<EOF
lorem ipsum
EOF
rm "$LOG"

start_test "LOG_MODE"
run_test_script do_test_config_LOG_vars.sh 'LOG_MODE=overwrite'
LOG=$TEST_SCRIPT_DIR/testout/do_test_config_LOG_vars.sh.out
diff - "$LOG" <<EOF
lorem ipsum
EOF
run_test_script do_test_config_LOG_vars.sh 'LOG_MODE=append'
diff - "$LOG" <<EOF
lorem ipsum
lorem ipsum
EOF
rm "$LOG"
