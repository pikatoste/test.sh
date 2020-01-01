# Shared functions for local tests.
# It is a shell fragment intended to be included from actual tests. Start each test script
# with a line simlilar to (depends on the relative position of this file):
#
# source "$(dirname "$(readlink -f "$0")")"/test.sh
#
#set -x
set -a
set -o errexit
set -o pipefail

VERSION=0.0.0-SNAPSHOT
TEST_SCRIPT="$(readlink -f "$0")"
TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
TESTSH_DIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color'

# TODO: redir stdout to test output log file
# TODO: substitute a named pipe + dumper process (redir to fd3 if verbose, /dev/null if not, then tee testout.log) for these two redir_* shitty functions
# TODO: display_test_name will always redirect to fd 3 (pipe).
REDIR=0
redir_stdout() {
  if [ "$REDIR" -eq 0 ]; then
    [ "$VERBOSE" = 1 ] || exec 3>&1 >/dev/null
  fi
  REDIR=$(($REDIR + 1))
}

restore_stdout() {
  REDIR=$(($REDIR - 1))
  if [ $REDIR -eq 0 ]; then
    [ "$VERBOSE" = 1 ] || exec 1>&3
  fi
}

display_test_name() {
	restore_stdout
  echo -e "${GREEN}*" "$@" "${NC}"
  redir_stdout
}

setup_test() { true; }
teardown_test() { true; }
setup_test_suite() { true; }
teardown_test_suite() { true; }

run_test() {
  local test_func=$1
  shift 1
  setup_test
  $test_func
  # TODO: call on TRAP
  teardown_test
}

discover_tests() {
  declare -F | cut -d \  -f 3 | grep ^test_
}

run_tests() {
  [ $# -gt 0 ] || set $(discover_tests)
  local failures=0
  setup_test_suite
  while [ $# -gt 0 ]; do
    local failed=0
    bash -c "set -e; set -o pipefail; run_test $1" || failed=1
    if [ $failed -ne 0 ]; then
      echo -e "${RED}$1 FAILED${NC}" >&2
      failures=$(( $failures + 1 ))
      if [ "$FAIL_FAST" = 1 ]; then
        break
      fi
    fi
    shift
  done
  # TODO: call on TRAP
  teardown_test_suite
  return $failures
}

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

assert() {
  if [ $? -ne 0 ]; then
    echo "Assertion failed: " "$@" >&2
    return 1
  fi
}

redir_stdout
load_config
load_includes

# TODO: process arguments: --version, --help

[ "$DEBUG" != 1 ] || set -x
