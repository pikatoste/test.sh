#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../../test.sh

@teardown_once: {
  assert_failure "[[ a = a ]]"
}

@setup: {
  true
}

@teardown: {
  assert_failure "[[ b = b ]]"
}

@test: "Performance managed fail test"
@body: {
  assert_success "[[ a = a ]]"
  assert_failure "[[ a = b ]]"
  assert_equals a a
  assert_equals a b
}

@run_tests
