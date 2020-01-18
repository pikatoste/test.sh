#!/bin/bash
teardown_test_suite() {
  false
}

teardown_test() {
  false
}

test_01() {
  true
}

source "$(dirname "$(readlink -f "$0")")"/../test.sh

run_tests
