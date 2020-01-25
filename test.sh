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

if [[ ! -v SUBSHELL_CMD ]]; then
  set -o allexport
  set -o errexit
  set -o errtrace
  set -o pipefail
  export SHELLOPTS
  shopt -s inherit_errexit
  export BASHOPTS
fi

get_result() {
  eval "${2:-LAST_IGNORE}"=$?
}

result_of() {
  # shellcheck disable=SC2155
  local pipe=$TSH_TMPDIR-pipe-$(mktemp -u XXXXXX)
  mkfifo "$pipe"
  cat <"$pipe" &
  local catpid=$!
  DISABLE_STACK_TRACE=
  get_result "$(eval "$1" | { tee "$pipe" >/dev/null || true; })" "$2"
  unset DISABLE_STACK_TRACE
  rm -f "$STACK_FILE"
  wait "$catpid"
  rm -f "$pipe"
}

exit_trap() {
  EXIT_CODE=${EXIT_CODE:-$?}
  [[ -v SUBSHELL_CMD || $SUBSHELL != never ]] || add_err_handler cleanup
  for handler in "${EXIT_HANDLERS[@]}"; do
    # shellcheck disable=SC2016
    result_of 'eval "$handler"'
  done
  [[ -v SUBSHELL_CMD || $SUBSHELL != never ]] || remove_err_handler
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

add_err_handler() {
  ERR_HANDLERS=("${ERR_HANDLERS[@]}" "$1")
}

remove_err_handler() {
  ERR_HANDLERS=("${ERR_HANDLERS[@]:0:${#ERR_HANDLERS[@]}-1}")
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
  [[ -v MANAGED || -v FIRST_TEST ]] || { teardown_test_called=1; result_of 'call_teardown "teardown_test"'; }
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
  echo -e "${RED}[ERROR] setup_test_suite failed, see $(prune_path "$LOG_FILE") for more information${NC}" >&3
}

call_setup_test_suite() {
  push_err_handler "pop_err_handler; error_setup_test_suite"
  call_if_exists setup_test_suite
  pop_err_handler
}

call_teardown() {
  add_err_handler "remove_err_handler; warn_teardown_failed $1"
  if [[ $SUBSHELL != 'never' ]]; then
    subshell "call_if_exists $1"
  else
    call_if_exists "$1"
  fi
  remove_err_handler
}

run_test_script() {
  # commented out to supprt realpath in busybox (for bash compat test in containers)
#  local test_script=$(pwd=$PWD; cd "$TEST_SCRIPT_DIR"; realpath --relative-to "$pwd" "$1")
  local test_script
  test_script=$(cd "$TEST_SCRIPT_DIR"; realpath "$1")
  shift
  ( unset \
      CURRENT_TEST_NAME \
      SUBSHELL_CMD \
      MANAGED \
      FIRST_TEST \
      teardown_test_called \
      TSH_TMPDIR PIPE \
      FOREIGN_STACK \
      GREEN ORANGE RED BLUE NC
    unset -f setup_test_suite teardown_test_suite setup_test teardown_test

    # restore log-related config vars to initial values
    if [[ $SUBTEST_LOG_CONFIG = reset ]]; then
      for var in LOG_DIR_NAME LOG_DIR LOG_NAME; do
        while [[ -v $var ]]; do unset $var; done
        restore_variable $var
      done
      # shellcheck disable=SC2030
      while [[ -v LOG_FILE ]]; do unset LOG_FILE; done
    fi

    EXIT_HANDLERS=()
    ERR_HANDLERS=(save_stack)
    "$test_script" "$@" )
}

with_exit_handler() {
  push_exit_handler "$2"
  $1
  pop_exit_handler
}

run_test() {
  local test_func=$1
  [[ ! -v SUBSHELL_CMD ]] || add_err_handler "print_stack_trace"
  add_err_handler "remove_err_handler; CURRENT_TEST_NAME=\${CURRENT_TEST_NAME:-$test_func}; display_test_failed"
  call_if_exists setup_test
  teardown_test_called=
  # shellcheck disable=SC2016
  with_exit_handler "$test_func" '[[ ! -v SUBSHELL_CMD ]] || [[ $teardown_test_called ]] || call_teardown teardown_test'
  CURRENT_TEST_NAME=${CURRENT_TEST_NAME:-$test_func}
  display_test_passed
  remove_err_handler
  teardown_test_called=1
  result_of 'call_teardown "teardown_test"'
  [[ ! -v SUBSHELL_CMD ]] || remove_err_handler
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
    if [[ $SUBSHELL == always ]]; then
      subshell "run_test $test_func" || failed=1
    else
      result_of "run_test \"$test_func\"" failed
      [[ $failed = 0 ]] || [[ $teardown_test_called ]] || result_of 'call_teardown "teardown_test"'
    fi
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
  result_of 'call_teardown "teardown_test_suite"'
  [[ $failures == 0 ]]
}

load_includes() {
  load_include_file() {
    local include_file=$1
    # shellcheck disable=SC1090
    source "$include_file"
    [[ -v SUBSHELL_CMD ]] || log "Included: $include_file"
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

subshell() {
  call_stack() {
    local_stack 1
    FOREIGN_STACK=("${LOCAL_STACK[@]}" "${FOREIGN_STACK[@]}")
    declare -p FOREIGN_STACK
  }
  rm -f "$STACK_FILE"
  if [[ $REENTER ]]; then
    BASH_ENV=<(call_stack; echo SUBSHELL_CMD="$(printf "%q" "$1")") /bin/bash --norc "$TEST_SCRIPT"
  else
    BASH_ENV=<(call_stack; echo SUBSHELL_CMD=) /bin/bash --norc -c "trap exit_trap EXIT; trap err_trap ERR; push_err_handler save_stack; $1"
  fi
}

save_stack() {
  if [ ! -f "$STACK_FILE" ]; then
    current_stack "$1" >"$STACK_FILE"
  fi
}

current_stack() {
  local err=$ERR_CODE
  local frame_idx=${1:-3}
  ERRCMD=$(echo -n "$BASH_COMMAND" | head -1)
  # shellcheck disable=SC2155
  local err_string="Error in ${FUNCNAME[$frame_idx]}($(prune_path "${BASH_SOURCE[$frame_idx]}"):${BASH_LINENO[$frame_idx-1]}): '${ERRCMD}' exited with status $err"
  ((frame_idx++))
  local_stack $frame_idx
  for ((i=${#FOREIGN_STACK[@]}-1; i>=0; i--)); do
    echo "${FOREIGN_STACK[i]}"
  done
  for ((i=${#LOCAL_STACK[@]}-1; i>=0; i--)); do
    echo "${LOCAL_STACK[i]}"
  done
  echo "$err_string"
}

prune_path() {
  if [[ $1 && $1 != environment ]]; then
    # shellcheck disable=SC2155
    local path=$(realpath "$1")
    echo "${path##$PRUNE_PATH}"
  else
    echo "$1"
  fi
}

local_stack() {
  LOCAL_STACK=()
  [[ $STACK_TRACE == no ]] || for ((i=${1:-0}; i<${#FUNCNAME[@]}-1; i++))
  do
    # shellcheck disable=SC2155
    local source_basename=$(basename "${BASH_SOURCE[$i+1]}")
    [[ $STACK_TRACE != pruned || $source_basename != test.sh ]] || break
    [[ $STACK_TRACE != compact || $source_basename != test.sh ]] || continue
    # shellcheck disable=SC2155
    local line="${FUNCNAME[$i+1]}($(prune_path "${BASH_SOURCE[$i+1]}"):${BASH_LINENO[$i]})"
    LOCAL_STACK+=("$line")
  done
}

print_stack_trace() {
  local err_msg
  err_msg=$(tail -1 "$STACK_FILE")
  [[ $err_msg ]] || return 0
  log_err "$(tail -1 "$STACK_FILE")"
  tac "$STACK_FILE" | tail -n +2 | while read -r frame; do
    log_err " at $frame"
  done
  rm -f "$STACK_FILE"
  [[ ! -v DISABLE_STACK_TRACE ]] || touch -f "$STACK_FILE"
}

assert_msg() {
  local msg=$1
  local why=$2
  echo "Assertion failed: ${msg:+$msg, }$why"
}

assert_err_msg() {
  log_err "$(assert_msg "$tsh_assert_msg" "$tsh_assert_why")"
}

expect_true() {
  eval "$1"
}

expect_false() {
  ! eval "$1" || false
}

assert() {
  local what=$1
  local expect=$2
  local why=$3
  local msg=$4
  tsh_assert_msg=$msg
  tsh_assert_why=$why
  push_err_handler "pop_err_handler; assert_err_msg"
  if [[ $SUBSHELL == always ]]; then
    $expect "subshell $(printf "%q" "$what")"
  else
    $expect "$what"
  fi
  pop_err_handler
}

assert_true() {
  local what=$1
  local msg=$2
  assert "$what" expect_true "expected success but got failure in: '$what'" "$msg"
}

assert_false() {
  local what=$1
  local msg=$2
  assert "$what" expect_false "expected failure but got success in: '$what'" "$msg"
}

assert_equals() {
  local expected=$1
  local current=$2
  local msg=$3
  tsh_assert_msg=$msg
  tsh_assert_why="expected '$expected' but got '$current'"
  push_err_handler "pop_err_handler; assert_err_msg"
  [[ "$expected" = "$current" ]]
  pop_err_handler
}

if [[ -v SUBSHELL_CMD ]]; then
  load_includes
  trap "EXIT_CODE=\$?; exit_trap" EXIT
  trap err_trap ERR
  push_err_handler save_stack
  eval "$SUBSHELL_CMD"
  exit 0
else
  # TODO: sort out global var names and control which are exported
  VERSION=@VERSION@
  TEST_SCRIPT=$(readlink -f "$0")
  TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
  # shellcheck disable=SC2128
  TESTSH=$(readlink -f "$BASH_SOURCE")
  TESTSH_DIR=$(dirname "$TESTSH")

  FOREIGN_STACK=()
  FIRST_TEST=
  TSH_TMPDIR=$(mktemp -d -p "${TMPDIR:-/tmp}" tsh-XXXXXXXXX)
  STACK_FILE=$TSH_TMPDIR-stack

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
    rm -f "$STACK_FILE"
  }

  setup_io() {
    PIPE=$TSH_TMPDIR/pipe
    mkfifo "$PIPE"
    # shellcheck disable=SC2031
    mkdir -p "$(dirname "$LOG_FILE")"
    [[ $SUBTEST_LOG_CONFIG != noredir ]] || return 0
    local redir=\>
    [[ $LOG_MODE = overwrite ]] || redir=\>$redir
    # shellcheck disable=SC2031
    [[   $VERBOSE ]] || eval cat $redir"$LOG_FILE" <"$PIPE" &
    redir=
    [[ $LOG_MODE = overwrite ]] || redir=-a
    # shellcheck disable=SC2031
    [[ ! $VERBOSE ]] || tee $redir "$LOG_FILE" <"$PIPE" &
    exec 3>&1 4>&2 >"$PIPE" 2>&1
  }

  config_defaults() {
    default_VERBOSE=
    default_DEBUG=
    default_INCLUDE_GLOB='include*.sh'
    # shellcheck disable=SC2016
    default_INCLUDE_PATH='$TESTSH_DIR/$INCLUDE_GLOB:$TEST_SCRIPT_DIR/$INCLUDE_GLOB'
    default_FAIL_FAST=1
    default_REENTER=1
    # shellcheck disable=SC2016
    default_PRUNE_PATH='$PWD/'
    default_SUBSHELL='never'
    default_STACK_TRACE='full'
    default_TEST_MATCH='^test_'
    default_COLOR='yes'
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

    load_config_file() {
      local config_file=$1
      # shellcheck disable=SC1090
      source "$config_file"
      log "Loaded config from $config_file"
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

    local config_vars="VERBOSE DEBUG INCLUDE_GLOB INCLUDE_PATH FAIL_FAST REENTER PRUNE_PATH SUBSHELL STACK_TRACE TEST_MATCH COLOR LOG_DIR_NAME LOG_DIR LOG_NAME LOG_FILE LOG_MODE SUBTEST_LOG_CONFIG"

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

    validate_values SUBSHELL never teardown always
    validate_values STACK_TRACE no full
    validate_values COLOR no yes
    validate_values LOG_MODE overwrite append
    validate_values SUBTEST_LOG_CONFIG reset noreset noredir
    set_color
  }

  trap 'EXIT_CODE=$?; rm -rf $TSH_TMPDIR; exit_trap' EXIT
  trap err_trap ERR
  config_defaults
  load_config
  push_err_handler "print_stack_trace"
  push_err_handler "save_stack"
  setup_io
  push_exit_handler "cleanup"
  load_includes
  push_exit_handler "[[ -v MANAGED ]] || call_teardown teardown_test_suite"
  push_exit_handler "[[ -v MANAGED || -n \$teardown_test_called ]] || call_teardown teardown_test"
  push_exit_handler "[[ -v MANAGED ]] || display_last_test_result"

  [[ ! $DEBUG ]] || set -x
fi
