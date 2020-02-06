#!/bin/bash
#
@LICENSE@
#
# See https://github.com/pikatoste/test.sh/
#
# shellcheck disable=SC2128
if [ "$0" = "${BASH_SOURCE}" ]; then
  echo "This is test.sh version @VERSION@"
  echo "See https://github.com/pikatoste/test.sh"
  exit 0
fi

set -o errexit
set -o errtrace
set -o pipefail
shopt -s inherit_errexit

try() {
  [[ ! -f $EXCEPTION ]] || throw "error.dangling-exception" "An exception occurred before entering the 'try' block"
  get_result "$(trap "throw_eval_syntax_error_exception \"$1\"" EXIT; eval "trap - EXIT;" "$1" >&2)"
}

get_result() {
  TRY_EXIT_CODE=$?
}

catch() {
  local err=$TRY_EXIT_CODE
  if [[ $err != 0 && -f "$EXCEPTION" ]]; then
    local exception=$1
    local the_exception=$(head -1 "$EXCEPTION")
    [[ $the_exception =~ ^$exception ]] || exit $err
    false
  fi
}

# TODO: legacy, still used by tests
try_catch_print() {
  try "$*"
  catch "nonzero" || print_exception
}

throw() {
  create_exception "$@"
  false
}

create_exception() {
  exception=$1
  exception_msg=$2
  first_frame=${3:-2}
  local cause
  [[ ! -f $EXCEPTION ]] || cause=$(cat "$EXCEPTION")
  echo "$exception" >"$EXCEPTION"
  echo "$exception_msg" >>"$EXCEPTION"
  local_stack $first_frame >>"$EXCEPTION"
  if [[ $cause ]]; then
    echo "Caused by:" >>"$EXCEPTION"
    echo "$cause" >>"$EXCEPTION"
  fi
}

