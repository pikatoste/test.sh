TEST_SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
LOG_DIR="$TEST_SCRIPT_DIR"/testout

build_docker_image() {
  local bash_version=$1
  local VERSION=${bash_version%.*}
  local PATCH_LEVEL=0
  local LATEST_PATCH=${bash_version#*.*.}

  local DOCKER_DIR=$TEST_SCRIPT_DIR/bash
  cp "$DOCKER_DIR"/Dockerfile.template "$DOCKER_DIR"/Dockerfile
  sed -i -e s/@VERSION@/$VERSION/ -e s/@PATCH_LEVEL@/$PATCH_LEVEL/ -e s/@LATEST_PATCH@/$LATEST_PATCH/ "$DOCKER_DIR"/Dockerfile
  docker build -t bash-test:$bash_version --rm "$DOCKER_DIR"
}

default_TEST_BASH_VERSIONS="4.4.{0,23} 5.0.{0,11}"
TEST_BASH_VERSIONS="$*"
TEST_BASH_VERSIONS=${TEST_BASH_VERSIONS:-$(eval echo $default_TEST_BASH_VERSIONS)}
FAILED=0
for bash_version in $TEST_BASH_VERSIONS; do
  docker image ls bash-test:$bash_version 2>/dev/null | grep -q $bash_version || build_docker_image $bash_version
  bash_version_str=$(docker run bash-test:$bash_version bash --version | head -1)
  echo "Testing bash:$bash_version ($bash_version_str)"
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR"/bash-$bash_version.log
  echo "Testing bash:$bash_version ($bash_version_str)" >"$LOG_FILE"
  docker run -v "$TEST_SCRIPT_DIR"/..:/mnt/test.sh --user test --rm bash-test:$bash_version bash -c \
    'set -e; cd ; cp -a /mnt/test.sh/runtest . ;  find runtest -type f -name test_\*.sh | grep -v /compat/ | sort | while read test; do "$test"; done' #2>/dev/null >>"$LOG_FILE"
  if [[ $? = 0 ]]; then
    echo "SUPPORTED: bash:$bash_version ($bash_version_str)"
  else
    echo "NOT SUPPORTED: bash:$bash_version ($bash_version_str)"
    ((FAILED++))
  fi
done

echo Remove dangling containers:
docker container ls -a | grep bash-test | cut -d \  -f 1 | xargs docker container rm

exit $FAILED
