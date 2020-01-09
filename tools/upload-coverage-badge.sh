COVERAGE_BADGE="${1:-/tmp/coverage.svg}"
git config user.email "ci@nowhere.org"
git config user.name "ci"
git checkout --orphan assets || git checkout assets
make clean
git reset --hard
cp "$COVERAGE_BADGE" .
git add .
git commit -m 'Update coverage badge'
git push -u origin assets --force
