#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

@setup_once: {
  echo setup_test_suite >>"$OUTFILE"
}

@teardown_once: {
  echo teardown_test_suite >>"$OUTFILE"
}

@setup: {
  echo setup_test >>"$OUTFILE"
}

@teardown: {
  echo teardown_test >>"$OUTFILE"
}

[ "$1" != fail ] || false

start_test "do_test_inline ok"

start_test "do_test_inline fail"
false
