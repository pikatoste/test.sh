#!/bin/bash
#
@LICENSE@
#
# See https://github.com/pikatoste/test.sh/
#

[[ ! $_TESTS_RUNNER ]] || return 0

set -o errexit -o errtrace -o pipefail
shopt -s inherit_errexit expand_aliases

alias @test:='define_test'
alias @body:='validate@body'
alias @skip='_SKIP=1 '
alias @setup_fixture:='setup_test_suite()'
alias @teardown_fixture:='teardown_test_suite()'
alias @setup:='setup_test()'
alias @teardown:='teardown_test()'
declare -A '_testdescs' '_testskip'
_TEST_NUM=1

define_test() {
  printf -v '_testfunc' 'test_%02d' "$_TEST_NUM"
  _testfuncs[_TEST_NUM]=$_testfunc
  _testskip[$_testfunc]=$_SKIP
  _testdescs[$_testfunc]=${1:-$_testfunc}
  eval "alias @body:='validate@body; $_testfunc()'"
  ((_TEST_NUM++))
}

validate@body() {
  [[ -v _testfunc ]] || throw 'test_syntax' 'Misplaced @body: tag'
  unset '_testfunc' '_SKIP'
}

alias try:="_try;(_try_prolog;"
alias catch:=");_catch ''&&{"
alias catch=");_catch "
alias success:="}; _success&&{ enable_exceptions;"
alias endtry="};_endtry"
alias with_cause:='WITH_CAUSE= '
alias exit='_exit'

_TMP_BASE=${TMPDIR:-/tmp}/tsh-$$
_EXCEPTIONS_FILE=$_TMP_BASE'-exceptions'
_TRY_VARS_FILE=$_TMP_BASE'-tryvars'
_ERR_FILE=$_TMP_BASE'-err'
declare -A '_exceptions' '_exception_types'
declare -A '_EXIT_HANDLERS' '_PRUNE_PATH_CACHE'

declare_exception() {
  local exception=$1 super=$2
  _exceptions[$exception]=$super
  type_of_exception $exception
  _exception_types[$exception]=$exception_type
  eval "alias $exception:=\"$exception_type&&{\"; alias $exception,=\"$exception_type \""
}

type_of_exception() {
  exception_type=$1
  local x=$exception_type
  while [[ ${_exceptions[$x]} ]]; do
    x=${_exceptions[$x]}
    exception_type=$x.$exception_type
  done
}

exception_is() {
  local exception_type=${_exception_types[${_EXCEPTION[-1]}]:-${_EXCEPTION[-1]}}
  local exception_filter=${_exception_types[$1]:-$1}
  [[ $exception_type =~ ^$exception_filter ]]
}

declare_exception 'nonzero'
declare_exception 'implicit' 'nonzero'
declare_exception 'assert' 'nonzero'
declare_exception 'error'
declare_exception 'test_syntax' 'error'
declare_exception 'pending_exception' 'error'
declare_exception 'eval_syntax' 'error'

with_vars() {
  _TRY_VARS=$*
}

_try() {
  push_caught_exception
  set +e
  trap - ERR
}

save_vars() {
  declare -p "$@" >"$_TRY_VARS_FILE"
}

restore_vars() {
  alias 'declare=declare -g'
  source "$_TRY_VARS_FILE"
  unalias 'declare'
}

_exit() {
  _EXPLICIT_EXIT=1
  builtin exit $1
}

_exit() {
  _EXPLICIT_EXIT=1
  builtin exit $1
}

check_exit_exception() {
  # in case the ERR trap is not called but the exit status of a command different from exit is non-zero
  [[ $_EXIT_CODE = 0 || -f $_EXCEPTIONS_FILE || $_EXPLICIT_EXIT ]] ||
    first_frame=6 BASH_COMMAND=$_EXIT_COMMAND create_implicit_exception "$_EXIT_CODE"
}

