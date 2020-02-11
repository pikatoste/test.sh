#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

FILES_DIR=$TEST_SCRIPT_DIR/files
COMPANION_TEST_NAME=do_$(basename "$TEST_SCRIPT")

# TODO: valida el contenido de las stack traces, esto debería hacerlo el test de stack traces
# TODO: usar parser para validar log
start_test "#71: Assertion failures should not disable further error reporting"
  ( ! PRUNE_PATH="*/" COLOR=no run_test_script "$COMPANION_TEST_NAME" || false )
  EXPECTED_OUT=$FILES_DIR/do_test_assert_71.out
  CURRENT_OUT=$TEST_SCRIPT_DIR/testout/do_test_assert_71.sh.out
  sed -e 's/:[0-9]*)/:)/' "$CURRENT_OUT" | diff "$EXPECTED_OUT" -
