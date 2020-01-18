#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "When executed, test.sh should output the version and github project"
OUT=$TEST_SCRIPT_DIR/.test_script.out
"$(dirname "$(readlink -f "$0")")"/../test.sh >"$OUT"
diff - "$OUT" <<EOF
This is test.sh version $VERSION
See https://github.com/pikatoste/test.sh
EOF
rm -f "$OUT"
