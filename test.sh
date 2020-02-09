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

set -o errexit -o errtrace -o pipefail
shopt -s inherit_errexit expand_aliases

alias try="_try;(set -e;trap 'err_trap' ERR;"
alias catch:=");_catch&&{"
alias catch=");_catch "
alias nonzero:="'nonzero'&&{"
alias endtry="};_endtry"

check_pending_exceptions() {
  [[ ! -f $EXCEPTIONS_FILE ]] || {
    throw "error.dangling-exception" "Pending exception, probably a masked error in command substitution"; }
}

_try() {
  push_caught_exception
  set +e
  # in case the try block executes exit instead of throw
  trap 'ERR_CODE=$?; [ -f "$EXCEPTIONS_FILE" ] || create_nonzero_implicit_exception 1' ERR
}

push_try_exit_code() {
  TRY_EXIT_CODE=$?
  TRY_EXIT_CODES=("$TRY_EXIT_CODE" "${TRY_EXIT_CODES[@]}")
}

pop_try_exit_code() {
  TRY_EXIT_CODE=$TRY_EXIT_CODES
  TRY_EXIT_CODES=("${TRY_EXIT_CODES[@]:1}")
}

push_caught_exception() {
  CAUGHT_EXCEPTIONS=("$EXCEPTION" "${CAUGHT_EXCEPTIONS[@]}")
}

pop_caught_exception() {
  EXCEPTION=$CAUGHT_EXCEPTIONS
  CAUGHT_EXCEPTIONS=("${CAUGHT_EXCEPTIONS[@]:1}")
}

_catch() {
  push_try_exit_code
  if [[ $TRY_EXIT_CODE != 0 ]]; then
    local exception_filter=$1
    local exception_type=$(head -1 "$EXCEPTIONS_FILE")
    [[ $exception_type =~ ^$exception_filter ]] || exit $TRY_EXIT_CODE
    handle_exception
    set -e
    trap 'err_trap' ERR
  else
    trap - ERR
    false
  fi
}

_endtry() {
  pop_caught_exception
  pop_try_exit_code
  set -e
  trap 'err_trap' ERR
}

failed() {
  [[ $TRY_EXIT_CODE != 0 ]]
}

throw() {
  create_exception "$@"
  exit 1
}

rethrow() {
  echo "$EXCEPTION" >"$EXCEPTIONS_FILE"
  exit 1
}

create_exception() {
  local exception_type=$1
  local exception_msg=$2
  local first_frame=${3:-2}

  # TODO: save exceptions reversed so that they can be appended to the current file
  local uncaught_exceptions
  [[ ! -f $EXCEPTIONS_FILE ]] || uncaught_exceptions=$(cat "$EXCEPTIONS_FILE")
  echo "$exception_type" >"$EXCEPTIONS_FILE"
  # TODO: replace '---' mark with something unambiguous
  { echo "$exception_msg"; echo '---'; local_stack "$first_frame"; } >>"$EXCEPTIONS_FILE"
  if [[ -v CAUSED_BY ]]; then
    { echo "chained:Caused by:"; echo "$EXCEPTION"; } >>"$EXCEPTIONS_FILE"
  fi
  # TODO: replace 'chained:' mark with something unambiguous
  if [[ $uncaught_exceptions ]]; then
    local chain_reason=${CHAIN_REASON:-Pending exception}
    { echo "chained:$chain_reason:"; echo "$uncaught_exceptions"; } >>"$EXCEPTIONS_FILE"
  fi
}

create_nonzero_implicit_exception() {
  local err=$ERR_CODE
  local errcmd=$(echo -n "$BASH_COMMAND" | head -1)
  local frame_idx=${1:-2}
  prune_path "${BASH_SOURCE[$frame_idx]}"
  local errmsg="Error in ${FUNCNAME[$frame_idx]}($PRUNED_PATH:${BASH_LINENO[$frame_idx-1]}): '${errcmd}' exited with status $err"
  ((frame_idx+=2))
  CHAIN_REASON='Previous exception' create_exception 'nonzero.implicit' "$errmsg" $frame_idx
}

