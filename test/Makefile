TESTS ?= \
    test_config.sh \
    test_includes.sh \
    test_test_functions.sh \
    test_FAIL_FAST.sh \
    test_log.sh \
    test_assert.sh \
    test_ignored.sh

include $(shell git rev-parse --show-toplevel)/Makefile.test

.PHONY: codecov
codecov:
	cd .. && for test in $(TESTS); do bashcov --skip-uncovered test/$$test; done
