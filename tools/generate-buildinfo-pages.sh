MAIN_OUT="$1"
TESTOUT_DIR="$2"
VERSION=$3

TOOLS_DIR=$(dirname "$(readlink -f "$0")")

ansi2html() {
  "$TOOLS_DIR"/ansi2html.sh
}

cat >testmain.md <<EOF
---
layout: release
version: $VERSION
---
# Main test output

EOF

ansi2html <"$MAIN_OUT" >>testmain.md

cat >>testmain.md <<EOF

# Detailed logs

EOF

for testlog in "$TESTOUT_DIR"/*; do
  testname=$(basename -s .out "$testlog")
  testlogmd="$testname".md
  echo --- >"$testlogmd"
  echo "layout: release" >>"$testlogmd"
  echo "version: $VERSION" >>"$testlogmd"
  echo --- >>"$testlogmd"
  echo "# Output of $testname" >>"$testlogmd"
  echo >>"$testlogmd"
  ansi2html <"$testlog" >>"$testlogmd"
  echo "* [$testname]($testname.html)" >>testmain.md
done
