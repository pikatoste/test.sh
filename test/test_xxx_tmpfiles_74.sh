#!/bin/bash
FILES=$({ find ${TMPDIR:-/tmp} -name tsh-\* 2>/dev/null || true; } | { wc -l || true; })
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "#74: Ensure temporary files are cleaned after running all tests"
set +e pipefail
assert_equals 0 "$FILES" "Temporary files remain"
