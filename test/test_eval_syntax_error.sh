#!/bin/bash
INCLUDE_GLOB="include/*.sh"
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "#98: eval syntax errors in the expression of assert_true are reported as such and not as an assertion failure"
test_generate_fail_check 'assert_true "[[ = b ]]"' <<EOF
$TESTSH: eval: line : conditional binary operator expected
[test.sh] Syntax error in the expression: "[[ = b ]]"
[test.sh] Error in eval_trace(runtest/test.sh:): 'eval "trap - EXIT;" "\$1"' exited with status 2
[test.sh]  at result_of(runtest/test.sh:)
[test.sh]  at expect_true(runtest/test.sh:)
[test.sh]  at assert(runtest/test.sh:)
[test.sh]  at assert_true(runtest/test.sh:)
[test.sh]  at main(runtest/test/tmp/do_test_assert.sh:)
EOF

start_test "#98: eval syntax errors in the expression of assert_false are reported as such and not as an assertion failure"
test_generate_fail_check 'assert_false "[[ = b ]]"' <<EOF
$TESTSH: eval: line : conditional binary operator expected
[test.sh] Syntax error in the expression: "[[ = b ]]"
[test.sh] Error in eval_trace(runtest/test.sh:): 'eval "trap - EXIT;" "\$1"' exited with status 2
[test.sh]  at result_of(runtest/test.sh:)
[test.sh]  at expect_false(runtest/test.sh:)
[test.sh]  at assert(runtest/test.sh:)
[test.sh]  at assert_false(runtest/test.sh:)
[test.sh]  at main(runtest/test/tmp/do_test_assert.sh:)
EOF

start_test "#98: eval syntax errors in the expression of result_of are reported as such and make it fail"
test_generate_fail_check 'result_of "[[ = b ]]"' <<EOF
$TESTSH: eval: line : conditional binary operator expected
[test.sh] Syntax error in the expression: "[[ = b ]]"
[test.sh] Error in eval_trace(runtest/test.sh:): 'eval "trap - EXIT;" "\$1"' exited with status 2
[test.sh]  at result_of(runtest/test.sh:)
[test.sh]  at main(runtest/test/tmp/do_test_assert.sh:)
EOF
