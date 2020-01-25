#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "#74: Use TMPDIR for temporary files"
TEST_TMPDIR="$(dirname "$(readlink -f "$0")")"/tmp
mkdir -p "$TEST_TMPDIR"
run_test_script do_test_tmpdir_74.sh
rm -rf "$TEST_TMPDIR"
