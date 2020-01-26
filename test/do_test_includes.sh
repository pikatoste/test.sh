#!/bin/bash

source "$(dirname "$(readlink -f "$0")")"/../test.sh

test_01() {
  true
}

run_tests
