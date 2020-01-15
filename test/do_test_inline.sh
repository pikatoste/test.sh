source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

setup_test_suite() {
  echo setup_test_suite >>"$OUTFILE"
}

teardown_test_suite() {
  echo teardown_test_suite >>"$OUTFILE"
}

setup_test() {
  echo setup_test >>"$OUTFILE"
}

teardown_test() {
  echo teardown_test >>"$OUTFILE"
}

start_test "do_test_inline ok"

start_test "do_test_inline fail"
false