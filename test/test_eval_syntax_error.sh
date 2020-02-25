#!/bin/bash
INCLUDE_GLOB="include/*.sh"
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "#98: eval syntax errors in the expression of assert_success are reported as such and not as an assertion failure"
generate_test_fail_check 'assert_success "[[ = b ]]"' <<EOF
$TESTSH: eval: line : conditional binary operator expected
[test.sh] eval_syntax exception: Syntax error in the expression: [[ = b ]]
[test.sh]  at _eval(test.sh:)
[test.sh]  at assert_success(test.sh:)
[test.sh]  at main(the_test.sh:)
EOF

start_test "#98: eval syntax errors in the expression of assert_failure are reported as such and not as an assertion failure"
generate_test_fail_check 'assert_failure "[[ = b ]]"' <<EOF
$TESTSH: eval: line : conditional binary operator expected
[test.sh] eval_syntax exception: Syntax error in the expression: [[ = b ]]
[test.sh]  at _eval(test.sh:)
[test.sh]  at assert_failure(test.sh:)
[test.sh]  at main(the_test.sh:)
EOF

start_test "#98: eval syntax errors in try/catch nonzero are not caught"
STACK_TRACE=no generate_test_fail_check 'try: _eval "[[ = b ]]"
catch nonzero: true
endtry' <<EOF
$TESTSH: eval: line : conditional binary operator expected
[test.sh] eval_syntax exception: Syntax error in the expression: [[ = b ]]
EOF
