#!/bin/bash

FAIL_FAST=1
source "$(dirname "$(readlink -f "$0")")"/../test.sh

@test: "Assertions should not fail when the assertion succeeds"
@body: {
  assert_success "true" "ok"
  assert_failure "false" "nok"
}

@test: "assert_success should fail when the assertion is false"
@body: {
  assert_success "true" "ok"
  assert_success "false" "nok"
}

@test: "assert_failure should fail when the assertion is true"
@body: {
  assert_failure "true" "ok"
  assert_failure "false" "nok"
}

@run_tests
