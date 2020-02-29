#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../../test.sh

setup_test() {
  true
}

start_test "Performance inline test 1"
assert_success "[[ a = a ]]"
assert_failure "[[ a = b ]]"
assert_equals a a
