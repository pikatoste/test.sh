# Adapt html stdin to jekyll theme
ORIG=$1
VERSION=$2
awk '{if (FNR == 1 && $0 != "---") {print "---"; print "layout: release"; print "version: '$VERSION'"; print "---";} print}' <"$ORIG" >"${1}".tmp
rm "$ORIG"
mv "${1}".tmp "$ORIG"
