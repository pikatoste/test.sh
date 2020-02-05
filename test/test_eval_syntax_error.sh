#!/bin/bash
INCLUDE_GLOB="include/*.sh"
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "#98: eval syntax errors in the expression of assert_true are reported as such and not as an assertion failure"
generate_test_fail_check 'assert_true "[[ = b ]]"' <<EOF
$TESTSH: eval: line : conditional binary operator expected
[test.sh] Syntax error in the expression: "[[ = b ]]"
[test.sh]  at eval_trace(test.sh:)
[test.sh]  at try(test.sh:)
[test.sh]  at assert_true(test.sh:)
[test.sh]  at main(the_test.sh:)
EOF

start_test "#98: eval syntax errors in the expression of assert_false are reported as such and not as an assertion failure"
generate_test_fail_check 'assert_false "[[ = b ]]"' <<EOF
$TESTSH: eval: line : conditional binary operator expected
[test.sh] Syntax error in the expression: "[[ = b ]]"
[test.sh]  at eval_trace(test.sh:)
[test.sh]  at try(test.sh:)
[test.sh]  at assert_false(test.sh:)
[test.sh]  at main(the_test.sh:)
EOF

start_test "#98: eval syntax errors in the expression of result_of are reported as such and make it fail"
STACK_TRACE=no generate_test_fail_check 'result_of "[[ = b ]]"' <<EOF
$TESTSH: eval: line : conditional binary operator expected
[test.sh] Syntax error in the expression: "[[ = b ]]"
EOF
