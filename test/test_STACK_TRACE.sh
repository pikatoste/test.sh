source "$(dirname "$(readlink -f "$0")")"/../test.sh

OUT="$TESTOUT_DIR"/do_$(basename "$TESTOUT_FILE")

start_test "STACK_TRACE should accept only valid values"
for i in no pruned compact full; do
  STACK_TRACE=$i load_config
done
! STACK_TRACE=pepe load_config || false

start_test "When STACK_TRACE=no no stack traces should be produced"
! CURRENT_TEST_NAME= STACK_TRACE=no "$TEST_SCRIPT_DIR"/do_test_STACK_TRACE.sh || false
! grep '[test.sh].*  at ' "$OUT" || false

start_test "When STACK_TRACE=pruned the stack traces should be truncated before the first test.sh frame"
! CURRENT_TEST_NAME= STACK_TRACE=pruned "$TEST_SCRIPT_DIR"/do_test_STACK_TRACE.sh || false
! grep '[test.sh].*  at .*(.*test.sh:[0-9]*)' "$OUT" || false

start_test "When STACK_TRACE=compact the stack traces should not contain frames in test.sh"
! CURRENT_TEST_NAME= STACK_TRACE=compact "$TEST_SCRIPT_DIR"/do_test_STACK_TRACE.sh || false
! grep '[test.sh].*  at .*(.*test.sh:[0-9]*)' "$OUT" || false

start_test "When STACK_TRACE=full the stack traces should contain the complete call stack"
! CURRENT_TEST_NAME= STACK_TRACE=full "$TEST_SCRIPT_DIR"/do_test_STACK_TRACE.sh || false
grep '[test.sh].*  at .*(.*test.sh:[0-9]*)' "$OUT" || false
