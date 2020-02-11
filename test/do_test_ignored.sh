#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

@test: "test_01"
@body: {
  false
}

@test: "test_02"
@body: {
  true
}

@run_tests
