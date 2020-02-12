#!/bin/bash

source "$(dirname "$(readlink -f "$0")")"/../../test.sh

docker run -v "$TEST_SCRIPT_DIR"/../..:/mnt/runtest -u $(id -u) --rm test.sh:$bash_version bash -c \
  "set -e; cd /mnt/runtest; rm -rf test/testout; time make -C test BUSYBOX=1; mv test/testout test/compat/testout-$bash_version"
