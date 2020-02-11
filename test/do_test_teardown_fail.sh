#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

@teardown_fixture: {
  false
  echo "ERROR: never reached"
}

@teardown: {
  false
  echo "ERROR: never reached"
}

@test:
@body: {
  true
}

@run_tests
