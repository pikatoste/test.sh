#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

teardown_test_suite() {
  echo teardown_test_suite
  [[ $command != teardown_test_suite ]] || false
}

teardown_test() {
  echo teardown_test
  [[ $command != teardown_test ]] || false
}

test_01() {
  echo test_01
  true
}

command=$1
run_tests
