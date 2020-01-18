#!/bin/bash

test_01() {
  true
}

SUBSHELL=always
REENTER=1
source "$(dirname "$(readlink -f "$0")")"/../test.sh

run_tests
