#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../../test.sh

start_test "Performance inline test 1"
assert_true "[[ a = a ]]"
assert_false "[[ a = b ]]"
assert_equals a a
