#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

COMPANION_TEST_NAME=do_$(basename "$TEST_SCRIPT")
COMPANION_TEST_SCRIPT=$TEST_SCRIPT_DIR/$COMPANION_TEST_NAME

start_test "#63: run_test_script() interprets relative paths from the current script"
( cd ..; run_test_script $COMPANION_TEST_NAME )
diff - "$LOG_DIR"/"$COMPANION_TEST_NAME".out <<EOF
lorem ipsum
EOF
