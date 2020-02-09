#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

OUT="$LOG_DIR"/do_$(basename "$LOG_FILE")

start_test "STACK_TRACE should accept only valid values"
(
  for i in no full; do
    STACK_TRACE=$i load_config
  done
  try: STACK_TRACE=pepe load_config
  catch nonzero: print_exception
  endtry
  failed
)

start_test "When STACK_TRACE=no no stack traces should be produced"
! STACK_TRACE=no run_test_script do_test_STACK_TRACE.sh || false
! grep '[test.sh].*  at ' "$OUT" || false

#start_test "When STACK_TRACE=pruned the stack traces should be truncated before the first test.sh frame"
#! STACK_TRACE=pruned run_test_script do_test_STACK_TRACE.sh || false
#! grep '[test.sh].*  at .*(.*test.sh:[0-9]*)' "$OUT" || false
#
#start_test "When STACK_TRACE=compact the stack traces should not contain frames in test.sh"
#! STACK_TRACE=compact run_test_script do_test_STACK_TRACE.sh || false
#! grep '[test.sh].*  at .*(.*test.sh:[0-9]*)' "$OUT" || false

start_test "When STACK_TRACE=full the stack traces should contain the complete call stack"
! STACK_TRACE=full run_test_script do_test_STACK_TRACE.sh || false
grep '[test.sh].*  at .*(.*test.sh:[0-9]*)' "$OUT" || false