#mutate_exception() {
#  local exception_type=$1
#  local exception_msg=$2
#  echo "$exception_type" >"$EXCEPTIONS_FILE".tmp
#  { echo "$exception_msg"; tail -n +2 "$EXCEPTIONS_FILE"; } >>"$EXCEPTIONS_FILE".tmp
#  rm -f "$EXCEPTIONS_FILE"
#  mv "$EXCEPTIONS_FILE".tmp "$EXCEPTIONS_FILE"
#}

prune_path() {
  if [[ $1 && $1 != environment ]]; then
    if [[ ${PRUNE_PATH_CACHE[$1]} ]]; then
      PRUNED_PATH=${PRUNE_PATH_CACHE[$1]}
    else
      local path
      path=$(realpath "$1")
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
    prune_path "${BASH_SOURCE[$i+1]}"
    local frame="${FUNCNAME[$i+1]}($PRUNED_PATH:${BASH_LINENO[$i]})"
    echo "$frame"
  done
}

handle_exception() {
  if [ -f "$EXCEPTIONS_FILE" ]; then
    EXCEPTION=$(cat "$EXCEPTIONS_FILE")
    rm -f "$EXCEPTIONS_FILE"
    return 0
  fi
  false
}

print_exception() {
  local exception_type
  ( while read -r exception_type; do
      while read -r line; do
        [[ $line != '---' ]] || break
        log_err "$line"
      done
      while read -r line; do
        if [[ $line =~ ^'chained:' ]]; then
          log_err "${line#chained:}"
          break
        fi
        log_err " at $line"
      done
    done
  ) <<<"$EXCEPTION"
}

eval_throw_syntax() {
  trap "throw_eval_syntax_error_exception \"$1\"" EXIT; eval 'trap - EXIT;' "$1"
}

throw_eval_syntax_error_exception() {
  local errmsg="Syntax error in the expression: \"$1\""
  throw 'error.eval-syntax-error' "$errmsg" 3
}

unhandled_exception() {
  if handle_exception; then
    print_exception
    EXCEPTION=
  fi
}

exit_trap() {
  EXIT_CODE=$?
  unhandled_exception
  [[ -z $PIPE ]] || rm -f "$PIPE"
  for handler in "${EXIT_HANDLERS[@]}"; do
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
  [[ -v MANAGED || -v FIRST_TEST ]] || { teardown_test_called=1; call_teardown 'teardown_test'; }
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
  push_err_handler 'error_setup_test_suite'
  call_if_exists 'setup_test_suite'
  pop_err_handler
}

call_teardown() {
  try
    call_if_exists "$1"
  catch:
    print_exception
    warn_teardown_failed "$1"
  endtry
}

run_test_script() {
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
  "$test_func"
  CURRENT_TEST_NAME=${CURRENT_TEST_NAME:-$test_func}
  display_test_passed
  call_teardown 'teardown_test'
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
    try
      run_test "$test_func"
    catch:
      print_exception
      failed=1
      CURRENT_TEST_NAME=${CURRENT_TEST_NAME:-$test_func}; display_test_failed;
      call_teardown 'teardown_test'
    endtry
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
  call_teardown 'teardown_test_suite'
  if [[ $failures != 0 ]]; then
    log_err "$failures test(s) failed"
    exit 5
  fi
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
  check_pending_exceptions
  local what=$1
  local msg=$2
  local why="expected success but got failure in: '$what'"
  try
    eval_throw_syntax "$what"
  catch nonzero:
    CAUSED_BY= throw 'nonzero.explicit.assert' "$(assert_msg "$msg" "$why")"
  endtry
}

assert_false() {
  check_pending_exceptions
  local what=$1
  tsh_assert_msg=$2
  tsh_assert_why="expected failure but got success in: '$what'"
  try
    eval_throw_syntax "$what"
  catch nonzero: true
  endtry
  failed || throw 'nonzero.explicit.assert' "$(assert_msg "$tsh_assert_msg" "$tsh_assert_why")"
}

