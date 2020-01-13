# Create / update gh-pages release docs
/tmp/tools/jekyllize.sh releases/$TAG/buildinfo/coverage/index.html
[ "$TAG" = latest ] && sed -i -e "s/^unstable_version:.*$/unstable_version: $VERSION/" _config.yml
[ "$TAG" != latest ] && sed -i -e "s/^stable_version:.*$/stable_version: $VERSION/" _config.yml
(cd releases/$TAG/buildinfo && /tmp/tools/generate-buildinfo-pages.sh ../../../build/testout/.main ../../../build/testout $VERSION)
cp /tmp/README.md releases/$TAG/doc/index.md
/tmp/tools/jekyllize-README.sh releases/$TAG/doc/index.md
cat releases/release-index.md.template | sed -e "s/^version:.*/version: $VERSION/" -e "s/^tag:.*/tag: $TAG/" >releases/$TAG/index.md
