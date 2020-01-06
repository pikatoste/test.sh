![](https://github.com/pikatoste/test.sh/workflows/CI/badge.svg)
![](https://raw.githubusercontent.com/pikatoste/test.sh/assets/coverage.svg)

# test.sh

test.sh is a shell library for writing tests as shell scripts.

Only GNU bash is supported.

## Installation

First, build test.sh:

```shell script
make
```

Then copy `build/test.sh` to your project or put it in a central location, such as /opt/test.sh/test.sh.

## Usage

Source test.sh at the beginning of your test script. If test.sh is included in your project, you
may want to reference it relative to the script location:

```shell script
source "$(dirname "$(readlink -f "$0")")"/test.sh
```

A test script is a collection of tests. In inline mode, tests are delimited by calls to `set_test_name`.
In managed mode, tests are defined by test functions. You should not mix inline and managed mode in the
same test script.

Inline mode:

```shell script
source "$(dirname "$(readlink -f "$0")")"/test.sh

test_name "This is my first test"
assert_true true
```

Managed mode:

```shell script
source "$(dirname "$(readlink -f "$0")")"/test.sh

test_01() {
  test_name "This is my first test"
  assert_true true
}

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
options. Some implications of this are:

* You cannot affect the environment of the test script from a test function.
* The stack traces generated from test functions show 'environment' as the source file of the functions.
  The line number is relative to the function ignoring blank lines and starting in 0.

### Configuration

Configuration is expressed with environment variables. These variables can come from the environment
or from a configuration file. Variables set in the environment take precedence over those defined
in the configuration file.

The configuration file is sourced, so it can contain any shell code. Normally you would
put only variable assignments in the configuration file.

If the variable CONFIG_FILE is defined, the configuration file will be loaded from that location.
Otherwise a file named 'test.sh.config' will be searched in these locations (see section 'Variables reference'):

* $TEST_SCRIPT_DIR
* $TESTSH_DIR

Available configuration variables:

* VERBOSE

  Values: 0 or 1, default 0.

  If set to 1, then the standard output and error are displayed in the main output in addition to
  being saved to the log file.

* DEBUG

  Values: 0 or 1, default 0.

  If set to 1, activate 'set -x'.

* INCLUDE_GLOB

  The include file glob used in the default INCLUDE_PATH. The default value is 'include*.sh'

* INCLUDE_PATH

  A colon separated list of include locations. Each location is a file glob.

  The default value is '$TESTSH_DIR/$INCLUDE_GLOB:$TEST_SCRIPT_DIR/$INCLUDE_GLOB'.

  Each include file found will be sourced. Include files are portions of shell code
  shared by your tests.

* FAIL_FAST

  Values: 0 or 1, default 1. Only used in managed mode.

  If set to 1, failure of a test fuction will interrupt the script and the remaining test functions will
  be skipped.

  If set to 0, all test functions will be executed.

### Variables reference

This is the list of variables defined by test.sh:

* TESTSH_DIR: the directory of test.sh.
* TEST_SCRIPT_DIR: the directory of the test script.
* CONFIG_FILE: the location of the effective configuration file.
* TESTOUT_FILE: the log file.

### Function reference

This is the list of functions defined by test.sh that you can use in a test script.

* run_tests

  Syntax:

  ```shell script
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
    set_test_name "The name of this test"
    # the test code goes here
  }
  ```

  They should start with a call to `set_test_name` and should not call `set_test_name` more than once.
  The remaing code is the test itself, which usually includes some of the following:
  * Initialization code
  * Execution code
  * Validation code
  TODO: unfinished

* set_test_name

  Syntax:

  ```shell script
  set_test_name <test name>
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

  ```shell script
  assert_true <shell command> [message]
  ```

* assert_false

  Syntax:

  ```shell script
  assert_false <shell command> [message]
  ```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)