assert_equals() {
  check_pending_exceptions
  local expected=$1
  local current=$2
  local msg=$3
  tsh_assert_msg=$msg
  tsh_assert_why="expected '$expected' but got '$current'"
  [[ "$expected" = "$current" ]] || throw 'nonzero.explicit.assert' "$(assert_msg "$tsh_assert_msg" "$tsh_assert_why")"
}

VERSION=@VERSION@
TEST_SCRIPT=$(readlink -f "$0")
TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
TESTSH=$(readlink -f "$BASH_SOURCE")
TESTSH_DIR=$(dirname "$TESTSH")
TEST_TMP=$TEST_SCRIPT_DIR/tmp
rm -rf "$TEST_TMP"
mkdir -p "$TEST_TMP"

FIRST_TEST=
TSH_TMP_PFX=${TMPDIR:-/tmp}/tsh-$$
EXCEPTIONS_FILE=$TSH_TMP_PFX-stack
declare -A PRUNE_PATH_CACHE

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
  [[ $SUBTEST_LOG_CONFIG != noredir ]] || return 0
  mkdir -p "$(dirname "$LOG_FILE")"
  if [[ $VERBOSE ]]; then
    PIPE=$TSH_TMP_PFX-pipe
    mkfifo "$PIPE"
    local redir=
    [[ $LOG_MODE = overwrite ]] || redir=-a
    tee $redir <"$PIPE" "$LOG_FILE" &
    exec 3>&1 4>&2 >"$PIPE" 2>&1
  else
    PIPE=
    local redir=\>
    [[ $LOG_MODE = overwrite ]] || redir=\>$redir
    eval exec 3\>\&1 4\>\&2 $redir"$LOG_FILE" 2\>\&1
  fi
}

config_defaults() {
  default_VERBOSE=
  default_DEBUG=
  default_INCLUDE_GLOB='include*.sh'
  default_INCLUDE_PATH='$TESTSH_DIR/$INCLUDE_GLOB:$TEST_SCRIPT_DIR/$INCLUDE_GLOB'
  default_FAIL_FAST=1
  default_PRUNE_PATH='$PWD/'
  default_STACK_TRACE='full'
  default_TEST_MATCH='^test_'
  default_COLOR='yes'
  # TODO: log would be better
  default_LOG_DIR_NAME='testout'
  default_LOG_DIR='$TEST_SCRIPT_DIR/$LOG_DIR_NAME'
  default_LOG_NAME='$(basename "$TEST_SCRIPT").out'
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
    for path in $CONFIG_PATH; do
      if [[ -f $path/test.sh.config ]]; then
        CONFIG_FILE=$path/test.sh.config
        load_config_file "$CONFIG_FILE"
        break
      fi
    done
  }

  local config_vars="VERBOSE DEBUG INCLUDE_GLOB INCLUDE_PATH FAIL_FAST PRUNE_PATH STACK_TRACE TEST_MATCH COLOR LOG_DIR_NAME LOG_DIR LOG_NAME LOG_FILE LOG_MODE SUBTEST_LOG_CONFIG INITIALIZE_SOURCE_CACHE CLEAN_TEST_TMP"

  # save environment config
  for var in $config_vars; do
    save_variable "$var"
  done

  # load config file if present
  [ -z "$CONFIG_FILE" ] || load_config_file "$CONFIG_FILE"
  [ -n "$CONFIG_FILE" ] || IFS=':' try_config_path

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

trap 'exit_trap' EXIT
trap 'err_trap' ERR
config_defaults
load_config
push_err_handler 'create_nonzero_implicit_exception'
setup_io
push_exit_handler 'cleanup'
[[ -z $CONFIG_FILE ]] || log "Configuration: $CONFIG_FILE"
init_prune_path_cache
load_includes
# TODO: inline mode can call teardown_test_suite when setup has not been called
push_exit_handler '[[ -v MANAGED ]] || call_teardown teardown_test_suite'
# TODO: inline mode can call teardown_test when setup has not been called
push_exit_handler '[[ -v MANAGED || -n $teardown_test_called ]] || call_teardown teardown_test'
push_exit_handler '[[ -v MANAGED ]] || display_last_test_result'

[[ ! $DEBUG ]] || set -x
