#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "#62: The expression passed to assert_success should reach the evaluation point unchanged"
  assert_equals "'pepe'" "'pepe'"
  assert_equals "'pepe'" "$(echo "'pepe'")"
  VAR="pepe"
  assert_equals "'pepe'" "$(echo "'$VAR'")"
  V=V1
  assert_success '[[ V1 =  "$V" ]]'
  assert_success "[[ V1 = \"$V\" ]]"
  V="V1 V2"
  assert_failure "[[ V1 = \"$V\" ]]"
  unset V
  assert_failure "[[ V1 = \"$V\" ]]"
  V="'V1 V2'"
  assert_success "[[ \"'V1 V2'\" = \"$V\" ]]"
