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
    test_STACK_TRACE.sh \
    test_error_reporting.sh \
    test_setup_error.sh \
    test_regression_33.sh \
    test_regression_30.sh \
    test_regression_31.sh \
    test_validate_values_56.sh \
    test_config_LOG_vars_50.sh \
    test_run_test_script_63.sh \
    test_assert_escaping_62.sh

include Makefile.test

.PHONY: coverage
coverage:
	cd .. && for test in $(TESTS); do bashcov --skip-uncovered test/$$test; done
