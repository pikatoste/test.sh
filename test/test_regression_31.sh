#!/bin/bash
INCLUDE_GLOB="include/*.sh"
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "Regression #31: double error reporting"

generate_test_fail_check 'assert_equals "$(false)" ""' <<EOF
[test.sh] An exception occurred before entering the 'try' block
[test.sh]  at try(test.sh:)
[test.sh]  at assert_equals(test.sh:)
[test.sh]  at main(the_test.sh:)
[test.sh] Caused by:
[test.sh] Error in main(the_test.sh:): 'false' exited with status 1
EOF

generate_test_fail_check 'assert_equals "$(false)" "a"' <<EOF
[test.sh] An exception occurred before entering the 'try' block
[test.sh]  at try(test.sh:)
[test.sh]  at assert_equals(test.sh:)
[test.sh]  at main(the_test.sh:)
[test.sh] Caused by:
[test.sh] Error in main(the_test.sh:): 'false' exited with status 1
EOF

generate_test_fail_check 'run_test_script ./__I_dont_exist' <<EOF
$TESTSH: line : $TEST_TMP/__I_dont_exist: No such file or directory
[test.sh] Error in run_test_script(test.sh:): 'BASH_ENV=<(declare -p PRUNE_PATH_CACHE) SUBTEST= "\$test_script" "\$@"' exited with status 127
[test.sh]  at main(the_test.sh:)
EOF
