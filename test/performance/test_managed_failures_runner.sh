#!/bin/bash

@teardown_fixture: {
  assert_failure "[[ a = a ]]"
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
