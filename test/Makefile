TESTS ?= \
    test_script.sh \
    test_config.sh \
    test_includes.sh \
    test_test_functions.sh \
    test_FAIL_FAST.sh \
    test_log.sh \
    test_assert.sh \
    test_ignored.sh \
    test_REENTER.sh \
    test_teardown_fail.sh \
    test_inline.sh \
    test_SUBSHELL.sh \
    test_STACK_TRACE.sh

include Makefile.test

.PHONY: coverage
coverage:
	cd .. && for test in $(TESTS); do bashcov --skip-uncovered test/$$test; done