prune_path() {
  if [[ $1 && $1 != environment ]]; then
    if [[ ${PRUNE_PATH_CACHE[$1]} ]]; then
      PRUNED_PATH=${PRUNE_PATH_CACHE[$1]}
    else
      # shellcheck disable=SC2155
      local path=$(realpath "$1")
      PRUNE_PATH_CACHE[$1]=${path##$PRUNE_PATH}
      PRUNED_PATH=${PRUNE_PATH_CACHE[$1]}
    fi
  else
    PRUNED_PATH="$1"
  fi
}

local_stack() {
  [[ $STACK_TRACE == no ]] || for ((i=${1:-0}; i<${#FUNCNAME[@]}-1; i++))
  do
    # shellcheck disable=SC2155
#    local source_basename=$(basename "${BASH_SOURCE[$i+1]}")
#    [[ $STACK_TRACE != pruned || $source_basename != test.sh ]] || break
#    [[ $STACK_TRACE != compact || $source_basename != test.sh ]] || continue
    # shellcheck disable=SC2155
    prune_path "${BASH_SOURCE[$i+1]}"
    local frame="${FUNCNAME[$i+1]}($PRUNED_PATH:${BASH_LINENO[$i]})"
    echo "$frame"
  done
}

print_exception() {
  if [[ -f "$EXCEPTION" ]]; then
    local exception
    ( while read -r exception; do
        ! read -r line || log_err "$line"
        while read -r line; do
          if [[ $line =~ ^'Caused by' ]]; then
            log_err "$line"
            break
          fi
          log_err " at $line"
        done
      done
    ) <"$EXCEPTION"
    rm -f "$EXCEPTION"
  fi
}

rethrow() {
  false
}

throw_eval_syntax_error_exception() {
#  ERR_CODE=$?
  print_exception
  local errmsg="Syntax error in the expression: \"$1\""
  throw "error.eval-syntax-error" "$errmsg" 3
}

create_nonzero_implicit_exception() {
  if [ ! -f "$EXCEPTION" ]; then
    local err=$ERR_CODE
    local errcmd=$(echo -n "$BASH_COMMAND" | head -1)
    local frame_idx=2
    prune_path "${BASH_SOURCE[$frame_idx]}"
    local errmsg="Error in ${FUNCNAME[$frame_idx]}($PRUNED_PATH:${BASH_LINENO[$frame_idx-1]}): '${errcmd}' exited with status $err"
    ((frame_idx+=2))
    create_exception "nonzero.implicit" "$errmsg" $frame_idx
  fi
}

exit_trap() {
  EXIT_CODE=${EXIT_CODE:-$?}
  print_exception
  for handler in "${EXIT_HANDLERS[@]}"; do
    # shellcheck disable=SC2016
    eval "$handler"
  done
}

push_exit_handler() {
  EXIT_HANDLERS=("$1" "${EXIT_HANDLERS[@]}")
}

pop_exit_handler() {
  EXIT_HANDLERS=("${EXIT_HANDLERS[@]:1}")
}

err_trap() {
  ERR_CODE=$?
  for handler in "${ERR_HANDLERS[@]}"; do
    eval "$handler" || true
  done
}

push_err_handler() {
  ERR_HANDLERS=("$1" "${ERR_HANDLERS[@]}")
}

pop_err_handler() {
  ERR_HANDLERS=("${ERR_HANDLERS[@]:1}")
}

display_last_test_result() {
  if [[ $EXIT_CODE == 0 ]]; then
    display_test_passed
  else
    display_test_failed
  fi
}

start_test() {
  [[ -v MANAGED || ! -v FIRST_TEST ]] || call_setup_test_suite
  [ -z "$CURRENT_TEST_NAME" ] || display_test_passed
  [[ -v MANAGED || -v FIRST_TEST ]] || { teardown_test_called=1; call_teardown "teardown_test"; }
  CURRENT_TEST_NAME="$1"
  [[ -v MANAGED ]] || { teardown_test_called=; call_if_exists setup_test; }
  [ -z "$CURRENT_TEST_NAME" ] || log "Start test: $CURRENT_TEST_NAME"
  unset FIRST_TEST
}

display_test_passed() {
  [ -z "$CURRENT_TEST_NAME" ] || { log_ok "PASSED: ${CURRENT_TEST_NAME}"; echo -e "${GREEN}* ${CURRENT_TEST_NAME}${NC}" >&3; }
  unset CURRENT_TEST_NAME
}

display_test_failed() {
  [ -z "$CURRENT_TEST_NAME" ] || { log_err "FAILED: ${CURRENT_TEST_NAME}"; echo -e "${RED}* ${CURRENT_TEST_NAME}${NC}" >&3; }
  unset CURRENT_TEST_NAME
}

display_test_skipped() {
  echo -e "${BLUE}* [skipped] $1${NC}" >&3
}

warn_teardown_failed() {
  echo -e "${ORANGE}WARN: $1 failed${NC}" >&3
}

do_log() {
  echo -e "$*"
}

log() {
  do_log "${BLUE}[test.sh]${NC} $*"
}

log_ok() {
  do_log "${GREEN}[test.sh]${NC} $*"
}

log_warn() {
  do_log "${ORANGE}[test.sh]${NC} $*"
}

log_err() {
  do_log "${RED}[test.sh]${NC} $*" >&2
}

call_if_exists() {
  ! declare -f "$1" >/dev/null || $1
}

error_setup_test_suite() {
  echo -e "${RED}[ERROR] setup_test_suite failed, see ${LOG_FILE##$PRUNE_PATH} for more information${NC}" >&3
}

call_setup_test_suite() {
  try "call_if_exists \"setup_test_suite\""
  catch || { error_setup_test_suite; rethrow; }
}

call_teardown() {
  try "call_if_exists \"$1\""
  catch || { print_exception; warn_teardown_failed "$1"; }
}

run_test_script() {
  # commented out to supprt realpath in busybox (for bash compat test in containers)
#  local test_script=$(pwd=$PWD; cd "$TEST_SCRIPT_DIR"; realpath --relative-to "$pwd" "$1")
  local test_script
  test_script=$(cd "$TEST_SCRIPT_DIR"; realpath "$1")
  shift
#  (
#    # TODO: give meaning to SUBSHELL_LOG_CONFIG and implement it
##    # restore log-related config vars to initial values
##    if [[ $SUBTEST_LOG_CONFIG = reset ]]; then
##      for var in LOG_DIR_NAME LOG_DIR LOG_NAME; do
##        while [[ -v $var ]]; do unset $var; done
##        restore_variable $var
##      done
##      # shellcheck disable=SC2030
##      while [[ -v LOG_FILE ]]; do unset LOG_FILE; done
##    fi
#
#    BASH_ENV=<(declare -p PRUNE_PATH_CACHE) SUBTEST= "$test_script" "$@" )
#  BASH_ENV=<(declare -p PRUNE_PATH_CACHE) SUBTEST='' "$test_script" "$@"
  "$test_script" "$@"
}

run_test() {
  local test_func=$1
  call_if_exists setup_test
  teardown_test_called=
  "$test_func"
  CURRENT_TEST_NAME=${CURRENT_TEST_NAME:-$test_func}
  display_test_passed
  teardown_test_called=1
  call_teardown "teardown_test"
}

run_tests() {
  MANAGED=
  discover_tests() {
    declare -F | cut -d \  -f 3 | grep "$TEST_MATCH" || true
  }

  # shellcheck disable=SC2086
  # shellcheck disable=SC2155
  [ $# -gt 0 ] || { local discovered=$(discover_tests); [ -z "$discovered" ] || set $discovered; }
  local failures=0
  call_setup_test_suite
  while [ $# -gt 0 ]; do
    local test_func=$1
    shift
    local failed=0
    try "run_test \"$test_func\""
    catch || {
      print_exception
      failed=1
      CURRENT_TEST_NAME=${CURRENT_TEST_NAME:-$test_func}; display_test_failed;
      [[ $teardown_test_called ]] || call_teardown "teardown_test"
    }
    if [ $failed -ne 0 ]; then
      failures=$(( failures + 1 ))
      if [[ $FAIL_FAST ]]; then
        while [ $# -gt 0 ]; do
          display_test_skipped "$1"
          shift
        done
        break
      fi
    fi
  done
  call_teardown "teardown_test_suite"
  [[ $failures == 0 ]]
}

load_includes() {
  load_include_file() {
    local include_file=$1
    # shellcheck disable=SC1090
    source "$include_file"
    log "Included: $include_file"
    [[ ! $INITIALIZE_SOURCE_CACHE ]] || prune_path "$include_file"
  }

  local include_files=()
  local saved_IFS=$IFS
  IFS=":"
  for path in $INCLUDE_PATH; do
    # shellcheck disable=SC2066
    for file in "$path"; do
      [[ -f $file ]] && include_files=("${include_files[@]/$file}" "$file")
    done
  done
  IFS=$saved_IFS
  for file in "${include_files[@]}"; do
    [[ $file ]] && load_include_file "$file"
  done
}

assert_msg() {
  local msg=$1
  local why=$2
  echo "Assertion failed: ${msg:+$msg, }$why"
}

assert_true() {
  local what=$1
  tsh_assert_msg=$2
  tsh_assert_why="expected success but got failure in: '$what'"
  try "$what"
  catch nonzero || throw "nonzero.explicit.assert" "$(assert_msg "$tsh_assert_msg" "$tsh_assert_why")" # STACK_TRACE=no
}

assert_false() {
  local what=$1
  tsh_assert_msg=$2
  tsh_assert_why="expected failure but got success in: '$what'"
  try "$what"
  catch nonzero || rm -f "$EXCEPTION"
  [[ $TRY_EXIT_CODE != 0 ]] || throw "nonzero.explicit.assert" "$(assert_msg "$tsh_assert_msg" "$tsh_assert_why")"
}

assert_equals() {
  local expected=$1
  local current=$2
  local msg=$3
  tsh_assert_msg=$msg
  tsh_assert_why="expected '$expected' but got '$current'"
  try "[[ \"$(printf "%q" "$expected")\" = \"$(printf "%q" "$current")\" ]]"
  catch nonzero || throw "nonzero.explicit.assert" "$(assert_msg "$tsh_assert_msg" "$tsh_assert_why")"
}

VERSION=@VERSION@
TEST_SCRIPT=$(readlink -f "$0")
TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
# shellcheck disable=SC2128
TESTSH=$(readlink -f "$BASH_SOURCE")
TESTSH_DIR=$(dirname "$TESTSH")
TEST_TMP=$TEST_SCRIPT_DIR/tmp
rm -rf "$TEST_TMP"
mkdir -p "$TEST_TMP"

FIRST_TEST=
TSH_TMPDIR=$(mktemp -d -p "${TMPDIR:-/tmp}" tsh-XXXXXXXXX)
EXCEPTION=$TSH_TMPDIR-stack
declare -A PRUNE_PATH_CACHE

if [[ $BUSYBOX ]]; then
  GREP="grep"
else
  GREP="grep --line-buffered"
fi

set_color() {
  if [[ $COLOR = yes ]]; then
    GREEN='\033[0;32m'
    ORANGE='\033[0;33m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color'
  else
    unset GREEN ORANGE RED BLUE NC
  fi
}

cleanup() {
  exec 1>&- 2>&-
  wait
  [[ ! $CLEAN_TEST_TMP ]] || [[ $EXIT_CODE != 0 ]] || rm -rf "$TEST_TMP"
}

setup_io() {
  PIPE=$TSH_TMPDIR/pipe
  mkfifo "$PIPE"
  # shellcheck disable=SC2031
  mkdir -p "$(dirname "$LOG_FILE")"
  [[ $SUBTEST_LOG_CONFIG != noredir ]] || return 0
  local redir=\>
  [[ $LOG_MODE = overwrite ]] || redir=\>$redir
  # TODO: --line-buffered incompatible con busybox
  # shellcheck disable=SC2031
  [[   $VERBOSE ]] || { $GREP -v ': pop_scope: ' <"$PIPE" | eval cat $redir"$LOG_FILE" & }
  redir=
  [[ $LOG_MODE = overwrite ]] || redir=-a
  # shellcheck disable=SC2031
  [[ ! $VERBOSE ]] || { $GREP -v ': pop_scope: ' <"$PIPE" | tee $redir "$LOG_FILE" & }
  exec 3>&1 4>&2 >"$PIPE" 2>&1
}

config_defaults() {
  default_VERBOSE=
  default_DEBUG=
  default_INCLUDE_GLOB='include*.sh'
  # shellcheck disable=SC2016
  default_INCLUDE_PATH='$TESTSH_DIR/$INCLUDE_GLOB:$TEST_SCRIPT_DIR/$INCLUDE_GLOB'
  default_FAIL_FAST=1
  # shellcheck disable=SC2016
  default_PRUNE_PATH='$PWD/'
  default_STACK_TRACE='full'
  default_TEST_MATCH='^test_'
  default_COLOR='yes'
  # TODO: log would be better
  default_LOG_DIR_NAME='testout'
  # shellcheck disable=SC2016
  # shellcheck disable=SC2016
  default_LOG_DIR='$TEST_SCRIPT_DIR/$LOG_DIR_NAME'
  # shellcheck disable=SC2016
  default_LOG_NAME='$(basename "$TEST_SCRIPT").out'
  # shellcheck disable=SC2016
  default_LOG_FILE='$LOG_DIR/$LOG_NAME'
  default_LOG_MODE='overwrite'
  default_SUBTEST_LOG_CONFIG='reset'
  default_INITIALIZE_SOURCE_CACHE=
  default_CLEAN_TEST_TMP=1
}

load_config() {
  save_variable() {
    local var=$1
    [[ ! -v $var ]] || eval "saved_$var=${!var}"
  }

  restore_variable() {
    local var=$1
    local saved_var=saved_$var
    [[ ! -v $saved_var ]] || eval "$var=${!saved_var}"
  }

  set_default() {
    local var=$1
    local default_var=default_$var
    [[ -v $var ]] || eval "$var=${!default_var}"
  }

  load_config_file() {
    local config_file=$1
    # shellcheck disable=SC1090
    source "$config_file"
  }

  try_config_path() {
    CONFIG_PATH="$TEST_SCRIPT_DIR:$TESTSH_DIR:$PWD"
    local current_IFS="$IFS"
    IFS=":"
    for path in $CONFIG_PATH; do
      ! [ -f "$path"/test.sh.config ] || {
        CONFIG_FILE="$path"/test.sh.config
        load_config_file "$CONFIG_FILE"
        break
      }
    done
    IFS="$current_IFS"
  }

  local config_vars="VERBOSE DEBUG INCLUDE_GLOB INCLUDE_PATH FAIL_FAST PRUNE_PATH STACK_TRACE TEST_MATCH COLOR LOG_DIR_NAME LOG_DIR LOG_NAME LOG_FILE LOG_MODE SUBTEST_LOG_CONFIG INITIALIZE_SOURCE_CACHE CLEAN_TEST_TMP"

  # save environment config
  for var in $config_vars; do
    save_variable "$var"
  done

  # load config file if present
  [ -z "$CONFIG_FILE" ] || load_config_file "$CONFIG_FILE"
  [ -n "$CONFIG_FILE" ] || try_config_path

  # prioritize environment config
  for var in $config_vars; do
    restore_variable "$var"
  done

  # set defaults
  for var in $config_vars; do
    set_default "$var"
  done

  set_color

  # validate config
  validate_values() {
    local var=$1
    local val=${!var}
    shift
    # shellcheck disable=SC2071
    for i in "$@"; do
      [[ $i != "$val" ]] || return 0
    done
    local allowed_values="$*"
    log_err "Configuration: invalid value of variable $var: '$val', allowed values: ${allowed_values// /, }" && false
  }

  # TODO: change to: no, yes... mmm what about the other booleans... not clear
  validate_values STACK_TRACE no full
  validate_values COLOR no yes
  validate_values LOG_MODE overwrite append
  validate_values SUBTEST_LOG_CONFIG reset noreset noredir
}

init_prune_path_cache() {
  local path
  [[ ! -v SUBTEST ]] || for path in "${!PRUNE_PATH_CACHE[@]}"; do
    PRUNE_PATH_CACHE[$path]=${path##$PRUNE_PATH}
  done
  [[ $INITIALIZE_SOURCE_CACHE ]] || return 0
  prune_path "$TEST_SCRIPT"
  prune_path "$BASH_SOURCE"
}

trap 'EXIT_CODE=$?; rm -rf $TSH_TMPDIR; exit_trap' EXIT
trap err_trap ERR
config_defaults
load_config
push_err_handler "create_nonzero_implicit_exception"
setup_io
push_exit_handler "cleanup"
[[ -z $CONFIG_FILE ]] || log "Loaded config from $CONFIG_FILE"
init_prune_path_cache
load_includes
push_exit_handler "[[ -v MANAGED ]] || call_teardown teardown_test_suite"
push_exit_handler "[[ -v MANAGED || -n \$teardown_test_called ]] || call_teardown teardown_test"
push_exit_handler "[[ -v MANAGED ]] || display_last_test_result"

[[ ! $DEBUG ]] || set -x
