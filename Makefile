prepare_test:
	[ -d runtest ] || mkdir runtest
	cp test.sh runtest
	cp -a test runtest

test: prepare_test
	${MAKE} -C runtest/test

clean:
	rm -rf runtest

all: clean test

.PHONY: test, prepare_test, clean
.DEFAULT_GOAL := all
