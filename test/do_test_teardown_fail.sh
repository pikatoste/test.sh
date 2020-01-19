#!/bin/bash
teardown_test_suite() {
  false
  echo "ERROR: never reached"
}

teardown_test() {
  false
  echo "ERROR: never reached"
}

test_01() {
  true
}

source "$(dirname "$(readlink -f "$0")")"/../test.sh

run_tests
