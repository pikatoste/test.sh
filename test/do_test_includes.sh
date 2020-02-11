#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

@test:
@body: {
  true
}

@run_tests
