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

set -o errexit -o errtrace -o pipefail
shopt -s inherit_errexit expand_aliases

alias @test:='define_test'
alias @body:='validate@body'
alias @skip='SKIP=1 '
alias @setup_fixture:='setup_test_suite()'
alias @teardown_fixture:='teardown_test_suite()'
alias @setup:='setup_test()'
alias @teardown:='teardown_test()'
alias @run_tests='run_tests'
declare -A testdescs testskip
TEST_NUM=1

define_test() {
  testfunc=test_$(printf "%02d" "$TEST_NUM")
  testfuncs[$TEST_NUM]=$testfunc
  testskip[$testfunc]=$SKIP
  testdescs[$testfunc]=${1:-$testfunc}
  eval "alias @body:='validate@body; $testfunc()'"
  ((TEST_NUM++))
}

validate@body() {
  [[ -v testfunc ]] || throw 'test_syntax' 'Misplaced @body tag'
  unset testfunc
}

alias try:="_try;(_try_prolog;"
alias catch:="_try_epilog);_catch&&{"
alias catch="_try_epilog);_catch "
alias :="&&{"
alias success:="}; _success&&{"
alias endtry="};_endtry"
alias chain:='CAUSED_BY= '

declare -A exceptions

declare_exception() {
  local exception=$1
  local super=$2
  exceptions[$exception]=$super
  type_of_exception $exception
  eval "alias $exception:=\"$exception_type&&{\""
  eval "alias $exception,=\"$exception_type&&{\" "
}

type_of_exception() {
  exception_type=$1
  local x=$exception_type
  while [[ ${exceptions[$x]} ]]; do
    x=${exceptions[$x]}
    exception_type=$x.$exception_type
  done
}

declare_exception nonzero
declare_exception implicit nonzero
declare_exception assert nonzero
declare_exception error
declare_exception internal error
declare_exception test_syntax error
declare_exception pending_exception error
declare_exception eval_syntax_error error

_try() {
  push_caught_exception
  set +e
  # in case the try block executes exit instead of throw
  trap 'ERR_CODE=$?; [ -f "$EXCEPTIONS_FILE" ] || create_implicit_exception 1' ERR
}

_try_prolog() {
  set -e
  trap 'err_trap' ERR
}

_try_epilog() {
  check_pending_exceptions
}

_catch() {
  push_try_exit_code
  if [[ $TRY_EXIT_CODE != 0 ]]; then
    local exception_type
    read -r exception_type <"$EXCEPTIONS_FILE" || throw 'internal' 'Try block failed but no exception generated'
    local exception_filter
    for exception_filter in "$@"; do
      [[ $exception_type =~ ^$exception_filter ]] || exit "$TRY_EXIT_CODE"
    done
    handle_exception
    set -e
    trap 'err_trap' ERR
  else
    trap - ERR
    false
  fi
}

_success() {
  [[ $TRY_EXIT_CODES = 0 ]]
}

_endtry() {
  pop_caught_exception
  pop_try_exit_code
  set -e
  trap 'err_trap' ERR
}

