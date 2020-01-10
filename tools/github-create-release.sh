TAG=$1
VERSION=$2
TOKEN=$3

onerr() {
  local err=$?
  echo "Error in ${BASH_SOURCE[1]}:${BASH_LINENO[0]}. '${BASH_COMMAND}' exited with status $err"
}
set -e errexit
set -e pipefail
set -e errtrace

trap onerr ERR

RELEASE_ID=$(curl -sS https://api.github.com/repos/pikatoste/test.sh/releases/tags/$TAG | jq -r '.id | select (.!=null)')
if [ "$TAG" = latest ]; then
  RELEASE_NAME="Development Build $VERSION"
  RELEASE_BODY="This is a development build.\nTest output: https://pikatoste.github.io/test.sh/buildinfo/$TAG/testmain.html\nCoverage report: https://pikatoste.github.io/test.sh/buildinfo/$TAG/coverage/"
  RELEASE_PRERELEASE=true
else
  RELEASE_NAME="Version $VERSION"
  RELEASE_BODY="This is a stable release.\nTest output: https://pikatoste.github.io/test.sh/buildinfo/$TAG/testmain.html\nCoverage report: https://pikatoste.github.io/test.sh/buildinfo/$TAG/coverage/"
  RELEASE_PRERELEASE=false
fi
RELEASE_BODY=$(cat <<EOF
{
  "tag_name": "$TAG",
  "target_commitish": "",
  "name": "$RELEASE_NAME",
  "body": "$RELEASE_BODY",
  "draft": false,
  "prerelease": $RELEASE_PRERELEASE
}
EOF
)
if [ "$RELEASE_ID" ]; then
  curl -sSfo /dev/null -H "Content-Type: application/json" -H "Authorization: token $TOKEN" -X PATCH https://api.github.com/repos/pikatoste/test.sh/releases/$RELEASE_ID -d "$RELEASE_BODY"
else
  curl -sSfo /dev/null -H "Content-Type: application/json" -H "Authorization: token $TOKEN" -X POST https://api.github.com/repos/pikatoste/test.sh/releases -d "$RELEASE_BODY"
fi
RESPONSE=$(curl -sSf https://api.github.com/repos/pikatoste/test.sh/releases/tags/$TAG)
RELEASE_ID=$(echo "$RESPONSE" | jq -r .id)
UPLOAD_URL=$(echo "$RESPONSE" | jq -r .upload_url | sed -e 's/{.*}//')

ASSET_ID=$(curl -sS https://api.github.com/repos/pikatoste/test.sh/releases/22729687/assets | jq -r '.[] | select(.name = "test.sh").id | select (.!=null)')
if [ "$ASSET_ID" ]; then
  curl -sSf -H "Authorization: token $TOKEN" -X DELETE https://api.github.com/repos/pikatoste/test.sh/releases/assets/$ASSET_ID
fi
curl -sSfo /dev/null -X POST --data-binary @build/test.sh -H "Authorization: token $TOKEN" -H "Content-Type: text/x-shellscript" "${UPLOAD_URL}?name=test.sh"
