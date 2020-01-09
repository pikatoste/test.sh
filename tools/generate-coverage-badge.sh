if [ -f runtest/coverage/index.html ]; then
  COVERAGE_LABEL=$(sed -n '/<tbody>/,/<\/tbody>/p;/<\/tbody>/q' runtest/coverage/index.html | xsltproc tools/coverage.xsl -)
  COVERAGE_COLOR=$(echo "$COVERAGE_LABEL" | awk '{if ($1 <= 80) print "red"; else if ($1 < 90) print "yellow"; else print "brightgreen"}')
else
  COVERAGE_LABEL="no report"
  COVERAGE_COLOR="lightgrey"
fi

url_encode() {
  local what="$1"
  echo -n "$what" | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g'
}

curl -s -X GET "https://img.shields.io/badge/coverage-$(url_encode "$COVERAGE_LABEL")-${COVERAGE_COLOR}"
