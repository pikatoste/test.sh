cat VERSION | \
  sed -e "s/SNAPSHOT$/SNAPSHOT-$(git rev-parse --short HEAD)$(git diff-index --quiet HEAD -- || echo -n -dirty)/"
