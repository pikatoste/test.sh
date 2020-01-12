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

if [[ ! -v SUBSHELL_CMD ]]; then
  set -o allexport
  set -o errexit
  set -o errtrace
  set -o pipefail
  export SHELLOPTS
fi

exit_trap() {
  local err=$?
  for handler in "${EXIT_HANDLERS[@]}"; do
    ERRCODE=$err eval "$handler" || true
  done
}

push_exit_handler() {
  EXIT_HANDLERS=("$1" "${EXIT_HANDLERS[@]}")
}

pop_exit_handler() {
  unset EXIT_HANDLERS[0]
}

err_trap() {
  for handler in "${ERR_HANDLERS[@]}"; do
    eval "$handler" || true
  done
}

push_err_handler() {
  ERR_HANDLERS=("$1" "${ERR_HANDLERS[@]}")
}

pop_err_handler() {
  unset ERR_HANDLERS[0]
}

display_last_test_result() {
  if [[ $ERRCODE == 0 ]]; then
    display_test_passed
  else
    display_test_failed
  fi
}

start_test() {
  [[ -v MANAGED || ! -v FIRST_TEST ]] || call_if_exists setup_test_suite
  [[ -v MANAGED || -v FIRST_TEST ]] || call_teardown teardown_test
  [[ -v MANAGED ]] || call_if_exists setup_test
  [ -z "$CURRENT_TEST_NAME" ] || display_test_passed
  CURRENT_TEST_NAME="$1"
  [ -z "$CURRENT_TEST_NAME" ] || log "Start test: $CURRENT_TEST_NAME"
  unset FIRST_TEST
}

display_test_passed() {
  [ -z "$CURRENT_TEST_NAME" ] || echo -e "${GREEN}* ${CURRENT_TEST_NAME}${NC}" >&3
  unset CURRENT_TEST_NAME
}

