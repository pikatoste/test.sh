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

start_test "Nested try/catch blocks do not repeat exceptions if rethrown"
  try:
    try:
      false
    catch: rethrow
    endtry
  catch:
    print_exception
    assert_equals 1 "$(echo "$EXCEPTION" | grep Error | wc -l)" "Wrong exception count"
  endtry

start_test "Nested try/catch blocks do not repeat exceptions if uncaught"
  try:
    try:
      throw 'error' "Error"
    catch nonzero: rethrow
    endtry
  catch:
    print_exception
    assert_equals 1 "$(echo "$EXCEPTION" | grep Error | wc -l)" "Wrong exception count"
  endtry

start_test "Pending exceptions are not lost"
  try:
    echo -n $(false) $(false)
    false
  catch:
    print_exception
    assert_equals 3 "$(echo "$EXCEPTION" | grep Error | wc -l)" "Wrong exception count"
  endtry


start_test "Exceptions in a subshell environment duplicate the exception (undesired feature)"
  try:
    $(false)
  catch:
    print_exception
    assert_equals 2 "$(echo "$EXCEPTION" | grep Error | wc -l)" "Wrong exception count"
  endtry
