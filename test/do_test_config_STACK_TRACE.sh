#!/bin/bash

FAIL_FAST=
source "$(dirname "$(readlink -f "$0")")"/../test.sh

func1() {
  func2
}

func2() {
  false
}

@test:
@body: {
  func1
}

@run_tests
