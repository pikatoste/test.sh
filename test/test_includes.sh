#!/bin/bash

SUBSHELL=never
source "$(dirname "$(readlink -f "$0")")"/../test.sh

setup_test() {
  unset -f include_test1
  unset -f include_test2
  cp "$TEST_SCRIPT_DIR"/files/_include_test1.sh "$TESTSH_DIR"/${SETUP_PREFIX}include_test.sh
  cp "$TEST_SCRIPT_DIR"/files/_include_test2.sh "$TEST_SCRIPT_DIR"/${SETUP_PREFIX}include_test.sh
}

teardown_test() {
  rm "$TESTSH_DIR"/${TEARDOWN_PREFIX}include_test.sh
  rm "$TEST_SCRIPT_DIR"/${TEARDOWN_PREFIX}include_test.sh
  unset include_test1
  unset include_test2
}

start_test "Files should be included from the default locations"
load_includes
include_test1
include_test2

SETUP_PREFIX=__
start_test "Files should be included from the default directories with the configured INCLUDE_GLOB"
INCLUDE_GLOB="__include*.sh"
unset INCLUDE_PATH
load_config
load_includes
include_test1
include_test2

TEARDOWN_PREFIX=$SETUP_PREFIX
SETUP_PREFIX=xx_
start_test "Files should be included from the configured INCLUDE_PATH"
INCLUDE_PATH="$TEST_SCRIPT_DIR"/files/_include*.sh
load_includes
include_test1
include_test2

TEARDOWN_PREFIX=$SETUP_PREFIX
start_test "Included files should not be reported when reincluded"
INCLUDE_PATH="$TEST_SCRIPT_DIR"/files/_include*.sh run_test_script "$TEST_SCRIPT_DIR"/do_test_includes.sh
OUT="$TEST_SCRIPT_DIR"/testout/do_test_includes.sh.out
assert_equals 2 "$(grep "\[test.sh\].* Included:" "$OUT" | wc -l)" "wrong count"
