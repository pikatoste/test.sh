#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "#74: Use TMPDIR for temporary files"
export TEST_TMPDIR="$(dirname "$(readlink -f "$0")")"/tmp

mkdir -p "$TEST_TMPDIR"
VERBOSE= run_test_script do_test_tmpdir_74.sh 1
rm -rf "$TEST_TMPDIR"

mkdir -p "$TEST_TMPDIR"
VERBOSE=1 run_test_script do_test_tmpdir_74.sh 2
rm -rf "$TEST_TMPDIR"
