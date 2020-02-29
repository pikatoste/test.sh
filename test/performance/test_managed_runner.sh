#!/bin/bash

@setup: {
  true
}

@test: "Performance managed test 1"
@body: {
  assert_success "[[ a = a ]]"
  assert_failure "[[ a = b ]]"
  assert_equals a a
}
