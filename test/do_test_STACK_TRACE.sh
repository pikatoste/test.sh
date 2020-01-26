#!/bin/bash

FAIL_FAST=
source "$(dirname "$(readlink -f "$0")")"/../test.sh

func1() {
  func2
}

func2() {
  false
}

test_01() {
  func1
}

run_tests