try_exit_handler() {
  check_exit_exception
  [[ $# = 0 ]] || save_vars "$@"
}

_try_prolog() {
  enable_exceptions
  # TODO: glob expansion in _TRY_VARS
  push_exit_handler "try_exit_handler $_TRY_VARS"
}

_catch() {
  push_try_exit_code
  # TODO: _TRY_VARS corruption in try in catch
  [[ ! $_TRY_VARS ]] || restore_vars
  [[ -f $_EXCEPTIONS_FILE ]] || {
    [[ $_TRY_EXIT_CODE != 0 ]] || return 1
    builtin exit "$_TRY_EXIT_CODE"
  }
  [[ $_TRY_EXIT_CODE != 0 ]] ||
    create_exception 'pending_exception' "$_pending_exception_msg"
  readarray -t _EXCEPTION <"$_EXCEPTIONS_FILE"
  local exception_type=${_exception_types[${_EXCEPTION[-1]}]:-${_EXCEPTION[-1]}} exception_filter
  for exception_filter in "$@"; do
    [[ $exception_type =~ ^$exception_filter ]] || continue
    rm -f "$_EXCEPTIONS_FILE"
    enable_exceptions
    return 0
  done
  builtin exit "$_TRY_EXIT_CODE"
}

enable_exceptions() {
  set -e
  trap 'err_trap' ERR
}

_success() {
  [[ $_TRY_EXIT_CODES = 0 ]]
}

_endtry() {
  pop_caught_exception
  pop_try_exit_code
  enable_exceptions
}

_pending_exception_msg='Pending exception, probably a masked error in a command substitution'

check_pending_exceptions() {
  [[ ! -f $_EXCEPTIONS_FILE ]] ||
    throw 'pending_exception' "$_pending_exception_msg"
}

push_try_exit_code() {
  _TRY_EXIT_CODE=$?
  _TRY_EXIT_CODES=("$_TRY_EXIT_CODE" "${_TRY_EXIT_CODES[@]}")
}

pop_try_exit_code() {
  _TRY_EXIT_CODE=$_TRY_EXIT_CODES
  _TRY_EXIT_CODES=("${_TRY_EXIT_CODES[@]:1}")
}

push_caught_exception() {
  [[ ! -v _EXCEPTION ]] || _CAUGHT_EXCEPTIONS=("${_EXCEPTION[*]@A}" "${_CAUGHT_EXCEPTIONS[@]}")
}

pop_caught_exception() {
  if (( ${#_CAUGHT_EXCEPTIONS[@]} > 0 )); then
    eval "$_CAUGHT_EXCEPTIONS"
    _CAUGHT_EXCEPTIONS=("${_CAUGHT_EXCEPTIONS[@]:1}")
  else
    unset '_EXCEPTION'
  fi
}

failed() {
  [[ $_TRY_EXIT_CODE != 0 ]]
}

throw() {
  create_exception "$@"
  builtin exit ${exit_code:-1}
}

rethrow() {
  printf "%s\n" "${_EXCEPTION[@]}" >"$_EXCEPTIONS_FILE"
  builtin exit "$_TRY_EXIT_CODE"
}

create_exception() {
  local exception=$1
  local exception_msg=$2
  local first_frame=${first_frame:-2}

  # TODO: only implicit and pending_exception exceptions should chain, others should throw a
  #       pending exceptions found while handling exception ...
  if [[ -f $_EXCEPTIONS_FILE ]]; then
    local chain_reason=${CHAIN_REASON:-'Pending exception'}
    echo -e "${_RED}$chain_reason:${_NC}" >>"$_EXCEPTIONS_FILE"
  fi
  if [[ -v WITH_CAUSE ]]; then
    { printf "%s\n" "${_EXCEPTION[@]}"; echo "Caused by:"; } >>"$_EXCEPTIONS_FILE"
  fi
  local 'msg_lines' i
  readarray -t 'msg_lines' <<<"$exception_msg"
  { stack_trace "$first_frame"
    for ((i=${#msg_lines[@]}-1; i>=0; i--)); do
      echo "${msg_lines[i]}"
    done
    printf "%d\n%s\n" "${#msg_lines[@]}" "$exception"; } >>"$_EXCEPTIONS_FILE"
}

create_implicit_exception() {
  local err=$1
  local exception=${2:-'implicit'}

  local errcmd
  # TODO: truncate... do better
  read -r errcmd <<<"$BASH_COMMAND"
  local first_frame=${first_frame:-4}
  local frame_idx=$((first_frame-2))
  prune_path "${BASH_SOURCE[frame_idx]}"
  local errmsg="Error in ${FUNCNAME[frame_idx]}($_PRUNED_PATH:${BASH_LINENO[frame_idx-1]}): '${errcmd}' exited with status $err"
  [[ ! -f $_EXCEPTIONS_FILE ]] || {
    local 'pending_exception'
    readarray -t 'pending_exception' <"$_EXCEPTIONS_FILE"
    exception=${pending_exception[-1]}
  }
  first_frame=$first_frame CHAIN_REASON='Previous exception' create_exception "$exception" "$errmsg"
}

prune_path() {
  if [[ $1 && $1 != 'environment' ]]; then
    if [[ ${_PRUNE_PATH_CACHE[$1]} ]]; then
      _PRUNED_PATH=${_PRUNE_PATH_CACHE[$1]}
    else
      local path
      path=$(realpath "$1")
      _PRUNE_PATH_CACHE[$1]=${path##$PRUNE_PATH}
      _PRUNED_PATH=${_PRUNE_PATH_CACHE[$1]}
    fi
  else
    _PRUNED_PATH="$1"
  fi
}

stack_trace() {
  if [[ $STACK_TRACE != 'no' ]]; then
    local i
    for ((i=${#FUNCNAME[@]}-2; i>=${1:-0}; i--))
    do
      prune_path "${BASH_SOURCE[i+1]}"
      echo "${FUNCNAME[i+1]}($_PRUNED_PATH:${BASH_LINENO[i]})"
    done
    echo "$((${#FUNCNAME[@]}-2-i))"
  else
    echo '0'
  fi
}

handle_exception() {
  readarray -t '_EXCEPTION' <"$_EXCEPTIONS_FILE"
  rm -f "$_EXCEPTIONS_FILE"
}

print_exception() {
  local log_function=${1:-'log_err'} i 'exception' 'msg_count'
  for ((i=${#_EXCEPTION[@]}-1; i>=0; i--)); do
    exception=${_EXCEPTION[i--]}
    msg_count=$((i-${_EXCEPTION[i]}))
      "$log_function" "$exception exception: ${_EXCEPTION[--i]}"
    for ((i--; i>=msg_count; i--)); do
      "$log_function" "${_EXCEPTION[i]}"
    done
    msg_count=$((i-${_EXCEPTION[i]}))
    for ((i--; i>=msg_count; i--)); do
      "$log_function" " at ${_EXCEPTION[i]}"
    done
    ((i<0)) || "$log_function" "${_EXCEPTION[i]}"
  done
}

_eval() {
  push_exit_handler "create_eval_syntax_exception ${*@Q}"
  { eval '{ pop_exit_handler;' "$@" '; } 2>&5' ; } 5>&2 2>"$_ERR_FILE"
}

create_eval_syntax_exception() {
  local errmsg
  printf -v errmsg "Syntax error in the expression: %s\n%s" "$*" "$(cat "$_ERR_FILE")"
  first_frame=3 create_exception 'eval_syntax' "$errmsg"
}

unhandled_exception() {
  [[ $_EXIT_CODE != 0 ]] || first_frame=1 create_exception 'pending_exception' "$_pending_exception_msg"
  handle_exception
  print_exception
  unset '_EXCEPTION'
}

exit_trap() {
  _EXIT_CODE=$?
  _EXIT_COMMAND=$BASH_COMMAND
  local handler i
  for ((i=${_EXIT_HANDLERS[$BASHPID]}-1; i>=0; i--)); do
    handler=${_EXIT_HANDLERS[$BASHPID-$i]}
    eval "$handler"
  done
}

push_exit_handler() {
  local handler_count=${_EXIT_HANDLERS[$BASHPID]}
  [[ $handler_count ]] || { trap 'exit_trap' EXIT; handler_count=0; }
  _EXIT_HANDLERS[$BASHPID-$handler_count]=$1
  _EXIT_HANDLERS[$BASHPID]=$((handler_count+1))
}

pop_exit_handler() {
  local handler_count=${_EXIT_HANDLERS[$BASHPID]}
  _EXIT_HANDLERS[$BASHPID]=$((handler_count-1))
}

err_trap() {
  _ERR_CODE=$?
  for handler in "${_ERR_HANDLERS[@]}"; do
    eval "$handler" || true
  done
}

push_err_handler() {
  _ERR_HANDLERS=("$1" "${_ERR_HANDLERS[@]}")
}

pop_err_handler() {
  _ERR_HANDLERS=("${_ERR_HANDLERS[@]:1}")
}

display_last_inline_test_result() {
  if [[ $_EXIT_CODE == 0 ]]; then
    display_test_passed
  else
    display_test_failed
  fi
}

start_test() {
  [[ ! -v _MANAGED ]] || return
  check_pending_exceptions
  if [[ $_FIRST_TEST ]]; then
    _setup_test_suite_called=1
    call_setup_test_suite
    _FIRST_TEST=
  else
    display_test_passed
    unset _CURRENT_TEST_NAME
    _teardown_test_called=1
    call_teardown 'teardown_test'
  fi
  _CURRENT_TEST_NAME="$1"
  _teardown_test_called=
   ! function_exists 'setup_test' || setup_test
  log_info "Start test: $_CURRENT_TEST_NAME"
}

display_test_passed() {
  log_ok "PASSED: ${_CURRENT_TEST_NAME}"
  printf "${_GREEN}%${_cols:+.$_cols}s${_NC}\n" "${_INDENT}* ${_CURRENT_TEST_NAME}" >&3
  ((++_lines_out))
}

display_test_failed() {
  log_err "FAILED: ${_CURRENT_TEST_NAME}"
  printf "${_RED}%${_cols:+.$_cols}s${_NC}\n" "${_INDENT}* ${_CURRENT_TEST_NAME}" >&3
  ((++_lines_out))
}

display_test_skipped() {
  printf "${_BLUE}%${_cols:+.$_cols}s${_NC}\n" "${_INDENT}* [skipped] $1" >&3
  ((++_lines_out))
}

warn_teardown_failed() {
  printf "${_ORANGE}%${_cols:+.$_cols}s${_NC}\n" "${_INDENT}WARN: $1 failed" >&3
  ((++_lines_out))
}

do_log() {
  echo -e "$*"
}

log_info() {
  do_log "${_BLUE}[test.sh]${_NC} $*"
}

log_ok() {
  do_log "${_GREEN}[test.sh]${_NC} $*"
}

log_warn() {
  do_log "${_ORANGE}[test.sh]${_NC} $*"
}

log_err() {
  do_log "${_RED}[test.sh]${_NC} $*" >&2
}

function_exists() {
  declare -f "$1" >/dev/null
}

call_setup_test_suite() {
  function_exists 'setup_test_suite' || return 0
  push_err_handler 'echo -e "${_RED}[ERROR] setup_test_suite failed, see ${LOG_FILE##$PRUNE_PATH} for more information${_NC}" >&3; ((++_lines_out))'
  setup_test_suite
  pop_err_handler
}

call_teardown() {
  function_exists "$1" || return 0
  try:
    "$1"
  catch:
    warn_teardown_failed "$1"
    print_exception
  endtry
}

run_test_script() {
  local test_script
  test_script=$(cd "$TEST_SCRIPT_DIR"; realpath "$1")
  shift
#  BASH_ENV=<(declare -p _PRUNE_PATH_CACHE) _SUBTEST='' "$test_script" "$@"
  "$test_script" "$@"
}

_spinner_chars=(- \\ \| /)
create_spinner() {
  ( set +e
    trap - ERR
    trap "exit" INT
    tput cup "$1" "$2"
    while true; do
      for char in "${_spinner_chars[@]}"; do
        echo -n "$char"
        tput cub 1
        sleep 0.15
      done
    done
  ) &
  _spinner_pid=$!
}

kill_spinner() {
  kill -INT "$_spinner_pid"
  wait "$_spinner_pid"
}

run_tests() {
  _MANAGED=
  _failed_count=0
  _skipped_count=0
  local test_func
  call_setup_test_suite
  for test_func in "${_testfuncs[@]}"; do
    if [[ $_failed_count > 0 && $FAIL_FAST || ${_testskip[$test_func]} ]]; then
      display_test_skipped "${_testdescs[$test_func]}"
      ((++_skipped_count))
      continue
    fi

    _CURRENT_TEST_NAME=${_testdescs[$test_func]}
    [[ ! $ANIMATE ]] || {
      printf "%.${_cols}s" "${_INDENT}* ${_CURRENT_TEST_NAME}"
      line_pos
      local tlinepos=$((LINPOS))
      create_spinner "$tlinepos" "${#_INDENT}"
    } >&3
    try:
      log_info "Start test: $_CURRENT_TEST_NAME"
      ! function_exists 'setup_test' || setup_test
      "$test_func"
    catch:
      print_exception
      [[ ! $ANIMATE ]] || {
        kill_spinner
        echo -ne "\r"
      } >&3
      display_test_failed
      ((_failed_count++)) || [[ ! $ANIMATE ]] || display_test_script_outcome 1 >&3
    success:
      [[ ! $ANIMATE ]] || {
        kill_spinner
        echo -ne "\r"
      } >&3
      display_test_passed
    endtry
    call_teardown 'teardown_test'
  done

  call_teardown 'teardown_test_suite'
  if [[ $_failed_count != 0 ]]; then
    log_err "$_failed_count test(s) failed"
    [[ $_TESTS_RUNNER ]] || exit 1
  fi
}

load_includes() {
  load_include_file() {
    local include_file=$1
    source "$include_file"
    log_info "Included: $include_file"
    [[ ! $INITIALIZE_SOURCE_CACHE ]] || prune_path "$include_file"
  }

  _load_includes() {
    local include_files=() path file
    for path in $INCLUDE_PATH; do
      for file in "$path"; do
        [[ -f $file ]] && include_files=("${include_files[@]/$file}" "$file")
      done
    done
    for file in "${include_files[@]}"; do
      [[ $file ]] && load_include_file "$file"
    done
  }

  IFS=":" _load_includes
}

assert_msg() {
  local msg=$1 why=$2
  _assert_msg="Assertion failed: ${msg:+$msg, }$why"
}

throw_assert() {
  assert_msg "$1" "$2"
  first_frame=3 throw 'assert' "$_assert_msg"
}

assert_success() {
  check_pending_exceptions
  local what=$1
  local msg=$2
  try:
    _eval "$what"
  catch nonzero:
    local why="expected success but got failure in: '$what'"
    with_cause: throw_assert "$msg" "$why"
  endtry
}

assert_failure() {
  check_pending_exceptions
  local what=$1
  local msg=$2
  try:
    _eval "$what"
  catch nonzero:
    log_info "Expected failure:"
    print_exception log_info
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

set_color() {
  if [[ $COLOR = 'yes' ]]; then
    _GREEN='\033[0;32m'
    _ORANGE='\033[0;33m'
    _RED='\033[0;31m'
    _BLUE='\033[0;34m'
    _NC='\033[0m' # No Color'
  else
    unset _GREEN _ORANGE _RED _BLUE _NC
  fi
}

cleanup() {
  exec 1>&- 2>&- 1>&3 2>&4
  wait
  [[ ! $CLEAN_TEST_TMP ]] || [[ $_EXIT_CODE != 0 ]] || rm -rf "$TEST_TMP"
}

setup_io() {
  [[ $SUBTEST_LOG_CONFIG != 'noredir' ]] || return 0
  local log_dir
  log_dir=$(dirname "$LOG_FILE")
  [[ -d $log_dir ]] || mkdir -p "$log_dir"
  if [[ $VERBOSE ]]; then
    _PIPE=$_TMP_BASE-pipe
    mkfifo "$_PIPE"
    local redir=
    [[ $LOG_MODE = overwrite ]] || redir=-a
    tee $redir <"$_PIPE" "$LOG_FILE" &
    exec 3>&1 4>&2 >"$_PIPE" 2>&1
  else
    _PIPE=
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

  # undocumented
  default_SUBTEST_LOG_CONFIG='reset'
  default_INITIALIZE_SOURCE_CACHE=1
  default_CLEAN_TEST_TMP=1
}

load_config() {
  save_variable() {
    local var=$1
    [[ ! -v $var ]] || eval "saved_$var=${!var@Q}"
  }

  restore_variable() {
    local var=$1
    local saved_var=saved_$var
    [[ ! -v $saved_var ]] || eval "$var=${!saved_var@Q}"
  }

  set_default() {
    local var=$1
    local default_var=default_$var
    [[ -v $var ]] || eval "$var=\$$default_var"
  }

  eval_var() {
    local var=$1
    eval "$var=${!var}"
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

  # TODO: distinguish between normal and post-evaluated variables
  local config_vars="VERBOSE DEBUG INCLUDE_GLOB INCLUDE_PATH FAIL_FAST PRUNE_PATH STACK_TRACE COLOR LOG_DIR_NAME LOG_DIR LOG_NAME LOG_FILE LOG_MODE SUBTEST_LOG_CONFIG INITIALIZE_SOURCE_CACHE CLEAN_TEST_TMP ANIMATE"
  local var

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

  if [[ $_TESTS_RUNNER ]]; then
    for var in $config_vars; do
      save_variable "$var"
    done
  fi

  # evaluate vars
  for var in $config_vars; do
    eval_var "$var"
  done

  set_color

  # validate config
  validate_value() {
    local var=$1
    local val=${!var}
    shift
    for i in "$@"; do
      [[ $i != "$val" ]] || return 0
    done
    local allowed_values="$*"
    throw 'configuration' "invalid value of variable $var: '$val', allowed values: ${allowed_values// /, }"
  }

  # TODO: change to: no, yes... mmm what about the other booleans... not clear
  validate_value STACK_TRACE no full
  validate_value COLOR no yes
  validate_value LOG_MODE overwrite append
  validate_value SUBTEST_LOG_CONFIG reset noreset noredir
}

init_prune_path_cache() {
  local path
  [[ ! -v _SUBTEST ]] || for path in "${!_PRUNE_PATH_CACHE[@]}"; do
    _PRUNE_PATH_CACHE[$path]=${path##$PRUNE_PATH}
  done
  [[ $INITIALIZE_SOURCE_CACHE ]] || return 0
  prune_path "$TEST_SCRIPT"
  prune_path "$BASH_SOURCE"
}

main_exit_handler() {
  [[ ! -f $_EXCEPTIONS_FILE ]] || unhandled_exception
  [[ -z $_PIPE ]] || rm -f "$_PIPE"
  [[ ! -f $_TRY_VARS_FILE ]] || rm -f "$_TRY_VARS_FILE"
  [[ ! -f $_ERR_FILE ]] || rm -f "$_ERR_FILE"
}

inline_exit_handler() {
  [[ ! -v _CURRENT_TEST_NAME ]] || display_last_inline_test_result
  [[ -n $_teardown_test_called ]] || call_teardown 'teardown_test'
  [[ -z $_setup_test_suite_called ]] || call_teardown 'teardown_test_suite'
}

self_runner_exit_handler() {
  main_exit_handler
  [[ $_FIRST_TEST ]] || [[ -v _MANAGED ]] || inline_exit_handler
  cleanup
}

setup_self_runner() {
  TEST_SCRIPT=$(readlink -f "$0")
  TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
  TEST_TMP=$TEST_SCRIPT_DIR'/tmp'
  [[ -d $TEST_TMP ]] || rm -rf "$TEST_TMP"
  mkdir -p "$TEST_TMP"

  push_exit_handler 'self_runner_exit_handler'
  trap 'err_trap' ERR
  push_err_handler 'create_implicit_exception $_ERR_CODE'
  config_defaults
  load_config
  setup_io
  [[ -z $CONFIG_FILE ]] || log_info "Configuration: $CONFIG_FILE"
  init_prune_path_cache
  load_includes

  _FIRST_TEST=1
  [[ ! $DEBUG ]] || set -x
}

tests_runner_exit_handler() {
  [[ ! $ANIMATE ]] || {
    tput cnorm
    stty echo
  }
  check_exit_exception
  main_exit_handler
}

setup_tests_runner() {
  push_exit_handler 'tests_runner_exit_handler'
  trap 'err_trap' ERR
  push_err_handler 'create_implicit_exception $_ERR_CODE'
  config_defaults
  load_config
  [[ -z $CONFIG_FILE ]] || echo "Configuration: $CONFIG_FILE"
  prune_path "$BASH_SOURCE"
}

setup_test_script() {
  TEST_SCRIPT=$(readlink -f "$test_script")
  TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
  TEST_TMP=$TEST_SCRIPT_DIR'/tmp'
  [[ -d $TEST_TMP ]] || rm -rf "$TEST_TMP"
  mkdir -p "$TEST_TMP"

  for var in INCLUDE_GLOB INCLUDE_PATH PRUNE_PATH LOG_DIR_NAME LOG_DIR LOG_NAME LOG_FILE; do
    restore_variable "$var"
    eval_var "$var"
  done
  setup_io
  push_exit_handler '[[ -z $_PIPE ]] || rm -f "$_PIPE"; cleanup'
  prune_path "$TEST_SCRIPT"
  load_includes

  [[ ! $DEBUG ]] || set -x
}

TESTSH=$(readlink -f "$BASH_SOURCE")
TESTSH_DIR=$(dirname "$TESTSH")
VERSION='@VERSION@'

runner() {
  setup_tty
  print_banner
  echo "This is test.sh version @VERSION@"
  echo "Build date: $(date -d @@BUILD_TIMESTAMP@)"
  echo "See https://github.com/pikatoste/test.sh"
  echo

  alias '@run_tests='
  _TESTS_RUNNER=1
  setup_tests_runner
  _INDENT='  '
  declare 'script_failures_accum=0' 'test_count_accum=0' 'failures_accum=0' 'errors_accum=0' 'skipped_accum=0' 'TIMES' 'test_script'
  _TRY_VARS='_script_error _test_count _failed_count _skipped_count _lines_out'
  { time {
    for test_script in "$@"; do
      declare -g '_script_error=0' '_test_count=0' '_failed_count=0' '_skipped_count=0' '_lines_out=1'
      printf "%${_cols:+.$_cols}s\n" "* $test_script:"
      try:
        setup_test_script
        source "$TEST_SCRIPT"
        _test_count=${#_testfuncs[@]}
        try:
          _TRY_VARS= run_tests
          [[ $_failed_count = 0 ]] || _script_error=1
        catch:
          print_exception
          _skipped_count=$((_test_count-_failed_count-_skipped_count))
          _script_error=1
        endtry
      catch:
        print_exception log_lines
        _script_error=1
      endtry
      [[ ! $ANIMATE ]] || (( _failed_count > 0 )) || display_test_script_outcome "$_script_error"
      script_failures_accum=$((script_failures_accum+_script_error))
      test_count_accum=$((test_count_accum+_test_count))
      # TODO: count errors and failures separately
      failures_accum=$((failures_accum+_failed_count))
      skipped_accum=$((skipped_accum+_skipped_count))
    done
  } 2>&3
  } 3>&2 2>"$_TRY_VARS_FILE"
  readarray -t -s 1 -n 1 'TIMES' <"$_TRY_VARS_FILE"
  printf "%d test scripts: %d passed, %d failed\n" "$#" "$(($#-script_failures_accum))" "$script_failures_accum"
  printf "%d tests: %d passed, %d failed, %d skipped\n" "$test_count_accum" "$((test_count_accum-failures_accum-skipped_accum))" "$failures_accum" "$skipped_accum"
  printf "took %s\n" "${TIMES##*[[:space:]]}"
  exit $((script_failures_accum % 256))
}

display_test_script_outcome() {
  local outcome=$1 line
  line_pos
  line=$((LINPOS - _lines_out))
  if (( $line >= 0 )); then
    tput cup "$line" 0
    if (( outcome == 0 )); then
      printf "${_GREEN}%${_cols:+.$_cols}s${_NC}" "* $test_script:"
    else
      printf "${_RED}%${_cols:+.$_cols}s${_NC}" "* $test_script:"
    fi
    tput cup "$LINPOS" 0
  fi
}

log_lines() {
  log_err "$@"
  ((++_lines_out))
}

print_banner() {
  local BANNER="@BANNER@"

  [[ $ANIMATE ]] || { echo "$BANNER"; return 0; }

  local ABANNER i len trim real_time
  readarray -n "$_lines" 'ABANNER' <<<"$BANNER"
  ABANNER[-1]=$(echo -n "${ABANNER[-1]}")
  len=${#ABANNER}
  trim=${ABANNER//?/?}

  # calibrate delay
  alias delay='sleep 0.000'
  { line_pos; readarray -t -s 1 -n 1 'real_time' < <(
    { LANG=C
      time {
        [[ $LINPOS ]] && tput cup $((LINPOS)) 0
        trim=${trim:((${#trim}/2))}
        printf "%.${_cols}s" "${ABANNER[@]#$trim}" >/dev/null
        [[ $LINPOS ]] || line_pos
        eval delay
      } 1>&3 2>&4
    } 4>&2 2>&1 )
  } 3>&1
  [[ $real_time =~ .*m(.*)s ]]
  local ms=$((10#${BASH_REMATCH[1]/./}))
  local step=15
  if ((ms >= 2*step)); then
    alias delay=
  else
    ((ms > step)) && ms=$step
    ms=$((step-ms))
    local s='0.000'
    alias delay="sleep ${s:0:((${#s}-${#ms}))}$ms"
  fi

  # animate
  LINPOS=
  for ((i=len-1; i>=0; i--)); do
    [[ $LINPOS ]] && tput cup $((LINPOS - ${#ABANNER[@]} + 1)) 0
    trim=${trim:1}
    printf "%.${_cols}s" "${ABANNER[@]#$trim}"
    [[ $LINPOS ]] || line_pos
    eval delay
  done
  echo
  readarray -s "${#ABANNER[@]}" 'ABANNER' <<<"$BANNER"
  printf "%.${_cols}s" "${ABANNER[@]}"
  unalias delay
}

setup_tty() {
  default_ANIMATE=1
  [ -t 1 ] || default_ANIMATE=
  [[ -v 'ANIMATE' ]] || ANIMATE=$default_ANIMATE

  [[ $ANIMATE ]] || return 0

  stty -echo
  tput civis
  _cols=$(tput cols)
  _lines=$(tput lines)
  trap '_cols=$(tput cols); _lines=$(tput lines)' WINCH
}

cursor_pos() {
  echo -en "\E[6n"
  read -sdR CURPOS
  CURPOS=${CURPOS#*[}
}

line_pos() {
  cursor_pos
  LINPOS=$((${CURPOS%;*}-1))
}

if [ "$0" = "${BASH_SOURCE}" ]; then
  runner "$@"
fi

setup_self_runner
alias '@run_tests=run_tests'
