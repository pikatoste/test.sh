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
  shopt -s inherit_errexit
  export BASHOPTS
fi

ignore() {
  [[ -z $1 ]] || echo -e "$1"
}

exit_trap() {
  EXIT_CODE=${EXIT_CODE:-$?}
  [[ -v SUBSHELL_CMD || $SUBSHELL != never ]] || add_err_handler cleanup
  for handler in "${EXIT_HANDLERS[@]}"; do
    ignore "$(eval "$handler")"
  done
  [[ -v SUBSHELL_CMD || $SUBSHELL != never ]] || remove_err_handler
}

push_exit_handler() {
  EXIT_HANDLERS=("$1" "${EXIT_HANDLERS[@]}")
}

pop_exit_handler() {
  unset EXIT_HANDLERS[0]
}

err_trap() {
  local err=$?
  EXIT_CODE=$err
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
  [[ -v MANAGED || -v FIRST_TEST ]] || { teardown_test_called=1; ignore "$(call_teardown teardown_test)"; }
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
  ! declare -f $1 >/dev/null || $1
}

error_setup_test_suite() {
  echo -e "${RED}[ERROR] setup_test_suite failed, see $(prune_path "$TESTOUT_FILE") for more information${NC}" >&3
}

call_setup_test_suite() {
  push_err_handler "pop_err_handler; error_setup_test_suite"
  call_if_exists setup_test_suite
  pop_err_handler
}

call_teardown_subshell() {
  add_err_handler "print_stack_trace"
  call_if_exists $1
  remove_err_handler
}

call_teardown() {
  if [[ $SUBSHELL != 'never' ]]; then
    subshell "call_teardown_subshell $1" || warn_teardown_failed $1
  else
    push_err_handler "pop_err_handler; warn_teardown_failed $1"
    call_if_exists $1
    pop_err_handler
  fi
}

run_test_script() {
  local test_script="$1"
  shift
  ( unset \
      CURRENT_TEST_NAME \
      SUBSHELL_CMD \
      MANAGED \
      FIRST_TEST \
      teardown_test_called \
      teardown_test_suite_called \
      PIPE \
      FOREIGN_STACK \
      GREEN ORANGE RED BLUE NC
    EXIT_HANDLERS=()
    ERR_HANDLERS=(save_stack)
    unset -f setup_test_suite teardown_test_suite setup_test teardown_test
    "$test_script" "$@" )
}

run_test() {
  local test_func=$1
  teardown_test_called=
  local test_func=$1
  [[ ! -v SUBSHELL_CMD ]] || add_err_handler "print_stack_trace"
  push_err_handler "pop_err_handler; display_test_failed"
  push_err_handler "pop_err_handler; CURRENT_TEST_NAME=\${CURRENT_TEST_NAME:-$test_func}"
  call_if_exists setup_test
  run_test_teardown_trap() {
    [[ $teardown_test_called ]] || ignore "$(call_teardown teardown_test)"
  }
  push_exit_handler run_test_teardown_trap
  $test_func
  CURRENT_TEST_NAME=${CURRENT_TEST_NAME:-$test_func}
  display_test_passed
  pop_exit_handler
  pop_err_handler
  pop_err_handler
  teardown_test_called=1
  ignore "$(call_teardown teardown_test)"
  [[ ! -v SUBSHELL_CMD ]] || remove_err_handler
}

