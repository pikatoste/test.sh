#!/bin/bash

source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "Regression #30: run_test_script() stalls when the there's an error in the function"
assert_failure "run_test_script ./__I_dont_exist__"
