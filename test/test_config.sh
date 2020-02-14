#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

FILES_DIR=$TEST_SCRIPT_DIR/files

start_test "The configuration file should be loaded from the default location"
  unset VERBOSE
  unset INCLUDE_GLOB
  unset INCLUDE_PATH
  unset CONFIG_FILE
  cp "$FILES_DIR"/test.sh.config.default "$TESTSH_DIR"/test.sh.config
  TEST_SCRIPT_DIR="$TESTSH_DIR" load_config
  rm "$TESTSH_DIR"/test.sh.config
  [ "$VERBOSE" = 0 ]
  [ "$INCLUDE_GLOB" = "*" ]
  [ "$INCLUDE_PATH" = default ]

start_test "The configuration file should be loaded from CONFIG_FILE"
  unset VERBOSE
  unset INCLUDE_GLOB
  unset INCLUDE_PATH
  unset CONFIG_FILE
  CONFIG_FILE="$FILES_DIR"/test.sh.config.FILE
  load_config
  [ "$VERBOSE" = 0 ]
  [ "$INCLUDE_GLOB" = "*" ]
  [ "$INCLUDE_PATH" = CONFIG_FILE ]

start_test "The configuration file should be loaded from CONFIG_PATH"
  unset VERBOSE
  unset INCLUDE_GLOB
  unset INCLUDE_PATH
  unset CONFIG_FILE
  cp "$FILES_DIR"/test.sh.config.DIR "$TEST_TMP"/test.sh.config
  TEST_SCRIPT_DIR="$TEST_TMP" load_config
  rm "$TEST_TMP"/test.sh.config
  [ "$VERBOSE" = 0 ]
  [ "$INCLUDE_GLOB" = "*" ]
  [ "$INCLUDE_PATH" = CONFIG_DIR ]

start_test "Configuration variables in the environment should be respected"
  VERBOSE=verbose
  INCLUDE_GLOB=include_glob
  INCLUDE_PATH=include_path
  unset CONFIG_FILE
  load_config
  [ "$VERBOSE" = verbose ]
  [ "$INCLUDE_GLOB" = include_glob ]
  [ "$INCLUDE_PATH" = include_path ]

start_test "Configuration variables in the environment should override the configuration file"
  VERBOSE=verbose
  INCLUDE_GLOB=include_glob
  INCLUDE_PATH=include_path
  unset CONFIG_FILE
  CONFIG_FILE="$FILES_DIR"/test.sh.config.default
  load_config
  [ "$VERBOSE" = verbose ]
  [ "$INCLUDE_GLOB" = include_glob ]
  [ "$INCLUDE_PATH" = include_path ]

start_test "Empty variables should be respected over defaults"
  INCLUDE_GLOB=
  unset CONFIG_FILE
  load_config
  [ "$INCLUDE_GLOB" = "" ]

start_test "Empty variables should be respected over configuration file"
  FAIL_FAST=
  unset CONFIG_FILE
  CONFIG_FILE="$FILES_DIR"/test.sh.config.default
  load_config
  [ "$FAIL_FAST" = "" ]
