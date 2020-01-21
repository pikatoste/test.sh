#!/bin/bash
test_01() {
  assert_true false "test_01"
}

teardown_test() {
  assert_true false "teardown_test"
}

teardown_test_suite() {
  assert_true false "teardown_test_suite"
}

source "$(dirname "$(readlink -f "$0")")"/../test.sh

ignore $(assert_true false "first")
ignore $(assert_true false "second")

run_tests
