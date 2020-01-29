#!/bin/bash

source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "Regression #31: double error reporting"
assert_equals "$(false)" ""
assert_false "run_test_script ./__I_dont_exist" && print_stack_trace
# TODO: check output
