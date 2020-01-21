#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "#62: The expression passed to assert_true should reach the evaluation point unchanged when SUBSHELL=always"
SUBSHELL=always
V="'V1 V2'"
assert_true "[[ \"'V1 V2'\" = \"$V\" ]]"

assert_equals "'pepe'" "'pepe'"
assert_equals "'pepe'" "$(echo "'pepe'")"
VAR="pepe"
assert_equals "'pepe'" "$(echo "'$VAR'")"
V=V1
assert_true '[[ V1 =  "$V" ]]'
assert_true "[[ V1 = \"$V\" ]]"
V="V1 V2"
assert_false "[[ V1 = \"$V\" ]]"
unset V
assert_false "[[ V1 = \"$V\" ]]"
V="'V1 V2'"
assert_true "[[ \"'V1 V2'\" = \"$V\" ]]"

start_test "#62: The expression passed to assert_true should reach the evaluation point unchanged when SUBSHELL!=always"
SUBSHELL=never
assert_equals "'pepe'" "'pepe'"
assert_equals "'pepe'" "$(echo "'pepe'")"
VAR="pepe"
assert_equals "'pepe'" "$(echo "'$VAR'")"
V=V1
assert_true '[[ V1 =  "$V" ]]'
assert_true "[[ V1 = \"$V\" ]]"
V="V1 V2"
assert_false "[[ V1 = \"$V\" ]]"
unset V
assert_false "[[ V1 = \"$V\" ]]"
V="'V1 V2'"
assert_true "[[ \"'V1 V2'\" = \"$V\" ]]"
