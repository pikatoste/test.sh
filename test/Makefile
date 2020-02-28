TESTS ?= \
    test_script.sh \
    test_config.sh \
    test_includes.sh \
    test_test_functions.sh \
    test_config_FAIL_FAST.sh \
    test_log.sh \
    test_assert.sh \
    test_ignored.sh \
    test_teardown_fail.sh \
    test_inline.sh \
    test_teardown.sh \
    test_config_STACK_TRACE.sh \
    test_error_reporting.sh \
    test_setup_error.sh \
    test_regression_33.sh \
    test_regression_30.sh \
    test_regression_31.sh \
    test_validate_value_56.sh \
    test_config_LOG_vars_50.sh \
    test_run_test_script_63.sh \
    test_assert_escaping_62.sh \
    test_assert_71.sh \
    test_tmpdir_74.sh \
    test_assert_76.sh \
    test_prune_path_cache.sh \
    test_eval_syntax_error.sh \
    test_exceptions.sh \
    \
    test_xxx_tmpfiles_74.sh

include Makefile.test

.PHONY: coverage performance compat

coverage:
	cd .. && for test in $(TESTS); do bashcov --skip-uncovered test/$$test; done

performance:
	performance/test_performance.sh
	cat performance/testout/test_performance.sh.out | grep real

compat:
	compat/test_bash_compat_51.sh
	for test in compat/testout-*; do echo -n "$$test: "; grep real "$$test/main.out"; done
