#!/bin/bash
#
@LICENSE@
#
# See https://github.com/pikatoste/test.sh/
#
if [ "$0" = "${BASH_SOURCE}" ]; then
  echo "This is test.sh version @VERSION@"
  echo "See https://github.com/pikatoste/test.sh"
  exit 0
fi

exit_trap() {
  if [ $? -eq 0 ]; then
    display_test_passed
  else
    display_test_failed
  fi
  rm -f "$PIPE"
}

setup_io() {
  PIPE=$(mktemp -u)
  mkfifo "$PIPE"
  trap exit_trap EXIT
  TESTOUT_DIR="$TEST_SCRIPT_DIR"/testout
  TESTOUT_FILE="$TESTOUT_DIR"/"$(basename "$TEST_SCRIPT")".out
  mkdir -p "$TESTOUT_DIR"
  local testsh=$(basename "$TESTSH")
  [ "$VERBOSE" = 1 ] || grep -v "$testsh: pop_scope: " <"$PIPE" | cat >"$TESTOUT_FILE" &
  [ "$VERBOSE" != 1 ] || grep -v "$testsh: pop_scope: " <"$PIPE" | tee "$TESTOUT_FILE" &
  exec 3>&1 4>&2 >"$PIPE" 2>&1
}

# TODO: rename to something more apporpiate, such as 'start_test'
# TODO: call setup/teardown also in online mode
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

do_log() {
  echo -e "$*"
}

log() {
  do_log "${GREEN}[test.sh]${NC} $*"
}

logerr() {
  do_log "${RED}[test.sh]${NC} $*" >&2
}

call_if_exists() {
  ! declare -f $1 >/dev/null || $1
}

call_teardown() {
  trap "print_stack_trace || true" ERR
  call_if_exists $1
}

run_test() {
  teardown_test_called=0
  local test_func=$1
  shift 1
  call_if_exists setup_test
  run_test_exit_trap() {
    [ $teardown_test_called = 1 ] || subshell "call_teardown teardown_test" || warn_teardown_failed
  }
  trap run_test_exit_trap EXIT
  trap "print_stack_trace || true; display_test_failed" ERR
  $test_func
  display_test_passed
  teardown_test_called=1
  subshell "call_teardown teardown_test" || warn_teardown_failed
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
      logerr "${test_func} FAILED"
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
  subshell "call_teardown teardown_test_suite" || warn_teardown_failed _suite
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

config_defaults() {
  default_VERBOSE=
  default_DEBUG=
  default_INCLUDE_GLOB='include*.sh'
  default_INCLUDE_PATH='$TESTSH_DIR/$INCLUDE_GLOB:$TEST_SCRIPT_DIR/$INCLUDE_GLOB'
  default_FAIL_FAST=1
  default_REENTER=1
  default_PRUNE_PATH='$PWD/'
}

load_config() {
  save_variable() {
    local var=$1
    [[ ! -v $var ]] || eval "saved_$var=\"${!var}\""
  }

  restore_variable() {
    local var=$1
    local saved_var=saved_$var
    [[ ! -v $saved_var ]] || eval "$var=\"${!saved_var}\""
  }

  set_default() {
    local var=$1
    local default_var=default_$var
    [[ -v $var ]] || eval "$var=$(eval "echo -n ${!default_var}")"
  }

  # TODO: write checks on booleans without comparison operators
  # TODO: use empty/not empty as boolean values, not 0/1

  local config_vars="VERBOSE DEBUG INCLUDE_GLOB INCLUDE_PATH FAIL_FAST REENTER PRUNE_PATH"

  # save environment config
  for var in $config_vars; do
    save_variable $var
  done

  # load config if present
  [ -z "$CONFIG_FILE" ] || source "$CONFIG_FILE"
  [ -n "$CONFIG_FILE" ] || try_config_path

  # prioritize environment config
  for var in $config_vars; do
    restore_variable $var
  done

  # set defaults
  for var in $config_vars; do
    set_default $var
  done
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
  current_stack 0
  CURRENT_STACK="$(echo "$CURRENT_STACK"; echo "$SAVE_STACK" )"
  if [ "$REENTER" = 1 ]; then
    /bin/bash --norc -c "SUBSHELL_CMD=\"$1\" source $TEST_SCRIPT"
  else
    bash --norc -c "$1"
  fi
}

prune_path() {
  [[ -v PRUNE_PATH ]] || eval "PRUNE_PATH=$default_PRUNE_PATH"
  local path=$(realpath "$1")
  echo ${path##$PRUNE_PATH}
}

current_stack() {
    for ((i=${1:-0};i<${#FUNCNAME[@]}-1;i++))
    do
      local line=$(echo "${FUNCNAME[$i+1]}($(prune_path "${BASH_SOURCE[$i+1]}"):${BASH_LINENO[$i]})")
      CURRENT_STACK=$([ -z "$CURRENT_STACK" ] || echo "$CURRENT_STACK"; echo "$line")
    done
}

print_stack_trace() {
  local err=$?
  local idx=1
  local i=${1:-0}
  ERRCMD=$BASH_COMMAND
  if [ "$IN_ASSERT" = 1 ]; then
    ((idx++))
    ERRCMD=${FUNCNAME[1]}
    ((i++))
  fi
  logerr "Error in ${FUNCNAME[$idx]}($(prune_path "${BASH_SOURCE[$idx]}"):${BASH_LINENO[$idx-1]}): '${ERRCMD}' exited with status $err"
  if [ ${#FUNCNAME[@]} -gt 2 ]
  then
    for ((i=1;i<${#FUNCNAME[@]}-1;i++))
    do
      logerr " at ${FUNCNAME[$i+1]}($(prune_path "${BASH_SOURCE[$i+1]}"):${BASH_LINENO[$i]})"
    done
  fi
  echo "$CURRENT_STACK" | while IFS= read line; do
    [ -z "$line" ] || logerr " at ${line}"
    ((i++))
  done
}

assert_fail_msg() {
  local what="$1"
  local why="$2"
  local msg="$3"
  logerr "Assertion failed: ${msg:+$msg: }$why in: $what"
  return 1
}

assert_true() {
  IN_ASSERT=1
  subshell "$1" || assert_fail_msg "$1" "expected success but got failure" "$2"
}

assert_false() {
  IN_ASSERT=1
  ! subshell "$1" || assert_fail_msg "$1" "expected failure but got success" "$2"
}

if [[ ! -v SUBSHELL_CMD ]]; then
  set -o allexport
  set -o errexit
  set -o errtrace
  set -o pipefail
  export SHELLOPTS

  # TODO: sort out global var names and control which are exported
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

  config_defaults
  trap "print_stack_trace || true" ERR
  setup_io
  load_config
  load_includes

  [ "$DEBUG" != 1 ] || set -x
else
  load_includes
  eval "$SUBSHELL_CMD"
  exit 0
fi
