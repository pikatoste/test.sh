<!-- BADGE-START -->
[![](https://github.com/pikatoste/test.sh/workflows/CI/badge.svg)](https://github.com/pikatoste/test.sh/actions)
[![](https://raw.githubusercontent.com/pikatoste/test.sh/assets/coverage.svg?sanitize=true)](https://pikatoste.github.io/test.sh/releases/latest/buildinfo/coverage/)

See https://pikatoste.github.io/test.sh/.
<!-- BADGE-END -->

# test.sh

test.sh is a bash library for writing tests as shell scripts.

Only GNU bash is supported. test.sh has been developed and tested with bash version 4.4.20.

## Installation

From a [prebuilt release](https://pikatoste.github.io/test.sh/releases/): download and copy test.sh to your project
or to a central location, such as /opt/test.sh/test.sh.

From sources:

1. Build test.sh:

    ```shell script
    make
    ```

2. Copy `build/test.sh` to your project or put or to a central location, such as /opt/test.sh/test.sh.

## Usage

A test script looks like this:

```shell script
#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/test.sh

start_test "This is a passing test"
assert_true true

start_test "This is a failing test"
assert_true false
```

This test script contains two tests, one that passes and one that fails.
It is written in *inline* mode; you can also choose *managed* mode, and the test becomes:

```shell script
#!/bin/bash
test_01() {
  start_test "This is a passing test"
  assert_true true
}

test_02() {
  start_test "This is a failing test"
  assert_true false
}

source "$(dirname "$(readlink -f "$0")")"/test.sh

run_tests
```

In _managed_ mode you write each test in a separate function and then invoke `run_tests` to run your tests. This mode
supports running all tests despite failures.

In _inline_ mode tests are delimited by calls to `start_test` and you don't invoke `run_tests`. In this mode,
the first failed test terminates the script.

You should not mix inline and managed mode in the same test script.

The output of a test script is a colorized summary with the result of each test. Both tests above produce the
same output:

<pre><font color="#4E9A06">* This is a passing test</font>
<font color="#CC0000">* This is a failing test</font>
</pre>

The standard output and error of the test script are redirected to a log file.
This file is named after the test script with the
suffix '.out' appended and is located in directory 'testout' relative to the test script. For example, if your
test script is `test/test_something.sh`, the output will be logged to `test/testout/test_something.sh.out`.
Lines in the log file coming from test.sh, i.e. not from the test script or the commands it executes,
are prefixed with the string '[testsh]', which is colorized to show the
category of the message: blue for info, orange for warnings and red for errors.

Test failures will cause a stack trace to be logged. The log output of the managed sample test is:

<pre><font color="#3465A4">[test.sh]</font> Start test: This is a passing test
<font color="#3465A4">[test.sh]</font> Start test: This is a failing test
<font color="#CC0000">[test.sh]</font> Assertion failed: expected success but got failure in: &apos;false&apos;
<font color="#CC0000">[test.sh]</font> Error in expect_true(test.sh:347): &apos;false&apos; exited with status 1
<font color="#CC0000">[test.sh]</font>  at assert(test.sh:364)
<font color="#CC0000">[test.sh]</font>  at assert_true(test.sh:370)
<font color="#CC0000">[test.sh]</font>  at test_02(mymanagedtest.sh:9)
<font color="#CC0000">[test.sh]</font>  at run_test(test.sh:201)
<font color="#CC0000">[test.sh]</font>  at run_tests(test.sh:231)
<font color="#CC0000">[test.sh]</font>  at main(mymanagedtest.sh:14)
</pre>

Currently test.sh does not deal with running test scripts; for this purpose you can use
[Makefile.test](https://github.com/box/Makefile.test).

### Sourcing test.sh

There are specific requirements on the position in a test script of the source command that loads test.sh,
depending on the setting of configuration variables SUBSHELL and REENTER:

* If SUBSHELL is set to 'never', there are no specific requirements.

* Otherwise, if REENTER is true, the source command should be after function definitions and before code at the
main level. Any code before test.sh is sourced will be reexecuted in each subshell invocation.
You should organize your script as follows: _function definitions_, _source test.sh_,
_main code_.

  Under this configuration some code could be executed in a subshell (see [Subshells](#subshells)). When REENTER
  is true, subshells restart the test script to redefine functions in the current subshell.
  This redefinition is only accomplished if these functions
  are defined before sourcing test.sh. You probably don't want to reexecute the test script main code
  when reentered from a subshell, and that's why the main test script code is _after_ sourcing test.sh (when test.sh is
  sourced as a result of a subshell invocation, the source command never returns).

* Otherwise, the source command should be at the beginning of the test script, before function definitions and any code
that affects these functions.

  Under this configuration some code could be executed in a subshell (see [Subshells](#subshells)). When REENTER
  is false, subshells simply execute the requested code. All variables and functions are available in the subshell
  because test.sh does `set -o allexport`, but this setting only affects code _after_ test.sh is sourced. Variables
  and functions defined before test.sh is are not available in the subshell
  unless explicitly exported, for example with `set -o allexport` at the beginning of the test
  script.

The aspect of the source command itself depends on the location of test.sh and whether you restrict the directory
where test scripts can be run from.

* If test.sh is installed at a central location, source it using an absolute path. For example:

  ```shell script
  source /opt/test.sh/test.sh
  ```

* If test.sh is installed relative to the test script and you want to support executing it from any
directory, specify a path relative to the dynamically-obtained location of the test script. For example,
if test.sh is in the same directory as the test script:

  ```shell script
  source "$(dirname "$(readlink -f "$0")")"/test.sh
  ```

* If test.sh is installed relative to the test script and you want to restrict the directory from which the test script
can be launched, specify a path relative to the chosen directory. For example:

  ```shell script
  source ./test.sh
  ```

### Implicit assertion

test.sh sets `-o errexit`, so any command that does not return success will be considered as
a failure. In inline mode, the first failure terminates the script; in managed mode this behaviour
depends on the configuration variable FAIL_FAST. In either case, a failure of an individual test
will cause the script to return failure.

There are some pitfalls with `-o errexit` to be aware of. Bash ignores this setting in the following situations:

* In the condition of an `if`, `while` or `until`.
* In expressions using `||` or `&&` except the last command.
* In negated commands, i.e. preceded by '!'.

In all of the above situations, expressions that evaluate to false will not trigger exit. Moreover, as any command
executed as part of the expression runs in _ignored errexit context_, if the command is a function then the
result of all commands in the function but the last are ignored. This means that if you have a validation function
such as:

```shell script
validate() {
  # check 1
  [[ $A = a ]]
  # check 2
  [[ $B = b ]]
}
```

then, expressions of the form `if validate; then ... fi`, `while validate; do ... done`, `validate || echo "error"`,
`! validate` will not behave as expected as all checks but the last will be ignored. In the last case, the result
of the negated expression will not trigger exit even if it evaluates to false.

### setup/teardown

The following semantics apply to the setup & teardown functions:

* `setup_test_suite`: if present, it will be called once before any test and `setup_test` functions. Failure in this
function will fail the test immediatelly, i.e. no tests will be executed.

* `teardown_test_suite`: if present, it will be called once after all tests and `teardown_test` functions. A failure
in this function will be reported as a warning in the main output and an error will be logged, but will not make
the test script to fail.

* `setup_test`: if present, it will be called before every test. A failure in this function will fail the
test but will not prevent other tests from executing (if FAIL_FAST is false). Because the test fails, the script
will fail also.

* `teardown_test`: if present, it will be called after every test. A failure in this function will be reported
as a warning in the main output and an error will be logged, but will not make the test to fail.

These semantics break in corner cases when SUBSHELL is set to 'never':
* A failure in `teardown_test` or `teardown_test_suite` will make the test script to fail.
* In inline mode, `teardown_test_suite` will not be called if `teardown_test` fails when invoked for a failed test or
the last test even if it succeeds.
* In managed mode, `teardown_test_suite` will not be called if `teardown_test` fails when invoked
for a failed test.

### Subshells

If allowed by the SUBSHELL configuration option, test.sh will execute in a subshell (i.e. `bash -c`)
code whose exit status must be monitored but not terminate the script on failure.
This includes test functions in managed mode, teardown functions and assert functions.

When code is executed in a subshell it cannot affect the environment of the caller. For example, variables set in
a test function evaluated in a subshell will not be seen from other test functions or the main script.

Subshells inherit the environment of the caller, which includes variables, functions and the shell
options, but the source file and line numbers of functions inherited from the environment are lost
in the subshell,
affecting the quality of stack traces. The REENTER configuration option overcomes this limitation.

### Stack traces

Errors logged contain a message with the function, source file and line number where the error occurred, optionally
followed by a stack trace depending on the STACK_TRACE configuration setting. Source file paths in the error message
and individual frames in the stack trace can be pruned with configuration option PRUNE_PATH.

Errors are logged for each individual test, setup and teardown functions, and the main script if in managed mode. This means
that the same log file can contain more than one error.

If you use `return` with a value other than 0 inside a function to trigger failure, the stack trace will attribute
the return statement to the calling function instead of the function to which the return belongs.
For this reason, using return to indicate failure is discouraged.

Stack traces include frames in test.sh, and they can be quite a large number if SUBSHELL is set to 'always'.
For example, this test script (the line `set -o allexport` makes the script support also REENTER false):

```shell script
#!/bin/bash
set -o allexport
test_01() {
  assert_true false "this is a test killer"
}

SUBSHELL=${SUBSHELL:-always}
STACK_TRACE=full
PRUNE_PATH="*/"
source "$(dirname "$(readlink -f "$0")")"/test.sh

run_tests
```

will log this output:

<pre><font color="#CC0000">[test.sh]</font> Assertion failed: this is a test killer: expected success but got failure in: &apos;false&apos;
<font color="#CC0000">[test.sh]</font> Error in source(test.sh:381): &apos;false&apos; exited with status 1
<font color="#CC0000">[test.sh]</font>  at main(mytest.sh:10)
<font color="#CC0000">[test.sh]</font>  at subshell(test.sh:278)
<font color="#CC0000">[test.sh]</font>  at expect_true(test.sh:348)
<font color="#CC0000">[test.sh]</font>  at call_assert(test.sh:361)
<font color="#CC0000">[test.sh]</font>  at assert_true(test.sh:369)
<font color="#CC0000">[test.sh]</font>  at test_01(mytest.sh:4)
<font color="#CC0000">[test.sh]</font>  at run_test(test.sh:201)
<font color="#CC0000">[test.sh]</font>  at source(test.sh:381)
<font color="#CC0000">[test.sh]</font>  at main(mytest.sh:10)
<font color="#CC0000">[test.sh]</font>  at subshell(test.sh:278)
<font color="#CC0000">[test.sh]</font>  at run_tests(test.sh:229)
<font color="#CC0000">[test.sh]</font>  at main(mytest.sh:12)
<font color="#CC0000">[test.sh]</font> test_01 FAILED
<font color="#CC0000">[test.sh]</font> Error in run_tests(test.sh:220): &apos;[[ $failures == 0 ]]&apos; exited with status 1
<font color="#CC0000">[test.sh]</font>  at main(mytest.sh:12)
</pre>

Because the error was triggered from `assert_true` --which is an internal test.sh function-- the error
message points to test.sh and not mytest.sh. This is a good reason to activate stack traces.
Note that there's a second error, this one is triggered in managed mode, SUBSHELL=always and FAIL_FAST false when the script
(not the test) fails. This second error also benefits from the stack trace.

In contrast, if you run `SUBSHELL=teardown ./mytest.sh` the stack trace is more compact:

<pre><font color="#CC0000">[test.sh]</font> Assertion failed: this is a test killer: expected success but got failure in: &apos;false&apos;
<font color="#CC0000">[test.sh]</font> Error in expect_true(test.sh:348): &apos;false&apos; exited with status 1
<font color="#CC0000">[test.sh]</font>  at call_assert(test.sh:363)
<font color="#CC0000">[test.sh]</font>  at assert_true(test.sh:369)
<font color="#CC0000">[test.sh]</font>  at test_01(mytest.sh:4)
<font color="#CC0000">[test.sh]</font>  at run_test(test.sh:201)
<font color="#CC0000">[test.sh]</font>  at run_tests(test.sh:231)
<font color="#CC0000">[test.sh]</font>  at main(mytest.sh:12)
</pre>

When REENTER is false, stack traces involving subshells are different.
For example, the log output of the previous script executed as `REENTER= ./mytest.sh` is:

<pre><font color="#CC0000">[test.sh]</font> Assertion failed: this is a test killer: expected success but got failure in: &apos;false&apos;
<font color="#CC0000">[test.sh]</font> Error in (:0): &apos;false&apos; exited with status 1
<font color="#CC0000">[test.sh]</font>  at subshell(environment:10)
<font color="#CC0000">[test.sh]</font>  at expect_true(environment:0)
<font color="#CC0000">[test.sh]</font>  at assert(environment:7)
<font color="#CC0000">[test.sh]</font>  at assert_true(environment:0)
<font color="#CC0000">[test.sh]</font>  at test_01(environment:0)
<font color="#CC0000">[test.sh]</font>  at run_test(environment:19)
<font color="#CC0000">[test.sh]</font>  at subshell(test.sh:279)
<font color="#CC0000">[test.sh]</font>  at run_tests(test.sh:229)
<font color="#CC0000">[test.sh]</font>  at main(mytest.sh:12)
<font color="#CC0000">[test.sh]</font> test_01 FAILED
<font color="#CC0000">[test.sh]</font> Error in run_tests(test.sh:220): &apos;[[ $failures == 0 ]]&apos; exited with status 1
<font color="#CC0000">[test.sh]</font>  at main(mytest.sh:12)
</pre>

The differences are:

* The error message shows no source file and 0 as the line number; this happens when the subshell evaluates a
simple expression.
* The subshell invocation sequence is simpler.
* All frames following the first subshell invocation show 'environment' as the source file and a line number
relative to the definition of the function in the environment, wich might be different from the definition
in the source file. For example, blank lines are removed from definitions of functions in the environment.

### Assertions

Explicit assertions were originally conceived as an aid in locating the origin of failures. The error reporting
facilities currently implemented have alleviated this need and as a result assertions have not received much
attention.

Currently there are only two assert
functions, `assert_true` and `assert_false`. See the description of these functions in the
[Function reference](#function-reference).

### Predefined variables

test.sh defines these variables, which are available to the test script after test.sh is sourced:

* VERSION: the version of test.sh.
* TESTSH: full path of the sourced test.sh.
* TESTSH_DIR: the directory of test.sh.
* TEST_SCRIPT_DIR: the directory of the test script.
* CONFIG_FILE: the location of the effective configuration file.
* TESTOUT_FILE: the log file.
* TESTOUT_DIR: the directory of the log file.

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

Boolean variables are considered true when not empty and false otherwise (undefined or empty).

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

  A colon-separated list of include locations. Each location is a file glob.

  The default value is '$TESTSH_DIR/$INCLUDE_GLOB:$TEST_SCRIPT_DIR/$INCLUDE_GLOB'.

  Each include file found will be sourced. Include files are portions of shell code
  shared by your tests.

* FAIL_FAST

  Boolean. Default true. Only used in managed mode.

  If true, failure of a test function will interrupt the script and the remaining test functions will
  be skipped.

  If false, all test functions will be executed. Requires SUBSHELL=always.

* SUBSHELL

  Values: never, teardown or always. Default: always when FAIL_FAST is false; teardown when FAIL_FAST is true.

  * never: never start subshells. Incompatible with FAIL_FAST false. Breaks teardown semantics
    (see [setup/teardown](#setupteardown)): any failure in a teardown function will terminate the script with
    failure. In this mode, `teardown_test_suite` will not get called when both a test and `teardown_test` fail.

  * teardown: only start subshells to execute `teardown_test` and `teardown_test_suite` functions.
    Incompatible with FAIL_FAST false.
    Enforces teardown semantics (see [setup/teardown](#setupteardown)):`teardown_test` and `teardown_test_suite`
    are always called in this mode and failures in these functions don't fail the test nor interrupt the script.

  * always: start a subshell to execute test functions, teardown functions and assert expressions. Required when
    FAIL_FAST is false. Enforces teardown semantics (see [setup/teardown](#setupteardown)):
    `teardown_test` and `teardown_test_suite` are always called in this mode and failures in
    these functions don't fail the test nor interrupt the script.

  See [Subshells](#subshells).

* REENTER

  Boolean. Default true.

  If true, when test.sh starts a subshell it will reexecute he test script and source again other involved scripts:
  test.sh and included files. This redefines functions in the subshell's context and allows
  stack traces to correctly refer to source files and line numbers.

  If false, subshells will reexecute the test script nor source again involved scripts. Functions defined in the calling shell are
  available to the subshell because they are exported in the environment, but the source file and line number of
  these functions is lost; stack traces with frames referencing these functions will
  show 'environment' as the source file and a line number relative to that function's definition
  _in the environment_, which might be different from the original function's definition in the source file.
  For example, blank lines are not present in the function definition in the environment.
  See [Stack traces](#stack-traces).

  The value of this variable affects the structure of test scripts (see [Sourcing test.sh](#sourcing-testsh)).

* STACK_TRACE

  Values: no or full. Default: full.

  * no: do not output stack traces.
  * full: include all frames.


* PRUNE_PATH

  Default: ${PWD}/

  A pattern that is matched at the beginning of each source file path in error reports, i.e. the error message and
  stack trace frames. The longest match is removed from the path. If there's no match the path not modified.

  For example, to strip all directories and leave only file names you would set `PRUNE_PATH="*/"`.

* TEST_MATCH

  Default: ^test_

  A regular expression that is matched against function names to discover test functions in managed mode.
  It is evaluated by grep.

### Function reference

This is the list of functions defined by test.sh that you can use in a test script.

* run_tests

  Syntax:

  ```text
  run_tests [test function]...
  ```

  Runs the specified test functions in managed mode. With no arguments, runs _discovered_ test
  functions: functions whose name match the pattern configured in TEST_MATCH. Discovered test functions will be executed
  in function name order, not function definition order. Test functions specified as arguments
  will be executed in the order of the arguments.

  You should call run_tests only once.

  A test function should look:

  ```shell script
  test_xxx() {
    start_test "Short description of this test"
    # the test code goes here
  }
  ```

  It should start with a call to `start_test` and should not call `start_test` more than once.

* start_test

  Syntax:

  ```text
  start_test <short test description>
  ```

  Set the test description of the current test. The test description is displayed in the main output and should
  be a single line of text. In inline mode, defines the start of a test (and the end of the previous test).
  In managed mode, sets the test description of the current test function.

* setup_test_suite

  If defined, this function will be called only once before any test.
  A failure in this function will cause failure of the script and no test will be executed.

  See [setup/teardown](#setupteardown).

* teardown_test_suite

  If defined, this function will be called once after all tests even if there are failures.
  A failure in this function will not cause failure of the script, but will cause a warning
  message to be displayed on the main output.

  See [setup/teardown](#setupteardown).

* setup_test

  If defined, this function will be called before each test.
  A failure in this function will cause failure of the test.

  See [setup/teardown](#setupteardown).

* teardown_test

  If defined, this function will be called after each test even if the test fails.
  A failure in this function will not cause failure of the test, but will cause a warning
  message to be displayed on the main output.

  See [setup/teardown](#setupteardown).

* assert_true

  Syntax:

  ```text
  assert_true <shell command> [message]
  ```

  Executes \<shell command\>. If the result code is not success, an error message is logged and an error triggered.

  For example, the following test script:

  ```shell script
  #!/bin/bash

  SUBSHELL=never
  STACK_TRACE=full
  PRUNE_PATH="*/"
  source "$(dirname "$(readlink -f "$0")")"/test.sh

  assert_true false "this is a test killer"
  ```

  will log the following output (with STACK_TRACE=full and SUBSHELL=[never\|teardown]):

  <pre><font color="#CC0000">[test.sh]</font> Assertion failed: this is a test killer: expected success but got failure in: &apos;false&apos;
  <font color="#CC0000">[test.sh]</font> Error in expect_true(test.sh:348): &apos;false&apos; exited with status 1
  <font color="#CC0000">[test.sh]</font>  at call_assert(test.sh:363)
  <font color="#CC0000">[test.sh]</font>  at assert_true(test.sh:369)
  <font color="#CC0000">[test.sh]</font>  at main(mytestasserttrue.sh:8)
  </pre>

* assert_false

  Syntax:

  ```text
  assert_false <shell command> [message]
  ```

  Executes \<shell command\>. If the result code is success, an error message is logged and an error triggered.
  For example, the following test script (with STACK_TRACE=full and SUBSHELL=[never\|teardown]):

  ```shell script
  #!/bin/bash

  SUBSHELL=never
  STACK_TRACE=full
  PRUNE_PATH="*/"
  source "$(dirname "$(readlink -f "$0")")"/test.sh

  assert_false true "this is a test killer"
  ```

  will log the following output:

  <pre><font color="#CC0000">[test.sh]</font> Assertion failed: this is a test killer: expected failure but got success in: &apos;true&apos;
  <font color="#CC0000">[test.sh]</font> Error in expect_false(test.sh:353): &apos;false&apos; exited with status 1
  <font color="#CC0000">[test.sh]</font>  at call_assert(test.sh:363)
  <font color="#CC0000">[test.sh]</font>  at assert_false(test.sh:373)
  <font color="#CC0000">[test.sh]</font>  at main(mytestassertfalse.sh:8)
  </pre>

    **NOTE**: \<shell command\> is executed in _ignored errexit context_
    (see [Implicit assertion](#implicit-assertion)). If \<shell command\> calls a function designed to
    run in errexit context, you should invoke \<shell command\> with the `subshell` function. For example,
    the assertion `assert_false my_validation_function`, when `my_validation_function` requires errexit
    context, should be written as: `assert_false "subshell my_validation_function"`.

* subshell

  Syntax:

  ```text
  subshell <shell command>
  ```

  Executes \<shell command\> in a subshell with errexit context enabled. This is useful when you need to execute code
  in errexit context but in a situation where bash is in ignored errexit context, such as when negating an expression
  with `!`. It is also useful for capturing the result code of an expression that might fail.
  Use this function instead of plain `bash -c`
  invocations to preserve the error tracing capacity of test.sh.

  See [Subshells](#subshells).

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

To run the tests run `make check`. This target expects test.sh to be built already, so to run the test on a clean
repository run `make all check`. The tests are run in the temporary directory `runtest` and the test logs can be
found in `runtest/test/testout`.

Other Makefile targets:

* all: build test.sh. Produces `build/test.sh`.
* clean: remove the `build` and `runtest` directories.
* check|test: run the tests. Requires an already built test.sh; for this target to pick changes to test.sh, do
  `make clean all check`. Test results are in `runtest/test/testout`.
* coverage: run the tests and generate an HTML coverage report in `runtest/coverage`.
Requires [Bashcov](https://github.com/infertux/bashcov), so you must install it first:

    ```shell script
    sudo apt isntall ruby
    gem install bashcov
    ```

## License
[MIT](https://choosealicense.com/licenses/mit/)
