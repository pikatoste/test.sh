COVERAGE=$(sed -n '/<tbody>/,/<\/tbody>/p;/<\/tbody>/q' runtest/coverage/index.html | xsltproc tools/coverage.xsl -)
COVERAGE_COLOR=$(echo "$COVERAGE" | awk '{if ($1 <= 80) print "red"; else if ($1 < 90) print "yellow"; else print "brightgreen"}')
COVERAGE_URLENC=$(echo -n "$COVERAGE" | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')
curl -X GET "https://img.shields.io/badge/coverage-${COVERAGE_URLENC}-${COVERAGE_COLOR}"
