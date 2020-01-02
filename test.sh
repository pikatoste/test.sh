# Shared functions for local tests.
# It is a shell fragment intended to be included from actual tests. Start each test script
# with a line simlilar to (depends on the relative position of this file):
#
# source "$(dirname "$(readlink -f "$0")")"/test.sh
#
# TODO: sort out global var names and control which are exported
set -a
set -o errexit
set -o pipefail
export SHELLOPTS

VERSION=0.0.0-SNAPSHOT
TEST_SCRIPT="$(readlink -f "$0")"
TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
TESTSH_DIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# TODO: configure whether to colorize output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color'

exit_trap() {
  rm -f "$PIPE"
}

redir_stdout() {
  PIPE=$(mktemp -u)
  mkfifo "$PIPE"
  trap exit_trap EXIT
  TESTOUT_DIR="$TEST_SCRIPT_DIR"/testout
  TESTOUT_FILE="$TESTOUT_DIR"/"$(basename "$TEST_SCRIPT")".out
  mkdir -p "$TESTOUT_DIR"
  [ "$VERBOSE" = 1 ] || cat <"$PIPE" >"$TESTOUT_FILE" &
  [ "$VERBOSE" != 1 ] || tee <"$PIPE" "$TESTOUT_FILE" &
  exec 3>&1 4>&2 >"$PIPE" 2>&1
}

# TODO: display after test: green ok, red failed, blue ignores
display_test_name() {
  [ "$VERBOSE" = 1 ] || echo -e "${GREEN}* $*${NC}" >&3
  echo -e "${GREEN}* $*${NC}"
}

setup_test() { true; }
teardown_test() { true; }
setup_test_suite() { true; }
teardown_test_suite() { true; }

teardown_test_called=0
run_test() {
  local test_func=$1
  shift 1
  setup_test
  run_test_exit_trap() {
    [ $teardown_test_called = 1 ] || teardown_test
  }
  trap run_test_exit_trap EXIT
  $test_func
  teardown_test_called=1
  teardown_test
}

discover_tests() {
  declare -F | cut -d \  -f 3 | grep ^test_
}

teardown_test_suite_called=0
run_tests() {
  [ $# -gt 0 ] || set $(discover_tests)
  local failures=0
  setup_test_suite
  run_test_exit_trap() {
    [ $teardown_test_suite_called = 1 ] || teardown_test_suite
    exit_trap
  }
  trap run_test_exit_trap EXIT
  while [ $# -gt 0 ]; do
    local failed=0
    subshell $1 || failed=1
    if [ $failed -ne 0 ]; then
      echo -e "${RED}$1 FAILED${NC}" >&3
      failures=$(( $failures + 1 ))
      if [ "$FAIL_FAST" = 1 ]; then
        break
      fi
    fi
    shift
  done
  teardown_test_suite_called=1
  teardown_test_suite
  return $failures
}

# TODO: load from predefined PATHs: test dir, testshdir
load_config() {
  # save environment config
  VERBOSE_=$VERBOSE
  DEBUG_=$DEBUG
  INCLUDE_GLOB_="$INCLUDE_GLOB"
  INCLUDE_PATH_="$INCLUDE_PATH"
  FAIL_FAST_=$FAIL_FAST

  # load config if present
  CONFIG_DIR=${CONFIG_DIR:-"$TESTSH_DIR"}
  CONFIG_FILE=${CONFIG_FILE:-"$CONFIG_DIR"/test.sh.config}
  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
  fi

  # prioritize environment config
  VERBOSE=${VERBOSE_:-$VERBOSE}
  DEBUG=${DEBUG_:-$DEBUG}
  INCLUDE_GLOB=${INCLUDE_GLOB_:-$INCLUDE_GLOB}
  INCLUDE_PATH=${INCLUDE_PATH_:-$INCLUDE_PATH}
  FAIL_FAST=${FAIL_FAST_:-$FAIL_FAST}

  # set defaults
  VERBOSE=${VERBOSE:-}
  DEBUG=${DEBUG:-}
  INCLUDE_GLOB=${INCLUDE_GLOB:-"include*.sh"}
  INCLUDE_PATH=${INCLUDE_PATH:-"$TESTSH_DIR/$INCLUDE_GLOB:$TEST_SCRIPT_DIR/$INCLUDE_GLOB"}
  FAIL_FAST=${FAIL_FAST:-1}
}

load_includes() {
  set +e
  shopt -q nullglob
  local current_nullglob=$?
  set -e
  shopt -s nullglob
  local current_IFS="$IFS"
  IFS=":"
  for path in $INCLUDE_PATH; do
    if [ -f "$path" ]; then
      source "$path"
    else
      local files=( "$path" )
      if [ ${#files[@]} -gt 0 ]; then
        source "${files[@]}"
      fi
    fi
  done
  IFS="$current_IFS"
  if [ $current_nullglob -ne 0 ]; then
    shopt -u nullglob
  fi
}

# TODO: use bash vars to pass current options to subshells
subshell() {
  bash -c "$1"
}

assert_fail_msg() {
  local what="$1"
  local why="$2"
  local msg="$3"
  echo "Assertion failed: ${msg:+$msg: }$why in: $what" >&2
  return 1
}

assert_true() {
  subshell "$1" "$2" || assert_fail_msg "$1" "expected success but got failure" "$2"
}

assert_false() {
  ! subshell "$1" "$2" || assert_fail_msg "$1" "expected failure but got success" "$2"
}

redir_stdout
load_config
load_includes

# TODO: process arguments: --version, --help

[ "$DEBUG" != 1 ] || set -x
