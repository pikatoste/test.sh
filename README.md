<!-- BADGE-START -->
[![](https://github.com/pikatoste/test.sh/workflows/CI/badge.svg)](https://github.com/pikatoste/test.sh/actions)
[![](https://raw.githubusercontent.com/pikatoste/test.sh/assets/coverage.svg?sanitize=true)](https://pikatoste.github.io/test.sh/buildinfo/latest/coverage/)
<!-- BADGE-END-->

See https://pikatoste.github.io/test.sh/.

# test.sh

test.sh is a shell library for writing tests as shell scripts.

Only GNU bash is supported.

## Installation

Download test.sh from a [prebuilt release](https://pikatoste.github.io/test.sh/releases/) and copy it to your project or put it in a central location,
such as /opt/test.sh/test.sh.

Or you can install test.sh from sources:

* First, build test.sh:

    ```shell script
    make
    ```

* Then copy `build/test.sh` to your project or put it in a central location, such as /opt/test.sh/test.sh.

## Usage

You must source test.sh in your test script, **after function definitions and before any commands**.
If test.sh is included in your project, you may want to reference it relative to the script location.
The sequence to source test.sh is:

```shell script
source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/test.sh
```

A test script is a collection of tests. In inline mode, tests are delimited by calls to `start_test`.
In managed mode, tests are defined by test functions. You should not mix inline and managed mode in the
same test script.

Inline mode:

```shell script
#!/bin/bash
source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/test.sh

start_test "This is my first test"
assert_true true
```

Managed mode:

```shell script
#!/bin/bash
test_01() {
  test_name "This is my first test"
  assert_true true
}

source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/test.sh

run_tests
```

Test output:

```text
* This is my first test
```

The output of a test script is a colorized summary with the result of each test.
The standard output and error are redirected to a log file named after the test script with the
suffix '.out' appended and located in directory 'testout' relative to the test script. For example, if your
test script is `test/test_something.sh`, the output will be logged to `test/testout/test_something.sh.out`.

Currently test.sh does not deal with running test scripts; for this purpose you can use
[Makefile.test](https://github.com/box/Makefile.test).

### Notifying failure

test.sh sets -o errexit, so any command that does not return success will be considered as
a failure. In inline mode, the first failure terminates the script; in managed mode this behaviour
depends on the configuration variable FAIL_FAST. In either case, a failure of an individual test
will cause the script to return failure.

Test failures will cause a stack trace to be logged.

In managed mode, each test function is executed in its own subshell. Assertions are evaluated in a subshell also.
This subshell inherits the environment, which includes both variables and functions, and the shell
options. One implication of this is that you cannot affect the environment of the test script from a test function.
Another consecuence is that bash looses track of the source files where functions are defined, affecting the
quality of stack traces. In order to overcome this, the REENTER feature has been defined.

### Configuration

Configuration is expressed with environment variables. These variables can come from the environment
or from a configuration file. Variables set in the environment take precedence over those defined
in the configuration file.

The configuration file is sourced, so it can contain any shell code. Normally you would
put only variable assignments in the configuration file.

If the variable CONFIG_FILE is defined, the configuration file will be loaded from that location.
Otherwise a file named 'test.sh.config' will be searched in these locations (see section [Predefined variables](#predefined-variables)'):

* $TEST_SCRIPT_DIR
* $TESTSH_DIR

Boolean variables are considered true when not empty, false otherwise (undefined or empty).

Available configuration variables:

* VERBOSE

  Boolean. Default false.

  If true, then the standard output and error are displayed in the main output in addition to
  being saved to the log file.

* DEBUG

  Boolean. Default 0.

  If true, activate 'set -x'.

* INCLUDE_GLOB

  The include file glob used in the default INCLUDE_PATH. The default value is 'include*.sh'

* INCLUDE_PATH

  A colon separated list of include locations. Each location is a file glob.

  The default value is '$TESTSH_DIR/$INCLUDE_GLOB:$TEST_SCRIPT_DIR/$INCLUDE_GLOB'.

  Each include file found will be sourced. Include files are portions of shell code
  shared by your tests.

* FAIL_FAST

  Boolean. Default true. Only used in managed mode.

  If true, failure of a test function will interrupt the script and the remaining test functions will
  be skipped.

  If false, all test functions will be executed.

* REENTER

  Boolean. Default true.

  If true, when test.sh starts a subshell it will source again all involved scripts: the test
  script, test.sh and included files. This redefines functions in the subshell's context and allows
  stack traces to correctly refer source files and line numbers.

  If false, subshells will not source again involved scripts. Functions defined in the calling shell are made
  available to the subshell because they are exported in the environment. The source file and line number of
  functions inherited from the environment is lost; stack traces with frames referencing these functions will
  show 'environment' as the source file and a line number relative to that function's definition
  _in the environment_, which might be different from the original function's definition in the source file.
  For example, blank lines are not present in the function definition in the environment.

* PRUNE_PATH

  Default: ${PWD}/

  A pattern that is matched at the beginning of each source path when generating frames in stack traces. The longest
  match is removed from the path; if there's no match the path not modified.

  For example, to strip all directories and leave only file names you would set `PRUNE_PATH="*/"`.

* SUBSHELL

  Values: never, teardown or always. Default: always when FAIL_FAST is false; teardown when FAIL_FAST is true.

  test.sh executes code whose exit status must be monitored but not terminate the script on failure in
  a subshell. This includes test functions, teardown functions and assert functions.

  * never: never start subshells. Incompatible with FAIL_FAST false. All failures, including those in teardown
    methods, will terminate the script.
  * teardown: only start subshells to execute teardown functions. Incompatible with FAIL_FAST false.
  * always: start a subshell to execute test functions, teardown functions and assert expressions. Required when
    FAIL_FAST is false.

* STACK_TRACE

  Values: no, pruned, compact or full. Default: pruned when SUBSHELL=always, compact otherwise.

  * no: do not output stack traces.
  * pruned: include frames up to the first frame in test.sh.
  * compact: include all frames except those in test.sh.
  * full: include all frames.

### Predefined variables

This is the list of variables defined by test.sh:

* VERSION: the version of test.sh.
* TESTSH_DIR: the directory of test.sh.
* TEST_SCRIPT_DIR: the directory of the test script.
* CONFIG_FILE: the location of the effective configuration file.
* TESTOUT_FILE: the log file.

### Function reference

This is the list of functions defined by test.sh that you can use in a test script.

* run_tests

  Syntax:

  ```text
  run_tests [test function]...
  ```

  Runs the specified test functions in managed mode. With no arguments, runs discovered test
  functions: functions whose name starts with 'test_'. Discovered test functions will be executed
  in function name order, not function definition order. Test functions specified as arguments
  will be executed in the order of the arguments.

  You should call run_tests only once.

  A test function should look:

  ```shell script
  test_xxx() {
    start_test "The name of this test"
    # the test code goes here
  }
  ```

  They should start with a call to `start_test` and should not call `start_test` more than once.
  The remaing code is the test itself, which usually includes some of the following:
  * Initialization code
  * Execution code
  * Validation code
  TODO: unfinished

* start_test

  Syntax:

  ```text
  start_test <test name>
  ```

  Defines the start of a test (and the end of the previous test) in inline mode. In managed mode,
  sets the test name of the current test function.

* setup_test_suite

  If defined, this function will be called in managed mode only once before all tests.
  A failure in this function will cause failure of the script and no test will be executed.

* teardown_test_suite

  If defined, this function will be called in managed mode only once after all tests, even if there are failures.
  A failure in this function itself will not cause failure of the script, but will cause a warning
  message to be displayed on the main output.

* setup_test

  If defined, this function will be called in managed mode before each test.
  A failure in this function will cause failure of the test.

* teardown_test

  If defined, this function will be called in managed mode after each test, even if the test fails.
  A failure in this function itself will not cause failure of the test, but will cause a warning
  message to be displayed on the main output.

* assert_true

  Syntax:

  ```text
  assert_true <shell command> [message]
  ```

* assert_false

  Syntax:

  ```text
  assert_false <shell command> [message]
  ```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

To run the tests run `make check`. This target expects test.sh to be built already, so to run the test on a clean
repository run `make all check`. The tests are run in the temporary directory `runtest` and the test logs can be
found in `runtest/test/testout`.

Other Makefile targets:

* all: build test.sh. Produces `build/test.sh`.
* clean: remove the `build` and `runtest`directories.
* coverage: run the tests and generate an HTML coverage report in `runtest/coverage`.
Requires [Bashcov](https://github.com/infertux/bashcov), so you must install it first:

    ```shell script
    sudo apt isntall ruby
    gem install bashcov
    ```

## License
[MIT](https://choosealicense.com/licenses/mit/)
