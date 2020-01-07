#!/bin/bash
@LICENSE@
# Shared functions for local tests.
# It is a shell fragment intended to be included from actual tests. Start each test script
# with a line simlilar to (depends on the relative position of this file):
#
# source "$(dirname "$(readlink -f "$0")")"/test.sh
#
if [ "$0" = "${BASH_SOURCE}" ]; then
  echo "This is test.sh version @VERSION@"
  echo "See https://github.com/pikatoste/test.sh"
  exit 0
fi
# TODO: sort out global var names and control which are exported
[ "$NOTESTSH" != 1 ] || { echo "Reentering test.sh from reentered script, did you forget the check '[ \"\$REENTRANT\" != 1 ] || return 0'?" >&2; exit 1; }
if [ "$REENTRANT" != 1 ]; then
  set -a
  set -o errexit
  set -o errtrace
  set -o pipefail
  export SHELLOPTS

  VERSION=@VERSION@
  TEST_SCRIPT="$(readlink -f "$0")"
  TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
  TESTSH="$(readlink -f "$BASH_SOURCE")"
  TESTSH_DIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  # TODO: configure whether to colorize output
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color'
fi
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
  [ -z "$CURRENT_TEST_NAME" ] || log "Start test: $CURRENT_TEST_NAME"
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

log() {
  echo -e "[test.sh] $*"
}

call_if_exists() {
  ! declare -f $1 >/dev/null || $1
}

run_test() {
  teardown_test_called=0
  local test_func=$1
  shift 1
  call_if_exists setup_test
  run_test_exit_trap() {
    [ $teardown_test_called = 1 ] || subshell "trap \"print_stack_trace || true\" ERR; call_if_exists teardown_test" || warn_teardown_failed
  }
  trap run_test_exit_trap EXIT
  trap "print_stack_trace || true; display_test_failed" ERR
  $test_func
  display_test_passed
  teardown_test_called=1
  subshell "trap \"print_stack_trace || true\" ERR; call_if_exists teardown_test" || warn_teardown_failed
}

discover_tests() {
  # TODO: use a configurable test matching pattern
  declare -F | cut -d \  -f 3 | grep ^test_ || true
}

run_tests() {
  teardown_test_suite_called=0
  [ $# -gt 0 ] || { local discovered="$(discover_tests)"; [ -z "$discovered" ] || set $discovered; }
  local failures=0
  call_if_exists setup_test_suite
  while [ $# -gt 0 ]; do
    local test_func=$1
    shift
    local failed=0
    subshell "run_test $test_func" || failed=1
    if [ $failed -ne 0 ]; then
      log "${RED}${test_func} FAILED${NC}" >&2
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
  subshell "trap \"print_stack_trace || true\" ERR; call_if_exists teardown_test_suite" || warn_teardown_failed _suite
  return $failures
}

try_config_path() {
  CONFIG_PATH="$TEST_SCRIPT_DIR:$TESTSH_DIR:$PWD"
  local current_IFS="$IFS"
  IFS=":"
  for path in $CONFIG_PATH; do
    ! [ -f "$path"/test.sh.config ] || {
      CONFIG_FILE="$path"/test.sh.config
      source "$CONFIG_FILE"
      break
    }
  done
  IFS="$current_IFS"
}

load_config() {
  # save environment config
  VERBOSE_=$VERBOSE
  DEBUG_=$DEBUG
  INCLUDE_GLOB_="$INCLUDE_GLOB"
  INCLUDE_PATH_="$INCLUDE_PATH"
  FAIL_FAST_=$FAIL_FAST
  REENTER_=$REENTER

  # load config if present
  [ -z "$CONFIG_FILE" ] || source "$CONFIG_FILE"
  [ -n "$CONFIG_FILE" ] || try_config_path

  # prioritize environment config
  VERBOSE=${VERBOSE_:-$VERBOSE}
  DEBUG=${DEBUG_:-$DEBUG}
  INCLUDE_GLOB="${INCLUDE_GLOB_:-$INCLUDE_GLOB}"
  INCLUDE_PATH="${INCLUDE_PATH_:-$INCLUDE_PATH}"
  FAIL_FAST=${FAIL_FAST_:-$FAIL_FAST}
  REENTER=${REENTER_:-$REENTER}

  # set defaults
  VERBOSE=${VERBOSE:-}
  DEBUG=${DEBUG:-}
  INCLUDE_GLOB=${INCLUDE_GLOB:-"include*.sh"}
  INCLUDE_PATH="${INCLUDE_PATH:-$TESTSH_DIR/$INCLUDE_GLOB:$TEST_SCRIPT_DIR/$INCLUDE_GLOB}"
  FAIL_FAST=${FAIL_FAST:-1}
  REENTER=${REENTER:-1}
}

load_includes() {
  local current_IFS="$IFS"
  IFS=":"
  for path in $INCLUDE_PATH; do
    # shellcheck disable=SC2066
    for include in "$path"; do
      [ ! -f "$include" ] || source "$include"
    done
  done
  IFS="$current_IFS"
}

subshell() {
  SAVE_STACK="$CURRENT_STACK"
  trap "CURRENT_STACK=\"$SAVE_STACK\"" RETURN
  CURRENT_STACK=
  current_stack 1
  CURRENT_STACK="$(echo "$CURRENT_STACK"; echo "$SAVE_STACK" )"
  if [ "$REENTER" = 1 ]; then
    bash --norc -c "REENTRANT=1; source $TESTSH; NOTESTSH=1 source $TEST_SCRIPT; $1"
#    bash --norc -c "REENTRANT=1 source $TEST_SCRIPT \"$1\""
  else
    bash --norc -c "$1"
  fi
}

current_stack() {
  local frame=${1:-0}
  while true; do
    local line=$(caller $frame)
    [ -n "$line" ] || break
    CURRENT_STACK=$([ -z "$CURRENT_STACK" ] || echo "$CURRENT_STACK"; echo "$line")
    ((frame++))
  done
}

print_stack_trace() {
  log "${RED}stack trace:${NC}" >&2
  local frame=${1:-0}
  while true; do
    local line=$(caller $frame)
    [ -n "$line" ] || break
    log "${RED}$line${NC}" >&2
    ((frame++))
  done
  echo "$CURRENT_STACK" | while read line; do
    log "${RED}${line}${NC}" >&2
  done
  #[ -z "$CURRENT_STACK" ] || echo -e "${RED}$CURRENT_STACK${NC}" >&2
}

assert_fail_msg() {
  local what="$1"
  local why="$2"
  local msg="$3"
  log "${RED}Assertion failed: ${msg:+$msg: }$why in: $what${NC}" >&2
  return 1
}

assert_true() {
  subshell "$1" || assert_fail_msg "$1" "expected success but got failure" "$2"
}

assert_false() {
  ! subshell "$1" || assert_fail_msg "$1" "expected failure but got success" "$2"
}

if [ "$REENTRANT" != 1 ]; then
  trap "print_stack_trace || true" ERR
  redir_stdout
  load_config
  load_includes

  [ "$DEBUG" != 1 ] || set -x
#else
#  eval "$1"
#  exit 0
fi
