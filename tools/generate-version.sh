cat VERSION | sed -e "s/SNAPSHOT$/SNAPSHOT-$(git rev-parse HEAD)$(git diff-index --quiet HEAD -- || echo -n -dirty)/"