check_pending_exceptions() {
  [[ ! -f $EXCEPTIONS_FILE ]] ||
    throw 'pending_exception' 'Pending exception, probably a masked error in a command substitution'
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

failed() {
  [[ $TRY_EXIT_CODE != 0 ]]
}

throw() {
  first_frame=$first_frame create_exception "$@"
  exit ${exit_code:-1}
}

rethrow() {
  echo "$EXCEPTION" >"$EXCEPTIONS_FILE"
  exit "$TRY_EXIT_CODE"
}

create_exception() {
  local exception=$1
  local exception_msg=$2
  local first_frame=${first_frame:-2}

  local uncaught_exceptions
  [[ ! -f $EXCEPTIONS_FILE ]] || uncaught_exceptions=$(cat "$EXCEPTIONS_FILE")
  type_of_exception "$exception"
  echo "$exception_type" >"$EXCEPTIONS_FILE"
  # TODO: replace '---' mark with something unambiguous
  { echo "$exception_msg"; echo '---'; local_stack "$first_frame"; } >>"$EXCEPTIONS_FILE"
  if [[ -v CAUSED_BY ]]; then
    { echo "chained:Caused by:"; echo "$EXCEPTION"; } >>"$EXCEPTIONS_FILE"
  fi
  # TODO: replace 'chained:' mark with something unambiguous
  if [[ $uncaught_exceptions ]]; then
    # TODO: only implicit and pending_exception exceptions should chain, others should throw a
    #       pending exceptions found while handling exception ...
    local chain_reason=${CHAIN_REASON:-Pending exception}
    { echo "chained:$chain_reason:"; echo "$uncaught_exceptions"; } >>"$EXCEPTIONS_FILE"
  fi
}

create_implicit_exception() {
  local err=$ERR_CODE
  local errcmd=
  # TODO: truncate... do better
  read -r errcmd <<<"$BASH_COMMAND" || true
  local frame_idx=${1:-2}
  prune_path "${BASH_SOURCE[$frame_idx]}"
  local errmsg="Error in ${FUNCNAME[$frame_idx]}($PRUNED_PATH:${BASH_LINENO[$frame_idx-1]}): '${errcmd}' exited with status $err"
  first_frame=$((frame_idx+2)) CHAIN_REASON='Previous exception' create_exception 'implicit' "$errmsg"
}

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
    echo "${FUNCNAME[$i+1]}($PRUNED_PATH:${BASH_LINENO[$i]})"
  done
}

handle_exception() {
  EXCEPTION=$(cat "$EXCEPTIONS_FILE")
  rm -f "$EXCEPTIONS_FILE"
}

print_exception() {
  local log_function=${1:-log_err}
  local exception_type
  while read -r exception_type; do
      while read -r line; do
        [[ $line != '---' ]] || break
        $log_function "$line"
      done
      while read -r line; do
        if [[ $line =~ ^'chained:' ]]; then
          $log_function "${line#chained:}"
          break
        fi
        $log_function " at $line"
      done
    done <<<"$EXCEPTION"
}

_eval() {
  if [[ $BASHPID == $$ ]]; then
    trap "EXIT_CODE=$?; create_eval_syntax_error_exception $(printf "%q" "$1"); exit_trap" EXIT; eval 'trap exit_trap EXIT;' "$1"
  else
    trap "create_eval_syntax_error_exception $(printf "%q" "$1")" EXIT; eval 'trap - EXIT;' "$1"
  fi
}

create_eval_syntax_error_exception() {
  local errmsg="Syntax error in the expression: $1"
  create_exception 'eval_syntax_error' "$errmsg"
}

unhandled_exception() {
  handle_exception
  print_exception
  EXCEPTION=
}

exit_trap() {
  EXIT_CODE=${EXIT_CODE:-$?}
  [[ ! -f $EXCEPTIONS_FILE ]] || unhandled_exception
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
  [[ ! -v MANAGED ]] || return
  # TODO: check pending exceptions after the last inline test
  check_pending_exceptions
  if [[ -v FIRST_TEST ]]; then
    setup_test_suite_called=1
    call_setup_test_suite
    unset FIRST_TEST
  else
    display_test_passed
    unset CURRENT_TEST_NAME
    teardown_test_called=1
    call_teardown 'teardown_test'
  fi
  CURRENT_TEST_NAME="$1"
  teardown_test_called=; call_if_exists setup_test
  log "Start test: $CURRENT_TEST_NAME"
}

display_test_passed() {
  log_ok "PASSED: ${CURRENT_TEST_NAME}"
  echo -e "${GREEN}* ${CURRENT_TEST_NAME}${NC}" >&3
}

