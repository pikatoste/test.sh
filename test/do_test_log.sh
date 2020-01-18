#!/bin/bash
TEST_SCRIPT="$(readlink -f "$0")"
TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
source "$TEST_SCRIPT_DIR"/../test.sh

start_test "passing test"
echo output
echo stderr >&2

start_test "failing test"
false
