#!/bin/bash
INCLUDE_GLOB="include/*.sh"
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "Exceptions should be caugh in the catch block"
  CAUGHT=
  try:
    false
  catch:
    CAUGHT=1
  endtry
  assert_equals 1 "$CAUGHT" "The catch block has not been executed"

start_test "Exceptions in the catch block should not overwrite the current exception or TRY_EXIT_CODE"
  try:
    false
  catch:
    try:
      true
    catch: true
    endtry
    assert_equals 0 "$TRY_EXIT_CODE" "The exit code of the inner try/catch block is wrong"
  endtry
  assert_equals 1 "$TRY_EXIT_CODE" "The exit code of the outer try/catch block is wrong"

start_test "Exceptions thrown from a catch block should ignore the current exception"
  STACK_TRACE=no generate_test_fail_check 'try: false
  catch: false
  endtry' <<EOF
[test.sh] Error in main(the_test.sh:): 'false' exited with status 1
EOF

start_test "Try blocks that exit but not throw generate exception"
  try:
    exit 1
  catch: print_exception
  endtry
