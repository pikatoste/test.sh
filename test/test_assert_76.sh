#!/bin/bash

source "$(dirname "$(readlink -f "$0")")"/../test.sh

my_func() {
  echo called >"$OUT"
}

OUT="$TEST_SCRIPT_DIR"/.test_assert_76.out

start_test "#76: assert_equals never evaluates its arguments"
  rm -f "$OUT"
  assert_equals my_func my_func
  [[ ! -f "$OUT" ]]
  echo -n $(assert_equals zzz my_func)
  rm -f "$_EXCEPTIONS_FILE"
  [[ ! -f "$OUT" ]]
  echo -n $(assert_equals my_func zzz)
  rm -f "$_EXCEPTIONS_FILE"
  [[ ! -f "$OUT" ]]
  assert_equals "\""'$(ls|wc -l)' "\""'$(ls|wc -l)'

start_test "#76: failures in assertion functions don't reevaluate the expression"
  rm -f "$OUT"
  try: assert_success "! my_func"
  catch: print_exception
  endtry
  diff - "$OUT" <<EOF
called
EOF

  rm -f "$OUT"
  try: assert_failure 'my_func'
  catch: print_exception
  endtry
  diff - "$OUT" <<EOF
called
EOF
