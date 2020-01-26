<!-- BADGE-START -->
[![](https://github.com/pikatoste/test.sh/workflows/CI/badge.svg)](https://github.com/pikatoste/test.sh/actions)
[![](https://raw.githubusercontent.com/pikatoste/test.sh/assets/coverage.svg?sanitize=true)](https://pikatoste.github.io/test.sh/releases/latest/buildinfo/coverage/)

See https://pikatoste.github.io/test.sh/.
<!-- BADGE-END -->

# test.sh

test.sh is a bash library for writing tests as shell scripts.

Requires GNU bash version \>= 4.4.
The development environment is Ubuntu 18.04 with bash version 4.4.20.
It has been tested succesfully on versions up to 5.0.11.

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

test.sh is a bash library designed to be sourced in test scripts. When executed, it prints a message with
the version number and a link to this repository.

A test script looks like this:

```shell script
#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/test.sh

start_test "This is a passing test"
assert_true true

start_test "This is a failing test"
assert_true false
```

This test script contains two tests: one that passes and one that fails.
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

The output of a test script is a colorized summary with the result of each test. Both test scripts above produce the
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
category of the message: blue for info, orange for warnings and red for errors. test.sh logs the following events:
* The start of each test
* The outcome of each test
* Explicit assertion failures: an assertion-specific error message and a stack trace
(see [Stack traces](#stack-traces)).
* Implicit assertion failures (see [Implicit assertion](#implicit-assertion): a stack trace
(see [Stack traces](#stack-traces)).

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

There are no specific requirements on the position in a test script of the source command that loads test.sh.
Just be aware that you can set configuration variables directly in the test script before sourcing test.sh, and
that configuration variables set this way will have precedence over the inherited environment and the configuration
file.

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

The errexit option is closely related to the ERR trap, but they are not the same. The ERR signal is raised when
a command returns non-zero, but does not imply exiting. It shares with errexit the conditions under which it is
ignored, i.e. ignored errexit context is also ignored ERR trap context.
Because both the ERR trap and errexit are active at the
same time, test.sh assumes that after an ERR trap the shell will exit, but this is not always true; this feature is
leveraged to enforce teardown semantics and support FAIL_FAST false, but can have unexpected effects also.
The exact situation when this happens is in command substitutions (`$(...)` or `` `...` `` expressions) evaluated in
the argument list of a command. For example, consider the expression `my_function $(false; true)`. The `false`
command will trigger the ERR trap and, because of errexit, `true` will not execute, but the call to `my_function` will
proceed.

The ERR trap is used by tests.sh to generate error reports. When in ignored ERR trap context, such as in
`! my_function $(false; true)`, no ERR signal nor exit will get triggered; this is coherent. But when
not in ignored ERR trap context, if `my_function` does fail in turn, two traps fill be raised: one for the command
substitution and another one for `my_function`. This means two error reports in test.sh. It is common to see this
in assertions. For example:

```shell script
assert_equals "marker: expected content" "$(grep marker "$FILE")"
```

If the grep command returns non-zero, an ERR signal is raised and an error report printed. As a consequence of this
error, the assertion will probably fail also and a second ERR signal will be raised, printing another error. The
first error occurs in the command substitution while the second one does in `assert_true`. See this in action:

```shell script
source ./test.sh
assert_equals "marker: expected content" "$(grep marker missing_file)"
```

<pre>$ VERBOSE=1 ./doubleerror.sh
grep: missing_file: No such file or directory
<font color="#CC0000">[test.sh]</font> Error in main(doubleerror.sh:2): &apos;grep marker missing_file&apos; exited with status 2
<font color="#CC0000">[test.sh]</font> Assertion failed: expected &apos;marker: expected content&apos; but got &apos;&apos;
<font color="#CC0000">[test.sh]</font> Error in expect_true(test.sh:364): &apos;[[ &quot;marker: expected content&quot; = &quot;&quot; ]]&apos; exited with status 1
<font color="#CC0000">[test.sh]</font>  at assert(test.sh:383)
<font color="#CC0000">[test.sh]</font>  at assert_equals(test.sh:406)
<font color="#CC0000">[test.sh]</font>  at main(doubleerror.sh:2)
</pre>

An alternative way to write the above assertion in an effort to get rid of the double error is:

```shell script
source ./test.sh
FOUND=$(grep marker missing_file)
assert_equals "marker: expected content" "$FOUND"
```

now the command substitution is not errexit-protected because it is not part of an argument list: if grep fails the
assertion will not execute. However, you still get a double error though this time both errors refer to the same
failure:

<pre>$ VERBOSE=1 ./singleerror.sh
grep: missing_file: No such file or directory
<font color="#CC0000">[test.sh]</font> Error in main(singleerror.sh:2): &apos;grep marker missing_file&apos; exited with status 2
<font color="#CC0000">[test.sh]</font> Error in main(singleerror.sh:2): &apos;FOUND=$(grep marker missing_file)&apos; exited with status 2
</pre>

How come? we are seeing a tricky part of ERR signals: it is raised (and trapped) in each nested subshell environment.
Deeper subshell nesting will produce more repetitions; for example, the following snippet prints three errors, each one
at a different nesting level:

```shell script
source ./test.sh
( FOUND=$(grep marker missing_file) )
assert_equals "marker: expected content" "$FOUND"
```

<pre>$ VERBOSE=1 ./tripleerror.sh
grep: missing_file: No such file or directory
<font color="#CC0000">[test.sh]</font> Error in main(tripleerror.sh:2): &apos;grep marker missing_file&apos; exited with status 2
<font color="#CC0000">[test.sh]</font> Error in main(tripleerror.sh:2): &apos;FOUND=$(grep marker missing_file)&apos; exited with status 2
<font color="#CC0000">[test.sh]</font> Error in main(tripleerror.sh:2): &apos;( FOUND=$(grep marker missing_file) )&apos; exited with status 2
</pre>

However, there's something you can do. Resorting to the internals of error handling in test.sh, this script finally
achieves the desired effect:

```shell script
source ./test.sh
FOUND=$(ERR_HANDLERS=(save_stack); grep marker missing_file)
assert_equals "marker: expected content" "$FOUND"
```
gets:

<pre>$ VERBOSE=1 ./singleerror.sh
grep: missing_file: No such file or directory
<font color="#CC0000">[test.sh]</font> Error in main(singleerror.sh:2): &apos;grep marker missing_file&apos; exited with status 2
</pre>

The explanation is: the `ERR_HANDLERS=(save_stack)` resets the reaction to ERR traps in the subshell environment
introduced by the command substitution. The error is captured but not printed.

After all, maybe the first form of double error wasn't that bad.

### setup/teardown

The following semantics apply to the setup & teardown functions:

* `setup_test_suite`: if present, it will be called once before any test and `setup_test` functions. Failure in this
function will fail the test immediatelly, i.e. no tests will be executed.

  A failure in this function is reported in the main output and the error is logged in the log output.

* `teardown_test_suite`: if present, it will be called once after all tests and `teardown_test` functions. A failure
in this function will be reported as a warning in the main output and an error will be logged, but will not make
the test script to fail.

* `setup_test`: if present, it will be called before every test. A failure in this function will fail the
test but will not prevent other tests from executing (if FAIL_FAST is false). Because the test fails, the script
will fail also.

  In managed mode, the test failure reported in the main output is the name of the test function instead of
  the test description set with `start_test`.

* `teardown_test`: if present, it will be called after every test. A failure in this function will be reported
as a warning in the main output and an error will be logged, but will not make the test to fail.

### Subshells

test.sh will execute in a subshell environment code whose exit status must be monitored but not terminate
the script on failure. This includes test functions in managed mode, teardown functions and assert expressions
in `assert_false`.

When code is executed in a subshell it cannot affect the environment of the caller. For example, variables set in
a test function evaluated in a subshell will not be seen from other test functions or the main script.

### Stack traces

Errors logged contain a message with the function, source file and line number where the error occurred, optionally
followed by a stack trace depending on the STACK_TRACE configuration setting. Source file paths in the error message
and individual frames in the stack trace can be pruned with configuration option PRUNE_PATH.

Errors are logged for each individual test, setup and teardown functions, and the main script if in managed mode. This means
that the same log file can contain more than one error.

If you use `return` with a value other than 0 inside a function to trigger failure, the stack trace will attribute
the return statement to the calling function instead of the function to which the return belongs.
For this reason, using return to indicate failure is discouraged.

Stack traces include frames in test.sh which reveal the implementation but are usually not relevant to debug test
scripts. Because of this you might be tempted to disable stack traces (configuration variable STACK_TRACE),
thinking that the error message provides enough information to track the source of an error. But this is only
true in simple inline mode scripts that don't call other functions, including test.sh assertion functions.
For example, let's review the stack trace generated by this test script:

```shell script
#!/bin/bash

test_01() {
  assert_true false "this is a test killer"
}

PRUNE_PATH="*/"
source "$(dirname "$(readlink -f "$0")")"/test.sh

run_tests
```

will log this output:

<pre><font color="#CC0000">[test.sh]</font> Assertion failed: this is a test killer: expected success but got failure in: &apos;false&apos;
<font color="#CC0000">[test.sh]</font> Error in expect_true(test.sh:343): &apos;false&apos; exited with status 1
<font color="#CC0000">[test.sh]</font>  at assert(test.sh:360)
<font color="#CC0000">[test.sh]</font>  at assert_true(test.sh:366)
<font color="#CC0000">[test.sh]</font>  at test_01(mytest.sh:6)
<font color="#CC0000">[test.sh]</font>  at run_test(test.sh:196)
<font color="#CC0000">[test.sh]</font>  at run_tests(test.sh:228)
<font color="#CC0000">[test.sh]</font>  at main(mytest.sh:13)
<font color="#CC0000">[test.sh]</font> FAILED: test_01
</pre>

Because the error was triggered from `assert_true` --which is an internal test.sh function-- the error
message points to test.sh and not mytest.sh. This is a good reason to activate stack traces.
Note that there's a second error: this one is triggered in managed mode false when the script fails because some
tests failed. This second error also benefits from the stack trace.

### Assertions

Explicit assertions were originally conceived as an aid in locating the origin of failures. The error reporting
facilities currently implemented have alleviated this need and as a result assertions have not received much
attention.

Currently there are three assert
functions: `assert_true`, `assert_false` and `assert_equals`. See the description of these functions in the
[Function reference](#function-reference).

`assert_true` and `assert_false` accept an expression which is evaluated with `eval` in errexit context.
There are quoting issues to be aware of:

* If the expression is surrounded by double quotes, parameter expansion will occur at call point. If single quotes
are used, then parameter expansion will occur at the evaluation point.
* Double quotes inside the expression have to be escaped if the expression is surrounded by double quotes.

The quoting issues also apply to the `result_of` function.

### Predefined variables

test.sh defines these variables, which are available to the test script after test.sh is sourced:

* VERSION: the version of test.sh.
* TESTSH: full path of the sourced test.sh.
* TESTSH_DIR: the directory of test.sh.
* TEST_SCRIPT: full path of the test script.
* TEST_SCRIPT_DIR: the directory of the test script.
* CONFIG_FILE: the location of the effective configuration file.

Configuration variables are set to the effective value.

### Configuration

Configuration is expressed with environment variables. These variables can come from the environment
or from a configuration file. Variables set in the environment take precedence over those defined
in the configuration file. Configuration variables can be set directly in the test script before
sourcing test.sh.

The configuration file is sourced, so it can contain any shell code. Normally you would
put only variable assignments in the configuration file.

If the variable CONFIG_FILE is defined, the configuration file will be loaded from that location.
Otherwise a file named 'test.sh.config' will be searched in these locations (see section
[Predefined variables](#predefined-variables)'):

* $TEST_SCRIPT_DIR
* $TESTSH_DIR
* Working directory

Boolean variables are considered true when not empty and false otherwise (undefined or empty).

The configuration is read before any configuration variable takes effect. The means that
errors are displayed in the main output because the redirection to LOG_FILE has not been done yet.
For the same reason, no color is applied: the COLOR configuration has not been yet processed.

Temporary files are created in TMPDIR if set, otherwise in `/tmp`.

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
  be skipped. Each skipped test is displayed in the main output as `[skipped] <test function>`.

  If false, all test functions will be executed.

* STACK_TRACE

  Values: no or full. Default: full.

  * no: do not log stack traces.
  * full: log stack traces.


* PRUNE_PATH

  Default: ${PWD}/

  A pattern that is matched at the beginning of each source file path in error reports, i.e. the error message and
  stack trace frames. The longest match is removed from the path. If there's no match the path is not modified.

  For example, to strip all directories and leave only file names you would set: `PRUNE_PATH="*/"`.

* TEST_MATCH

  Default: ^test_

  A regular expression that is matched against function names to discover test functions in managed mode.
  It is evaluated by grep.

* COLOR

  Values: yes, no. Default: yes.

  * yes: output ANSI color escape sequences in both main and log output.
  * no: do not output ANSI color escape sequences in neither main or log output.

* LOG_DIR_NAME

  The name of the log directory. Default: testout

* LOG_DIR

  Full path of the log directory. Default: `$TEST_SCRIPT_DIR/$LOG_DIR_NAME`

* LOG_NAME

  Name of the log file. Default: `$(basename "$TEST_SCRIPT").out`

* LOG_FILE

  Full path of the log file. Default: `$LOG_DIR/$LOG_NAME`

* LOG_MODE

  Values: overwrite, append. Default: overwrite

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

  You should call `run_tests` only once.

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

  STACK_TRACE=full
  PRUNE_PATH="*/"
  source "$(dirname "$(readlink -f "$0")")"/test.sh

  assert_true false "this is a test killer"
  ```

  will log the following output:

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
  For example, the following test script:

  ```shell script
  #!/bin/bash

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

* assert_equals

  Syntax:

  ```text
  assert_equals <expected> <current> [message]
  ```

  Compares \<expeced\> and \<current\> with the bash expression: `[[ $expected = $current ]]`.
  If the comparison fails, an error message is logged and an error triggered. The error message follows the pattern
  `Assertion failed: [<message>, ]expected '<expected>' but got '<current>'`.

* result_of

  Syntax:

  ```text
  result_of <shell command> [result variable]
  ```

  Executes \<shell command\> in errexit context and returns the result code in the variable specified or
  `LAST_RESULT` by default. Useful for capturing the result code of an expression that might fail. Can be used to avoid
  situations which would force ignored errexit context, such as negating expressions with `!`.
  Use this function instead of plain `bash -c`
  invocations to preserve the error tracing capacity of test.sh. The \<shell command\> is subject to quoting issues
  that are discussed in section [Assertions](#assertions).

  See [Subshells](#subshells).

* run_test_script

  Syntax:

  ```text
  run_test_script <test script>
  ```

  Executes \<test script\>, which is a relative or absolute path to a standalone test.sh-enabled test script.
  Relative paths are interpreted from `$TEST_SCRIPT_DIR`.

  Using this function is preferred over plain execution of the test script because it resets internal
  variables that govern the execution of test.sh and might affect the executed script. The current
  configuration of the calling script is passed to the executed script, with the following exceptions:

  * The current color settings (not the COLOR configuration variable) are reset.
  * LOG_DIR_NAME, LOG_DIR, LOG_NAME and LOG_FILE: these variables are reset to the value they had at the start
  of the calling script. Directing the called script log output to the calling script log file is not supported.
  These variables can only be set in the called script or in its configuration file.

  The main output of the executed script is directed to the log file of
  the calling script unless redirected elsewhere. For example, to redirect the main output of the executed
  script to the main output of the calling script, execute:

  ```text
  run_test_script <test script> >&3 2>&4
  ```

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
