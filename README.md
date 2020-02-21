<!-- BADGE-START -->
[![](https://github.com/pikatoste/test.sh/workflows/CI/badge.svg)](https://github.com/pikatoste/test.sh/actions)
[![](https://raw.githubusercontent.com/pikatoste/test.sh/assets/coverage.svg?sanitize=true)](https://pikatoste.github.io/test.sh/releases/latest/buildinfo/coverage/)

See https://pikatoste.github.io/test.sh/.
<!-- BADGE-END -->

# test.sh

test.sh is a bash library for writing tests as shell scripts.

Requires GNU bash version \>= 4.4.
It has been tested succesfully on versions up to 5.0.11.
The development environment is Ubuntu 18.04 with bash version 4.4.20.

## Installation

From a [prebuilt release](https://pikatoste.github.io/test.sh/releases/): download and copy test.sh to your project
or to a central location, such as /opt/test.sh/test.sh.

From sources:

1. Build test.sh:

    ```shell script
    make
    ```

2. Copy `build/test.sh` to your project or to a central location, such as /opt/test.sh/test.sh.

## Usage

test.sh is a bash library designed to be sourced in test scripts; if executed, it prints a message with
the version number and a link to this repository.

A test script looks like this:

```shell script
#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/test.sh

@test: "This is a passing test"
@body: {
  assert_success true
}

@test: "This is a failing test"
@body: {
  assert_success false
}

@run_tests
```

This test script contains two tests: one that passes and one that fails.
Tests are defined with a pair of `@test:` and `@body:` tags and executed with `@run_tests`.

The output of a test script is a colorized summary with the result of each test. The test script above prints:

<pre><font color="#4E9A06">* This is a passing test</font>
<font color="#CC0000">* This is a failing test</font>
</pre>

This report is printed to the standard output of the test script, referred in this document as the 'main output'.
The standard output and error of the test script are redirected to a log file.
This file is named after the test script with the
suffix '.out' appended and is located in directory 'testout' relative to the test script. For example, if your
test script is `test/test_something.sh`, the output will be logged to `test/testout/test_something.sh.out`.
Lines in the log file coming from test.sh, i.e. not from the test script or the commands it executes,
are prefixed with the string '[testsh]', which is colorized to show the
category of the message: blue for info, orange for warnings and red for errors. test.sh logs the following events:
* The start of each test
* The outcome of each test, either success or failure
* Any errors, basically non-zero exit status from any command. Errors are handled as exceptions; they log an error
message and a stack trace

The log output of the test example above is:

<pre><font color="#3465A4">[test.sh]</font> Start test: This is a passing test
<font color="#4E9A06">[test.sh]</font> PASSED: This is a passing test
<font color="#3465A4">[test.sh]</font> Start test: This is a failing test
<font color="#CC0000">[test.sh]</font> Assertion failed: expected success but got failure in: &apos;false&apos;
<font color="#CC0000">[test.sh]</font>  at throw_assert(test.sh:474)
<font color="#CC0000">[test.sh]</font>  at assert_success(test.sh:485)
<font color="#CC0000">[test.sh]</font>  at test_02(myfirsttest.sh:11)
<font color="#CC0000">[test.sh]</font>  at run_tests(test.sh:426)
<font color="#CC0000">[test.sh]</font>  at main(myfirsttest.sh:14)
<font color="#CC0000">[test.sh]</font> Caused by:
<font color="#CC0000">[test.sh]</font> Error in _eval(test.sh:267): &apos;false&apos; exited with status 1
<font color="#CC0000">[test.sh]</font>  at assert_success(test.sh:482)
<font color="#CC0000">[test.sh]</font>  at test_02(myfirsttest.sh:11)
<font color="#CC0000">[test.sh]</font>  at run_tests(test.sh:426)
<font color="#CC0000">[test.sh]</font>  at main(myfirsttest.sh:14)
<font color="#CC0000">[test.sh]</font> FAILED: This is a failing test
<font color="#CC0000">[test.sh]</font> 1 test(s) failed
</pre>

Currently test.sh does not deal with running test scripts; for this purpose you can use
[Makefile.test](https://github.com/box/Makefile.test).

### Anatomy of a test script

You should start the script with a bash shebang: remember, test.sh is a bash-only library.

Next comes the line that sources test.sh. The position doesn't really matter.

The remaining code is the test script itself, which is just normal bash code.

Each test is defined with the pair of tags `@test:` and `@body:`. The `@test:` tag is followed by a string with a
short description of the test. This string is what gets displayed in the main output and is also referenced by
test start/pass/fail logged events. The body of the test is defined with a `@body:` tag, which must me preceded
by a `@test:` tag. The body is normal shell code. You can define as much tests as you want. Each test defines a
bash function `test_n` where _n_ is the test number, starting at 1: the first test defines a function `test_1`,
the second test `test_2` and so on. This function is what you'll see in error stack traces.

Finally, you execute the tests with `@run_tests`. Tests are executed in the order of definition. Only tests
defined before `@run_tests` are executed. The `@test:` tag can be optionally preceded by a `@skip` tag;
such tests are not executed, they are reported as skipped.

All these tags are just bash commands; you can mix any bash code in between, for example to define functions
used by the tests. In fact, you don't need to define any tests, something you might do if interested only
in the error handling features of test.sh.

### setup/teardown

test.sh supports setup/teardown semantics with four more tags.
Each one of these tags is followed by a function body definition just as the `@body:` tag. At most one instance
of these tags should be present in a test script.

The following semantics apply to the setup & teardown functions:

* `@setup_fixture:`: If present, it will be called once before any test and `setup_test` functions. Failure in this
function will fail the test immediately, i.e. no tests will be executed.
A failure in this function is reported in the main output and the error is logged in the log output.
* `@teardown_fixture:`: if present, it will be called once after all tests and `teardown_test` functions. A failure
in this function will be reported as a warning in the main output and an error will be logged, but will not make
the test script to fail.
* `@setup:`: if present, it will be called before every test. A failure in this function will fail the
test but will not prevent other tests from executing (if FAIL_FAST is false). Because the test fails, the script
will fail also.
* `@teardown:`: if present, it will be called after every test. A failure in this function will be reported
as a warning in the main output and an error will be logged, but will not make the test to fail.

### Error handling

Error handling is where test.sh excels: errors are processed and reported in an exception-like fashion. Every command
that returns non-zero is considered an error, and as such throws an exception; these are _implicit exceptions_, as
if each command was followed by 'if command failed then throw exception'. Therefore, the test script is run in
the so-called "implicit assertion" mode. There are also normal, explicit exceptions: those that are thrown
with the `throw` function. Code can be wrapped in try/catch constructs, which is what test.sh does to run tests
and call teardown functions. Al this is implemented with a combination of shell options and ERR/EXIT traps.

The exact set of options set by test.sh are:

```shell script
set -o errexit -o pipefail -o errtrace
shopt -s inherit_errexit expand_aliases
```

These options are active right after sourcing test.sh. `expand_aliases` is not related to error handling; aliases
are used to implement the test definition and try/catch syntax.

Any uncaught exception in the body of a test interrupts the test and makes it fail. A failure of an individual test
will cause the script to return failure.
An uncaught exception in the main body of the test script terminates the script with failure.
For example:

```shell script
#!/bin/bash
VERBOSE=1 source ./test.sh
false
```

prints:

<pre><font color="#CC0000">[test.sh]</font> Error in main(myimpliciterror.sh:3): &apos;false&apos; exited with status 1
</pre>

and the exit code is 1.

#### Exceptions
test.sh uses internally a try/catch construct to implement test and teardown semantics.
This construct is also available to the test script. The syntax of the try/catch construct is:

```text
try:
  [commands...]
catch: | catch exception[, exception...]:
  commands...
[success:
  commands...]
endtry
```

* `try:`, `catch:`, `success:` and `endtry` must be at the beginning of a line.
* `try:`, `catch:`, and `endtry`  are all required, `success:` is optional.
* The body of the `catch:` and `success:` blocks must contain at least one command.
* The `catch:` clause can optionally specify a comma-separated list of exceptions. No spaces are allowed
before a comma, which must be followed by at least one space. The last exception must end with a colon.

For example:

```shell script
#!/bin/bash
VERBOSE=1 source ./test.sh

try:
  false
catch:
  print_exception
endtry
```

The try block is executed in a subshell: changes to variables in the try block are local to the subshell and are
not visible outside the try block. catch and success blocks are not executed in a subshell.
try/catch constructs can be nested.

Exceptions are thrown implicitly when the exit code of a command is non-zero, or explicitly with the
`throw <exception> <message>` function. \<exception\> is the exception type. Exceptions can inherit from
other exceptions. Inheritance is defined with function `declare_exception <exception> <super>`, where \<super\>
is the exception supertype of \<exception\>. Non-declared exceptions do not have a supertype. Only declared
exceptions can be specified in the list of caught exceptions in the catch clause. `catch:` catches all exceptions.
Exceptions listed in the catch clause are tried in order; each specified exception matches itself and all its subtypes.

The `throw` function in a catch block can be optionally preceded by `with_cause:` to chain the current exception
to the thrown exception with the link message 'Caused by:'. Pending exceptions are always linked to the thrown
exception with the link message 'Pending exception:'. Exceptions can be thrown from anywhere in the script: a try
block, a catch block, a success block or outside a try/catch construct.

These functions are only available in a catch block:
* `print_exception` prints the current exception: the exception message, a stack trace and all chained exceptions
* `rethrow` rethrows the current exception

The `failed` function returns 0 if an exception was caught in the catch block of the
last try/catch construct and false otherwise. Note that if an exception escapes the try block an is not caught
a call to `failed` after the try/catch construct will not get executed.

test.sh defines a hierarchy of exceptions. Some of them are abstract, i.e. they are never thrown as such but
are the supertype of concrete exceptions. The list of predefined exceptions is:
* nonzero: abstract. Represents a command failure.
* implicit (nonzero): concrete. Type of implicit exceptions when there are no pending exceptions.
* assert (nonzero): concrete. Thrown from assert functions when the assertion fails.
* error: abstract. Represents runtime errors.
* test_syntax (error): concrete. A misplaced `@body:` tag.
* pending_exception (error): concrete. Pending exceptions detected.
* eval_syntax_error (error): concrete. A syntax error in the command of `assert_success` or `assert_failure`.

#### Pending exceptions
test.sh relies on errexit to propagate thrown exceptions across subshell environments, but there are situations
when this propagation is interrupted. The exception remains, though, and test.sh checks at certain
points whether there are pending exceptions and throws 'pending_exception' exception. Pending exceptions
are created when thrown from a command substitution that is part of the arguments of another command or construct
that returns its own exit code. Multiple pending exceptions can accumulate until they are detected, as demonstrated
by this script:

```shell script
#!/bin/bash
VERBOSE=1 source ./test.sh
echo -n $(false) $(throw error Error!)
echo still here...
```

which prints:

<pre>still here...
<font color="#CC0000">[test.sh]</font> Pending exception, probably a masked error in a command substitution
<font color="#CC0000">[test.sh]</font>  at unhandled_exception(test.sh:275)
<font color="#CC0000">[test.sh]</font>  at exit_trap(test.sh:283)
<font color="#CC0000">[test.sh]</font>  at main(mypendingexception.sh:1)
<font color="#CC0000">[test.sh]</font> <font color="#CC0000">Pending exception:</font>
<font color="#CC0000">[test.sh]</font> Error!
<font color="#CC0000">[test.sh]</font>  at main(mypendingexception.sh:3)
<font color="#CC0000">[test.sh]</font> <font color="#CC0000">Pending exception:</font>
<font color="#CC0000">[test.sh]</font> Error in main(mypendingexception.sh:3): &apos;false&apos; exited with status 1
</pre>

This pending_exception was thrown from the EXIT trap, as shown by the stack trace. The other points where test.sh
checks for pending exceptions are:

* At the start of each assert function. This is intended to trap pending exceptions early when using command
substitutions in arguments to assert functions, such as `assert_equals "" "$(false)"`.
* At the end of each try block, before the catch block. Each test is executed in a try block, so pending exceptions
generated during a test will not pass the test undetected.

#### Repeated exceptions
The ERR trap that creates an implicit exception is inherited by subshells. Each nested subshell will create an
implicit exception, resulting in repeated exceptions for the same original exception thrown from an inner subshell.
For example, the command `(false)` creates two exceptions:

<pre><font color="#CC0000">[test.sh]</font> Error in main(doubleexception.sh:3): &apos;( false )&apos; exited with status 1
<font color="#CC0000">[test.sh]</font> <font color="#CC0000">Previous exception:</font>
<font color="#CC0000">[test.sh]</font> Error in main(doubleexception.sh:3): &apos;false&apos; exited with status 1
</pre>

There's no way to distinguish a pending exception from a current exception at implicit exception creation, so
an existing exception is chained to the current exception with the ambiguous link message "Previous exception:".

Subshells introduced by try blocks do not repeat exceptions even when nested.

The type of an implicit exception is the type of the pending exception or `implicit` if there are no pending exceptions.

#### Ignored errexit context

There are some pitfalls with `-o errexit` to be aware of. Bash ignores this setting in the following situations:

* In the condition of an `if`, `while` or `until`.
* Commands separated by `||` or `&&` except the last command. The final result of the expression will do trigger
exit of non-zero.
* In negated commands, i.e. preceded by '!'.

In all of the above situations the commands are executed in _ignored errexit context_; if the command is a function,
the exit code of commands in the function body is ignored and the exit code of the function is the exit code of the
las command evaluated in the function body. This means that if you have a validation function
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

The ERR trap shares with errexit the conditions under which it is ignored, i.e. ignored errexit context is also
ignored ERR trap context. No implicit exceptions are thrown in ignored ERR trap context.

### Assertions

There are three assert
functions: `assert_success`, `assert_failure` and `assert_equals`. See the description of these functions in the
[Function reference](#function-reference).

`assert_success` and `assert_failure` accept an expression which is evaluated with `eval` in errexit context, i.e.
implicit exceptions are thrown as usual. There are quoting issues to be aware of:

* If the expression is surrounded by double quotes, parameter expansion will occur at call point. If single quotes
are used, then parameter expansion will occur at the evaluation point.
* Double quotes inside the expression have to be escaped if the expression is surrounded by double quotes.

If the evaluated expression contains syntax errors, an `eval_syntax_error` exception is thrown; this
exception is not considered for the assertion result and the assertion neither succeeds nor fails because the
expression could not be evaluated. It is considered a runtime error.

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

The configuration is read before any configuration variable takes effect. This means that
errors during configuration processing are displayed in the main output because the redirection
to LOG_FILE has not been done yet.
For the same reason, no color is applied: the COLOR configuration has not been yet processed.

Temporary files are created in TMPDIR if set, otherwise in `/tmp`.

* VERBOSE

  Boolean. Default false.

  If true, then the standard output and error are displayed in the main output in addition to
  being saved to the log file.

* DEBUG

  Boolean. Default false.

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

  * overwrite: clear the contents of the log file.
  * append: append the test script log to the existing content.

### Function reference

This is the list of functions and aliases defined by test.sh that you can use in a test script.

* @run_tests

  Syntax:

  ```text
  @run_tests
  ```

  Alias for function `run_tests`.
  Runs all tests. You should call `run_tests` only once. Alias for function `run_tests`.

* _eval

  Syntax:

  ```text
  _eval [arguments]...
  ```

  Wrapper for the `eval` builtin. Throws `eval_syntax_error` exception.

  The `eval` builtin behaviour when the evaluated command contains syntax errors is to exit with exit code 2. No ERR
  trap is triggered in the shell environment where `eval` is executed; if this is the main shell environment, no
  exception is generated. The `_eval` function does throw `eval_syntax_error` in this event and is a better fit
  for test.sh error handling.

* @setup_fixture:

  Syntax:

  ```text
  @setup_fixture: {
    command...
  }
  ```

  Alias that defines the function `setup_test_suite`.
  If defined, this function will be called only once before any test.
  A failure in this function will cause failure of the script and no test will be executed.

  See [setup/teardown](#setupteardown).

* @teardown_fixture:

  Syntax:

  ```text
  @teardown_fixture: {
    command...
  }
  ```

  Alias that defines the function `teardown_test_suite`.
  If defined, this function will be called once after all tests even if there are failures.
  A failure in this function will not cause failure of the script, but will cause a warning
  message to be displayed on the main output.

  See [setup/teardown](#setupteardown).

* @setup:

  Syntax:

  ```text
  @setup: {
    command...
  }
  ```

  Alias that defines the function `setup_test`.
  If defined, this function will be called before each test.
  A failure in this function will cause failure of the test.

  See [setup/teardown](#setupteardown).

* @teardown:

  Syntax:

  ```text
  @teardown: {
    command...
  }
  ```

  Alias that defines the function `teardown_test`.
  If defined, this function will be called after each test even if the test fails.
  A failure in this function will not cause failure of the test, but will cause a warning
  message to be displayed on the main output.

  See [setup/teardown](#setupteardown).

* assert_success

  Syntax:

  ```text
  assert_success <command> [message]
  ```

  Evaluates \<command\>. Throws exception `assert` if the exit code is not success.

  For example, the following test script:

  ```shell script
  #!/bin/bash
  VERBOSE=1 source ./test.sh
  assert_success false "this is a test killer"
  ```

  prints:

  <pre><font color="#CC0000">[test.sh]</font> Assertion failed: this is a test killer, expected success but got failure in: &apos;false&apos;
  <font color="#CC0000">[test.sh]</font>  at throw_assert(test.sh:475)
  <font color="#CC0000">[test.sh]</font>  at assert_success(test.sh:486)
  <font color="#CC0000">[test.sh]</font>  at main(assert_success.sh:3)
  <font color="#CC0000">[test.sh]</font> Caused by:
  <font color="#CC0000">[test.sh]</font> Error in _eval(test.sh:268): &apos;false&apos; exited with status 1
  <font color="#CC0000">[test.sh]</font>  at assert_success(test.sh:483)
  <font color="#CC0000">[test.sh]</font>  at main(assert_success.sh:3)
  </pre>

* assert_failure

  Syntax:

  ```text
  assert_failure <command> [message]
  ```

  Evaluates \<command\>. Exceptions thrown from command are logged with level info for reference. Throws
  exception `assert` if the exit code is 0.
  For example, the following test script:

  ```shell script
  #!/bin/bash
  VERBOSE=1 source ./test.sh
  assert_failure true "this is a test killer"
  ```

  prints:

  <pre><font color="#CC0000">[test.sh]</font> Assertion failed: this is a test killer, expected failure but got success in: &apos;true&apos;
  <font color="#CC0000">[test.sh]</font>  at throw_assert(test.sh:475)
  <font color="#CC0000">[test.sh]</font>  at assert_failure(test.sh:501)
  <font color="#CC0000">[test.sh]</font>  at main(assert_failure.sh:3)
  </pre>

* assert_equals

  Syntax:

  ```text
  assert_equals <expected> <current> [message]
  ```

  Compares \<expected\> and \<current\> with the bash expression: `[[ "$expected" = "$current" ]]`.
  Throws exception `assert` if the result is non-zero. The exception message follows the pattern
  `Assertion failed: [<message>, ]expected '<expected>' but got '<current>'`.

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
