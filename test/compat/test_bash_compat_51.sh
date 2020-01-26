#!/bin/bash

build_docker_image() {
  sed -e s/@IMAGE_VERSION@/$1/ "$TEST_SCRIPT_DIR"/Dockerfile.template >"$TEST_SCRIPT_DIR"/Dockerfile
  docker build -t test.sh:$bash_version --rm "$TEST_SCRIPT_DIR"
}

setup_test() {
  # build docker image if not already built
  docker image ls test.sh:$bash_version 2>/dev/null | grep -q $bash_version || build_docker_image $bash_version
}

teardown_test() {
  docker container ls -a | grep test.sh | cut -d \  -f 1 | xargs docker container rm 2>/dev/null || true
}

source "$(dirname "$(readlink -f "$0")")"/../../test.sh

for bash_version in 4.4.23 5.0.11; do
  start_test "Bash version $bash_version should be supported"
  export TEST_SCRIPT_DIR bash_version
  run_test_script do_test_bash_compat_51.sh
  cp "$LOG_DIR"/do_test_bash_compat_51.sh.out "$TEST_SCRIPT_DIR"/"$LOG_DIR_NAME"-$bash_version/main.out
done
