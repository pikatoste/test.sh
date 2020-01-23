#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "#74: Ensure temporary files are cleaned after running all tests"
set +e pipefail
FILES=$({ find ${TMPDIR:-/tmp} -name tsh-\* 2>/dev/null || true; } | { grep -v "$TSH_TMPDIR" || true; } | { wc -l || true; })
assert_equals 0 "$FILES" "Temporary files remain"
