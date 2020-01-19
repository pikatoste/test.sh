#!/bin/bash
SUBSHELL=always
REENTER=false
source "$(dirname "$(readlink -f "$0")")"/../test.sh

test_01() {
  false
}

run_tests
