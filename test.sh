# Shared functions for local tests.
# It is a shell fragment intended to be included from actual tests. Start each test script
# with a line simlilar to (depends on the relative position of this file):
#
# source "$(dirname "$(readlink -f "$0")")"/test.sh
#
# TODO: sort out global var names and control which are exported
set -a
set -o errexit
set -o errtrace
set -o pipefail
export SHELLOPTS

VERSION=0.0.0-SNAPSHOT
TEST_SCRIPT="$(readlink -f "$0")"
TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
TESTSH_DIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# TODO: configure whether to colorize output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color'

exit_trap() {
  if [ $? -eq 0 ]; then
    display_test_passed
  else
    display_test_failed
  fi
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

set_test_name() {
  [ -z "$CURRENT_TEST_NAME" ] || display_test_passed
  CURRENT_TEST_NAME="$1"
  [ -z "$CURRENT_TEST_NAME" ] || echo "Start test: $CURRENT_TEST_NAME"
}

display_test_passed() {
  [ -z "$CURRENT_TEST_NAME" ] || echo -e "${GREEN}* ${CURRENT_TEST_NAME}${NC}" >&3
}

display_test_failed() {
  [ -z "$CURRENT_TEST_NAME" ] || echo -e "${RED}* ${CURRENT_TEST_NAME}${NC}" >&3
}

display_test_skipped() {
  echo -e "${BLUE}* [skipped] $1${NC}" >&3
}

warn_teardown_failed() {
  echo -e "${BLUE}WARN: teardown_test$1 failed${NC}" >&3
}

setup_test() { true; }
teardown_test() { true; }
setup_test_suite() { true; }
teardown_test_suite() { true; }

run_test() {
  teardown_test_called=0
  local test_func=$1
  shift 1
  setup_test
  run_test_exit_trap() {
    [ $teardown_test_called = 1 ] || subshell teardown_test || warn_teardown_failed
  }
  trap run_test_exit_trap EXIT
  trap "print_stack_trace; display_test_failed" ERR
  $test_func
  display_test_passed
  teardown_test_called=1
  subshell teardown_test || warn_teardown_failed
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
    [ $teardown_test_suite_called = 1 ] || subshell teardown_test_suite || warn_teardown_failed _suite
    exit_trap
  }
  trap run_test_exit_trap EXIT
  while [ $# -gt 0 ]; do
    local test_func=$1
    shift
    local failed=0
    subshell "run_test $test_func" || failed=1
    if [ $failed -ne 0 ]; then
      echo -e "${RED}$test_func FAILED${NC}" >&2
      failures=$(( $failures + 1 ))
      if [ "$FAIL_FAST" = 1 ]; then
        while [ $# -gt 0 ]; do
          display_test_skipped $1
          shift
        done
        break
      fi
    fi
  done
  teardown_test_suite_called=1
  subshell teardown_test_suite || warn_teardown_failed _suite
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

subshell() {
  bash -c "$1"
}

print_stack_trace() {
  echo "stack trace:"
  local frame=${1:-0}
  while caller $frame; do
    ((frame++))
  done || true
  #caller || true
}

assert_fail_msg() {
  local what="$1"
  local why="$2"
  local msg="$3"
  echo "Assertion failed: ${msg:+$msg: }$why in: $what" >&2
  return 1
}

assert_true() {
  subshell "$1" || assert_fail_msg "$1" "expected success but got failure" "$2"
}

assert_false() {
  ! subshell "$1" || assert_fail_msg "$1" "expected failure but got success" "$2"
}

redir_stdout
load_config
load_includes
trap "print_stack_trace" ERR

# TODO: process arguments: --version, --help

[ "$DEBUG" != 1 ] || set -x