display_test_failed() {
  log_err "FAILED: ${CURRENT_TEST_NAME}"
  echo -e "${RED}* ${CURRENT_TEST_NAME}${NC}" >&3
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

call_setup_test_suite() {
  declare -f 'setup_test_suite' >/dev/null || return 0
  try:
    setup_test_suite
  catch:
    echo -e "${RED}[ERROR] setup_test_suite failed, see ${LOG_FILE##$PRUNE_PATH} for more information${NC}" >&3
    rethrow
  endtry
}

call_teardown() {
  try:
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
#  BASH_ENV=<(declare -p PRUNE_PATH_CACHE) SUBTEST='' "$test_script" "$@"
  "$test_script" "$@"
}

run_tests() {
  MANAGED=
  local failures=0
  local test_func
  call_setup_test_suite
  for test_func in "${testfuncs[@]}"; do
    if [[ $failures > 0 && $FAIL_FAST || ${testskip[$test_func]} ]]; then
      display_test_skipped "${testdescs[$test_func]}"
      continue
    fi

    CURRENT_TEST_NAME=${testdescs[$test_func]}
    try:
      log "Start test: $CURRENT_TEST_NAME"
      call_if_exists setup_test
      "$test_func"
    catch:
      print_exception
      display_test_failed
      call_teardown 'teardown_test'
      failures=$(( failures + 1 ))
    success:
      display_test_passed
      call_teardown 'teardown_test'
    endtry
  done

  call_teardown 'teardown_test_suite'
  if [[ $failures != 0 ]]; then
    log_err "$failures test(s) failed"
    exit 1
  fi
}

load_includes() {
  load_include_file() {
    local include_file=$1
    source "$include_file"
    log "Included: $include_file"
    [[ ! $INITIALIZE_SOURCE_CACHE ]] || prune_path "$include_file"
  }

  local include_files=()
  local saved_IFS=$IFS
  IFS=":"
  for path in $INCLUDE_PATH; do
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

throw_assert() {
  throw 'assert' "$(assert_msg "$1" "$2")"
}

assert_success() {
  check_pending_exceptions
  local what=$1
  local msg=$2
  try:
    _eval "$what"
  catch nonzero:
    local why="expected success but got failure in: '$what'"
    chain: throw_assert "$msg" "$why"
  endtry
}

assert_failure() {
  check_pending_exceptions
  local what=$1
  local msg=$2
  try:
    _eval "$what"
  catch nonzero:
    log "Expected failure:"
    print_exception log
  success:
    local why="expected failure but got success in: '$what'"
    throw_assert "$msg" "$why"
  endtry
}

assert_equals() {
  check_pending_exceptions
  local expected=$1
  local current=$2
  local msg=$3
  [[ "$expected" = "$current" ]] || {
    local why="expected '$expected' but got '$current'"
    throw_assert "$msg" "$why"
  }
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

inline_exit_handler() {
  [[ ! -v CURRENT_TEST_NAME ]] || display_last_test_result
  [[ -n $teardown_test_called || -v FIRST_TEST ]] || call_teardown teardown_test
  [[ -z $setup_test_suite_called ]] || call_teardown teardown_test_suite
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
  default_FAIL_FAST=
  default_PRUNE_PATH='$PWD/'
  default_STACK_TRACE='full'
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

  local config_vars="VERBOSE DEBUG INCLUDE_GLOB INCLUDE_PATH FAIL_FAST PRUNE_PATH STACK_TRACE COLOR LOG_DIR_NAME LOG_DIR LOG_NAME LOG_FILE LOG_MODE SUBTEST_LOG_CONFIG INITIALIZE_SOURCE_CACHE CLEAN_TEST_TMP"

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
push_err_handler 'create_implicit_exception'
setup_io
push_exit_handler 'cleanup'
[[ -z $CONFIG_FILE ]] || log "Configuration: $CONFIG_FILE"
init_prune_path_cache
load_includes
push_exit_handler '[[ -v MANAGED ]] || inline_exit_handler'

[[ ! $DEBUG ]] || set -x
