generate_test() {
  THE_TEST_NAME=do_test_assert.sh
  THE_TEST=$TEST_TMP/$THE_TEST_NAME
  mkdir -p "$TEST_TMP"
  cat >"$THE_TEST" <<EOF
source "$TESTSH"
$1
EOF
  chmod a+x "$THE_TEST"
  OUT=$THE_TEST.out
}

check_output() {
  sed -i -e 's/\([ :]\)[0-9]\+\([:)]\)/\1\2/' "$OUT"
  cat >"$TEST_TMP"/expected
  diff "$TEST_TMP"/expected "$OUT"
}

test_generate_fail_check() {
  generate_test "$1"
  ! LC_ALL=C LOG_FILE="$OUT" COLOR=no run_test_script "$THE_TEST" || false
  check_output
}

test_generate_success_check() {
  generate_test "$1"
  LC_ALL=C LOG_FILE="$OUT" COLOR=no run_test_script "$THE_TEST"
  check_output
}
