#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

@teardown_once: {
  echo teardown_test_suite
  [[ $command != teardown_test_suite ]] || false
}

@teardown: {
  echo teardown_test
  [[ $command != teardown_test ]] || false
}

@test:
@body: {
  echo test_01
  true
}

command=$1
@run_tests
