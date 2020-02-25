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

start_test "Exceptions in the catch block should not overwrite the current exception or _TRY_EXIT_CODE"
  try:
    false
  catch:
    try:
      true
    catch: true
    endtry
    assert_equals 0 "$_TRY_EXIT_CODE" "The exit code of the inner try/catch block is wrong"
  endtry
  assert_equals 1 "$_TRY_EXIT_CODE" "The exit code of the outer try/catch block is wrong"

start_test "Exceptions thrown from a catch block should ignore the current exception"
  STACK_TRACE=no generate_test_fail_check 'try: false
  catch: false
  endtry' <<EOF
[test.sh] implicit exception: Error in main(the_test.sh:): 'false' exited with status 1
EOF

start_test "Try blocks that do exit with non-zero with no exit command and no ERR trap, generate exception"

  try:
    set +e
    false
  catch: print_exception
  endtry

start_test "Try blocks that exit do not generate exception and propagate exit"

  assert_failure '
    try:
      exit 1
    catch: print_exception
    endtry' 'Exception caught or zero exit status'

start_test "Nested try/catch blocks do not repeat exceptions if rethrown"
  try:
    try:
      false
    catch: rethrow
    endtry
  catch:
    print_exception
    assert_equals 1 "$(printf "%s\n" "${_EXCEPTION[@]}" | grep Error | wc -l)" "Wrong exception count"
  endtry

start_test "Nested try/catch blocks do not repeat exceptions if uncaught"
  try:
    try:
      throw 'error' "Error"
    catch nonzero: rethrow
    endtry
  catch:
    print_exception
    assert_equals 1 "$(printf "%s\n" "${_EXCEPTION[@]}" | grep Error | wc -l)" "Wrong exception count"
  endtry

start_test "Pending exceptions are not lost"
  try:
    echo -n $(false) $(false)
    false
  catch:
    print_exception
    assert_equals 3 "$(printf "%s\n" "${_EXCEPTION[@]}" | grep Error | wc -l)" "Wrong exception count"
  endtry


start_test "Exceptions in a subshell environment duplicate the exception (undesired feature)"
  try:
    $(false)
  catch:
    print_exception
    assert_equals 2 "$(printf "%s\n" "${_EXCEPTION[@]}" | grep Error | wc -l)" "Wrong exception count"
  endtry

start_test "The catch block can select multiple exceptions"
  try:
    false
  catch error, nonzero:
    print_exception
  endtry
  try:
    throw error "Error"
  catch error, nonzero:
    print_exception
  endtry

start_test "The catch block does not catch non selected exceptions"
  declare_exception pepe
  try: true
    try:
      throw pepe "Pepe"
    catch error, nonzero:
      print_exception
      throw 'test_failed' "Caught non-selected exception"
    endtry
  catch pepe:
    print_exception
  endtry

start_test "Implicit exceptions propagate the type of the existing pending exception"
declare_exception pepe
try:
  try:
    ( throw pepe "Pepe" )
  catch nonzero:
    print_exception
    throw 'test_failed' "Implicit exception did not propagate the pending exception's type"
  endtry
catch pepe:
  echo exception=${_EXCEPTION[-1]}
  print_exception
endtry