run_tests() {
  MANAGED=
  discover_tests() {
    declare -F | cut -d \  -f 3 | grep "$TEST_MATCH" || true
  }

  teardown_test_suite_called=
  [ $# -gt 0 ] || { local discovered="$(discover_tests)"; [ -z "$discovered" ] || set $discovered; }
  local failures=0
  call_setup_test_suite
  run_tests_exit_trap() {
    [[ $teardown_test_suite_called ]] || ignore "$(call_teardown teardown_test_suite)"
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
      failures=$(( $failures + 1 ))
      if [[ $FAIL_FAST ]]; then
        while [ $# -gt 0 ]; do
          display_test_skipped $1
          shift
        done
        break
      fi
    fi
  done
  teardown_test_suite_called=1
  ignore "$(call_teardown teardown_test_suite)"
  pop_exit_handler
  [[ $failures == 0 ]]
}

load_includes() {
  load_include_file() {
    local include_file=$1
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
  rm -f $STACK_FILE
  if [[ $REENTER ]]; then
    BASH_ENV=<(call_stack; echo SUBSHELL_CMD=\"$1\") /bin/bash --norc "$TEST_SCRIPT"
  else
    BASH_ENV=<(call_stack; echo SUBSHELL_CMD=) /bin/bash --norc -c "trap exit_trap EXIT; trap err_trap ERR; push_err_handler save_stack; $1"
  fi
}

save_stack() {
  if [ ! -f $STACK_FILE ]; then
    current_stack $1 >$STACK_FILE
  fi
}

current_stack() {
  local err=$EXIT_CODE
  local frame_idx=${1:-3}
  ERRCMD=$(echo -n "$BASH_COMMAND" | head -1)
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
    local path=$(realpath "$1")
    echo ${path##$PRUNE_PATH}
  else
    echo $1
  fi
}

local_stack() {
  LOCAL_STACK=()
  [[ $STACK_TRACE == no ]] || for ((i=${1:-0}; i<${#FUNCNAME[@]}-1; i++))
  do
    local source_basename=$(basename "${BASH_SOURCE[$i+1]}")
    [[ $STACK_TRACE != pruned || $source_basename != test.sh ]] || break
    [[ $STACK_TRACE != compact || $source_basename != test.sh ]] || continue
    local line=$(echo "${FUNCNAME[$i+1]}($(prune_path "${BASH_SOURCE[$i+1]}"):${BASH_LINENO[$i]})")
    LOCAL_STACK+=("$line")
  done
}

print_stack_trace() {
  local err_msg=$(tail -1 $STACK_FILE)
  [[ $err_msg ]] || return 0
  log_err "$(tail -1 $STACK_FILE)"
  tac $STACK_FILE | tail -n +2 | while read frame; do
    log_err " at $frame"
  done
  rm -f $STACK_FILE
}

assert_msg() {
  local msg=$1
  local why=$2
  echo "Assertion failed: ${msg:+$msg, }$why"
}

assert_err_msg() {
  log_err "$(assert_msg "$@")"
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
  shift
  push_err_handler "pop_err_handler; print_stack_trace; touch $STACK_FILE"
  push_err_handler "pop_err_handler; assert_err_msg \"$msg\" \"$why\""
  if [[ $SUBSHELL == always ]]; then
    $expect "subshell '$what'"
  else
    push_err_handler "pop_err_handler; save_stack"
    $expect "$what"
    pop_err_handler
  fi
  pop_err_handler
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
  assert "[[ \"$current\" = \"$expected\" ]]" expect_true "expected '$expected' but got '$current'" "$msg"
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
  TESTSH=$(readlink -f "$BASH_SOURCE")
  TESTSH_DIR=$(dirname "$TESTSH")

  FOREIGN_STACK=()
  FIRST_TEST=
  STACK_FILE=/tmp/stack-$$

  set_color() {
    if [[ $COLOR = yes ]]; then
      GREEN='\033[0;32m'
      ORANGE='\033[0;33m'
      RED='\033[0;31m'
      BLUE='\033[0;34m'
      NC='\033[0m' # No Color'
    fi
  }

  cleanup() {
    exec 1>&- 2>&-
    wait
    rm -f $STACK_FILE
  }

  setup_io() {
    PIPE=$(mktemp -u)
    mkfifo "$PIPE"
#    TESTOUT_DIR=${LOG_DIR:-$TEST_SCRIPT_DIR/testout}
#    TESTOUT_FILE=${LOG_FILE:-$TESTOUT_DIR/$(basename "$TEST_SCRIPT").out}
    TESTOUT_DIR="$TEST_SCRIPT_DIR"/testout
    TESTOUT_FILE="$TESTOUT_DIR"/"$(basename "$TEST_SCRIPT")".out
    mkdir -p "$TESTOUT_DIR"
    [[   $VERBOSE ]] || cat >"$TESTOUT_FILE" <"$PIPE" &
    [[ ! $VERBOSE ]] || tee  "$TESTOUT_FILE" <"$PIPE" &
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

    default_VERBOSE=
    default_DEBUG=
    default_INCLUDE_GLOB='include*.sh'
    default_INCLUDE_PATH='$TESTSH_DIR/$INCLUDE_GLOB:$TEST_SCRIPT_DIR/$INCLUDE_GLOB'
    default_FAIL_FAST=1
    default_REENTER=1
    default_PRUNE_PATH='$PWD/'
    default_SUBSHELL='$(set_default_SUBSHELL)'
    default_STACK_TRACE='full'
    default_TEST_MATCH='^test_'
    default_COLOR='yes'
    default_LOG_DIR='$TEST_SCRIPT_DIR/testout'
    default_LOG_NAME='$(basename "$TEST_SCRIPT").out'
    default_LOG_FILE='$LOG_DIR/$LOG_NAME'
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

    local config_vars="VERBOSE DEBUG INCLUDE_GLOB INCLUDE_PATH FAIL_FAST REENTER PRUNE_PATH SUBSHELL STACK_TRACE TEST_MATCH COLOR LOG_DIR LOG_NAME LOG_FILE"

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
      log_err "Configuration: invalid value of variable $var: '$val', allowed values: $(echo "$*" | sed -e 's/ /, /g')" && false
    }

    validate_values SUBSHELL never teardown always
    if [[ ! $FAIL_FAST && $SUBSHELL != always ]]; then
      log_warn "Configuration: SUBSHELL set to 'always' because FAIL_FAST is false (was: SUBSHELL=$SUBSHELL)"
      SUBSHELL=always
    fi
    validate_values STACK_TRACE no full
    validate_values COLOR no yes

    set_color
  }

  trap "EXIT_CODE=\$?; rm -f \$PIPE; exit_trap" EXIT
  trap err_trap ERR
  config_defaults
  push_err_handler "print_stack_trace"
  push_err_handler "save_stack"
  setup_io
  push_exit_handler "cleanup"
  load_config
  load_includes
  push_exit_handler "[[ -v MANAGED ]] || call_teardown teardown_test_suite"
  push_exit_handler "[[ -v MANAGED || -n \$teardown_test_called ]] || call_teardown teardown_test"
  push_exit_handler "[[ -v MANAGED ]] || display_last_test_result"

  [[ ! $DEBUG ]] || set -x
fi
