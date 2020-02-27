#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

OUT="$LOG_DIR"/do_$(basename "$LOG_FILE")

@test: "STACK_TRACE should accept only valid values"
@body: {
  for i in no full; do
    STACK_TRACE=$i load_config
  done
  try:
    STACK_TRACE=pepe load_config
  catch:
    if exception_is 'configuration'; then
      log_ok "Expected exception:"
      print_exception 'log_ok'
    else
      rethrow
    fi
  endtry
}

@test: "When STACK_TRACE=no no stack traces should be produced"
@body: {
  assert_failure 'STACK_TRACE=no run_test_script do_test_config_STACK_TRACE.sh'
  assert_failure "grep '[test.sh].*  at ' \"$OUT\""
}

@skip @test: "When STACK_TRACE=pruned the stack traces should be truncated before the first test.sh frame"
@body: {
  assert_failure 'STACK_TRACE=pruned run_test_script do_test_config_STACK_TRACE.sh'
  ! grep '[test.sh].*  at .*(.*test.sh:[0-9]*)' "$OUT" || false
}

@skip @test: "When STACK_TRACE=compact the stack traces should not contain frames in test.sh"
@body: {
  assert_failure 'STACK_TRACE=compact run_test_script do_test_config_STACK_TRACE.sh'
  ! grep '[test.sh].*  at .*(.*test.sh:[0-9]*)' "$OUT" || false
}

@test: "When STACK_TRACE=full the stack traces should contain the complete call stack"
@body: {
  assert_failure 'STACK_TRACE=full run_test_script do_test_config_STACK_TRACE.sh'
  assert_success "grep '[test.sh].*  at .*(.*test.sh:[0-9]*)' \"$OUT\""
}

@run_tests
