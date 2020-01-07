prepare_test:
	[ -d runtest ] || mkdir runtest
	cp build/test.sh runtest
	cp -a test runtest

test: test_clean prepare_test
	${MAKE} -C runtest/test

test_clean:
	rm -rf runtest

VERSION:=$(shell cat VERSION | sed -e 's/SNAPSHOT$$/SNAPSHOT-$(shell git rev-parse HEAD)$(shell git diff-index --quiet HEAD -- || echo -n -dirty)/')

build/test.sh: test.sh VERSION
	mkdir -p build
	sed -e 's/^/\# /' LICENSE >build/LICENSE
	sed -e "s/@VERSION@/$(VERSION)/" -e '/@LICENSE@/r build/LICENSE' -e '/@LICENSE@/d' test.sh >build/test.sh.tmp
	mv build/test.sh.tmp build/test.sh
	chmod a+x build/test.sh

clean: test_clean coverage_clean
	rm -rf build

build: build/test.sh

check: test

coverage_clean:
	rm -rf coverage

coverage: test_clean prepare_test
	${MAKE} -C runtest/test coverage

all: build

.PHONY: test, prepare_test, test_clean, clean, build, check, coverage, coverage_clean
.DEFAULT_GOAL := all
