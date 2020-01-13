# Adapt html stdin to jekyll theme
ORIG="$1"
awk '{if (FNR == 1 && $0 != "---") {print "---"; print "layout: default"; print "---";} print}' <"$ORIG" >"${1}".tmp
rm "$ORIG"
mv "${1}".tmp "$ORIG"
