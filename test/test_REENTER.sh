#!/bin/bash
set -a
CHECK=${CHECK}pass

FAIL_FAST=
SUBSHELL=always
source "$(dirname "$(readlink -f "$0")")"/../test.sh

test_01() {
  true
}

start_test "Subshells should not resource files when REENTER is false"
# TODO: wrong check: runs in subshell
( CURRENT_TEST_NAME= REENTER= run_tests 3>&1 )
assert_true '[[ $CHECK = pass ]]'

start_test "Errors in subshells when REENTER is false should generate stack traces"
! COLOR=no run_test_script do_test_REENTER.sh || { COLOR=yes; false; }
COLOR=yes
OUT=$LOG_DIR/do_test_REENTER.sh.out
grep "(environment:0)" "$OUT"
OUT2="$TEST_SCRIPT_DIR"/.do_test_REENTER.out
sed -e 's/^\(.*\)(.*)\(.*\)$/\1()\2/' "$OUT" >"$OUT2"
diff - "$OUT2" <<OUT
[test.sh] FAILED: test_01
[test.sh] Error in test_01(): 'false' exited with status 1
[test.sh]  at run_test()
[test.sh]  at source()
[test.sh]  at main()
[test.sh]  at subshell()
[test.sh]  at run_tests()
[test.sh]  at main()
[test.sh] Error in run_tests(): '[[ \$failures == 0 ]]' exited with status 1
[test.sh]  at main()
OUT
