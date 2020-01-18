#!/bin/bash
test_01() {
  start_test "test_01"
  false
}

test_02() {
  start_test "test_02"
  true
}

source "$(dirname "$(readlink -f "$0")")"/../test.sh

run_tests
