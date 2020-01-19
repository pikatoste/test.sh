#!/bin/bash

SUBSHELL=never
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "Regression #30: run_test_script() stalls when the there's an error in the function"
! subshell "run_test_script ./__I_dont_exist__" || false