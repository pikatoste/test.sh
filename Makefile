prepare_test:
	[ -d runtest ] || mkdir runtest
	cp build/test.sh runtest
	cp -a test runtest

PRUNE_PATH?=$$PWD/

test: test_clean prepare_test
	${MAKE} -C runtest/test PRUNE_PATH=$(PRUNE_PATH)

test_clean:
	rm -rf runtest

performance: prepare_test
	${MAKE} -C runtest/test performance

compat: prepare_test
	${MAKE} -C runtest/test compat

VERSION:=$(shell tools/generate-version.sh)
BUILD_TIMESTAMP=$(shell date +%s)

build/test.sh: test.sh VERSION
	mkdir -p build
	sed -e 's/^/\# /' -e 's/ \+$$//' LICENSE >build/LICENSE
	BANNER=$$(cat banner.txt | head -n -1 | sed -e 's:\\:\\\\:g' -e 's:/:\\/:g' -e '$$ ! s/$$/\\/') ; sed -e "s/@BUILD_TIMESTAMP@/$(BUILD_TIMESTAMP)/" -e "s/@VERSION@/$(VERSION)/" -e "s/@BANNER@/$$BANNER/" -e '/@LICENSE@/r build/LICENSE' -e '/@LICENSE@/d' test.sh >build/test.sh.tmp
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

.PHONY: test, prepare_test, test_clean, clean, build, check, coverage, coverage_clean, performance, compat
.DEFAULT_GOAL := all
