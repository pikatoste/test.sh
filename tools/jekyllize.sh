# Adapt html stdin to jekyll theme
ORIG="$1"
awk 'BEGIN {print "---"; print "default"; print "---";} {print}' <"$ORIG" >"${1}".tmp
rm "$ORIG"
mv "${1}".tmp "$ORIG"