display_test_failed() {
  [ -z "$CURRENT_TEST_NAME" ] || echo -e "${RED}* ${CURRENT_TEST_NAME}${NC}" >&3
  unset CURRENT_TEST_NAME
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

log_warn() {
  do_log "${BLUE}[test.sh]${NC} $*"
}

log_err() {
  do_log "${RED}[test.sh]${NC} $*" >&2
}

call_if_exists() {
  ! declare -f $1 >/dev/null || $1
}

call_teardown_subshell() {
  push_err_handler "print_stack_trace || true"
  call_if_exists $1
  pop_err_handler
}

call_teardown() {
  if [[ $SUBSHELL != 'never' ]]; then
    subshell "call_teardown_subshell $1" || warn_teardown_failed $2
  else
    push_err_handler "warn_teardown_failed $2"
    call_if_exists $1
    pop_err_handler
  fi
}

run_test() {
  teardown_test_called=0
  local test_func=$1
  shift 1
  [[ ! -v SUBSHELL_CMD ]] || push_err_handler "print_stack_trace || true"
  call_if_exists setup_test
  run_test_teardown_trap() {
    [ $teardown_test_called = 1 ] || call_teardown teardown_test
  }
  push_exit_handler run_test_teardown_trap
  push_err_handler display_test_failed
  $test_func
  display_test_passed
  pop_err_handler
  pop_exit_handler
  teardown_test_called=1
  call_teardown teardown_test
  [[ ! -v SUBSHELL_CMD ]] || pop_err_handler
}

run_tests() {
  MANAGED=
  discover_tests() {
    # TODO: use a configurable test matching pattern
    declare -F | cut -d \  -f 3 | grep ^test_ || true
  }

  teardown_test_suite_called=0
  [ $# -gt 0 ] || { local discovered="$(discover_tests)"; [ -z "$discovered" ] || set $discovered; }
  local failures=0
  call_if_exists setup_test_suite
  run_tests_exit_trap() {
    [ $teardown_test_suite_called = 1 ] || call_teardown teardown_test_suite _suite
  }
  push_exit_handler run_tests_exit_trap
  while [ $# -gt 0 ]; do
    local test_func=$1
    shift
    local failed=0
    if [[ $SUBSHELL == always ]]; then
      subshell "run_test $test_func" || failed=1
    else
      run_test $test_func
    fi
    if [ $failed -ne 0 ]; then
      log_err "${test_func} FAILED"
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
  call_teardown teardown_test_suite _suite
  pop_exit_handler
  return $failures
}

load_includes() {
  load_include_file() {
    local include_file=$1
    source "$include_file"
    [[ -v SUBSHELL_CMD ]] || log "Included: $include_file"
  }

  local saved_IFS=$IFS
  IFS=":"
  for path in $INCLUDE_PATH; do
    # shellcheck disable=SC2066
    for include in "$path"; do
      [ ! -f "$include" ] || load_include_file "$include"
    done
  done
  IFS=$saved_IFS
}

subshell() {
  call_stack() {
    local_stack 1
    FOREIGN_STACK=("${LOCAL_STACK[@]}" "${FOREIGN_STACK[@]}")
    declare -p FOREIGN_STACK
  }
  if [ "$REENTER" = 1 ]; then
    BASH_ENV=<(call_stack) /bin/bash --norc -c "SUBSHELL_CMD=\"$1\" source $TEST_SCRIPT"
  else
    BASH_ENV=<(call_stack) bash --norc -c "$1"
  fi
}

prune_path() {
  [[ -v PRUNE_PATH ]] || eval "PRUNE_PATH=$default_PRUNE_PATH"
  local path=$(realpath "$1")
  echo ${path##$PRUNE_PATH}
}

local_stack() {
  LOCAL_STACK=()
  [[ $STACK_TRACE != no ]] || return 0
  for ((i=${1:-0}; i<${#FUNCNAME[@]}-1; i++))
  do
    [[ $STACK_TRACE != pruned || $(basename "${BASH_SOURCE[$i+1]}") != test.sh ]] || break
    [[ $STACK_TRACE != compact || $(basename "${BASH_SOURCE[$i+1]}") != test.sh ]] || continue
    local line=$(echo "${FUNCNAME[$i+1]}($(prune_path "${BASH_SOURCE[$i+1]}"):${BASH_LINENO[$i]})")
    LOCAL_STACK+=("$line")
  done
}

print_stack_trace() {
  local err=$?
  local frame_idx=2
  ERRCMD=$BASH_COMMAND
#  if [ "$IN_ASSERT" = 1 ]; then
#    ERRCMD=${FUNCNAME[2]}
#    ((frame_idx++))
#  fi
  log_err "Error in ${FUNCNAME[$frame_idx]}($(prune_path "${BASH_SOURCE[$frame_idx]}"):${BASH_LINENO[$frame_idx-1]}): '${ERRCMD}' exited with status $err"
  ((frame_idx++))
  local_stack $frame_idx
  for frame in "${LOCAL_STACK[@]}" "${FOREIGN_STACK[@]}"; do
    log_err " at $frame"
  done
}

assert_fail_msg() {
  local what="$1"
  local why="$2"
  local msg="$3"
  log_err "Assertion failed: ${msg:+$msg: }$why in: $what"
  return 1
}

call_assert() {
  IN_ASSERT=1
  if [[ $SUBSHELL == always ]]; then
    subshell "$1" || assert_fail_msg "$@"
  else
    push_err_handler "assert_fail_msg \"$1\" \"$2\" \"$3\" || true"
    eval "$1"
    pop_err_handler
  fi
}
call_not_assert() {
  IN_ASSERT=1
  if [[ $SUBSHELL == always ]]; then
    ! subshell "$1" || assert_fail_msg "$@"
  else
    push_err_handler "assert_fail_msg \"$1\" \"$2\" \"$3\" || true"
    ! eval "$1"
    pop_err_handler
  fi
}
assert_true() {
  call_assert "$1" "expected success but got failure" "$2"
}

assert_false() {
  call_not_assert "$1" "expected success but got failure" "$2"
}

if [[ -v SUBSHELL_CMD ]]; then
  load_includes
  trap exit_trap EXIT
  trap err_trap ERR
  eval "$SUBSHELL_CMD"
  exit 0
else
  # TODO: sort out global var names and control which are exported
  VERSION=@VERSION@
  TEST_SCRIPT="$(readlink -f "$0")"
  TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
  TESTSH="$(readlink -f "$BASH_SOURCE")"
  TESTSH_DIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  FOREIGN_STACK=()
  FIRST_TEST=

  # TODO: configure whether to colorize output
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color'

  setup_io() {
    PIPE=$(mktemp -u)
    mkfifo "$PIPE"
    push_exit_handler "rm -f \"$PIPE\""
    TESTOUT_DIR="$TEST_SCRIPT_DIR"/testout
    TESTOUT_FILE="$TESTOUT_DIR"/"$(basename "$TEST_SCRIPT")".out
    mkdir -p "$TESTOUT_DIR"
    local testsh=$(basename "$TESTSH")
    [[ $VERBOSE == 1 ]] || grep -v "$testsh: pop_scope: " <"$PIPE" | cat >"$TESTOUT_FILE" &
    [[ $VERBOSE != 1 ]] || grep -v "$testsh: pop_scope: " <"$PIPE" | tee  "$TESTOUT_FILE" &
    exec 3>&1 4>&2 >"$PIPE" 2>&1
  }

  config_defaults() {
    set_default_SUBSHELL() {
      if [[ $FAIL_FAST ]]; then
        echo "teardown"
      else
        echo "always"
      fi
    }
    set_default_STACK_TRACE() {
      if [[ $SUBSHELL != always ]]; then
        echo "compact"
      else
        echo "pruned"
      fi
    }
    default_VERBOSE=
    default_DEBUG=
    default_INCLUDE_GLOB='include*.sh'
    default_INCLUDE_PATH='$TESTSH_DIR/$INCLUDE_GLOB:$TEST_SCRIPT_DIR/$INCLUDE_GLOB'
    default_FAIL_FAST=1
    default_REENTER=1
    default_PRUNE_PATH='$PWD/'
    default_SUBSHELL='$(set_default_SUBSHELL)'
    default_STACK_TRACE='$(set_default_STACK_TRACE)'
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

    # TODO: write checks on booleans without comparison operators
    # TODO: use empty/not empty as boolean values, not 0/1

    local config_vars="VERBOSE DEBUG INCLUDE_GLOB INCLUDE_PATH FAIL_FAST REENTER PRUNE_PATH SUBSHELL STACK_TRACE"

    # save environment config
    for var in $config_vars; do
      save_variable $var
    done

    # load config if present
    [ -z "$CONFIG_FILE" ] || load_config_file "$CONFIG_FILE"
    [ -n "$CONFIG_FILE" ] || try_config_path

    # prioritize environment config
    for var in $config_vars; do
      restore_variable $var
    done

    # set defaults
    for var in $config_vars; do
      set_default $var
    done

    # validate config
    validate_values() {
      local var=$1
      local val=${!var}
      shift
      local values=
      # shellcheck disable=SC2071
      for i in "$@"; do
        [[ $i != $val ]] || return 0
      done
      log_err "Configuration: invalid value in variable $var: '$val', should be one of: $*" && false
    }

    validate_values SUBSHELL never teardown always
    if [[ ! $FAIL_FAST && $SUBSHELL != always ]]; then
      log_warn "Configuration: SUBSHELL set to 'always' because FAIL_FAST is false (was: SUBSHELL=$SUBSHELL)"
      SUBSHELL=always
    fi
    validate_values STACK_TRACE no pruned compact full
  }

  trap exit_trap EXIT
  trap err_trap ERR
  config_defaults
  push_err_handler "print_stack_trace || true"
  setup_io
  load_config
  load_includes
  push_exit_handler "[[ -v MANAGED ]] || call_teardown teardown_test"
  push_exit_handler "[[ -v MANAGED ]] || call_teardown teardown_test_suite _suite"
  push_exit_handler display_last_test_result

  [ "$DEBUG" != 1 ] || set -x
fi
