#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

FILES_DIR=$TEST_SCRIPT_DIR/files
COMPANION_TEST=do_$(basename "$TEST_SCRIPT")
COMPANION_TEST_OUT=$TEST_SCRIPT_DIR/testout/$(basename "$COMPANION_TEST").out

start_test "#63: run_test_script() interprets relative paths from the current script"
( cd ..; run_test_script "$COMPANION_TEST" )
diff - "$COMPANION_TEST_OUT" <<EOF
lorem ipsum
EOF
