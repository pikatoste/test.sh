TEST_SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
LOG_DIR="$TEST_SCRIPT_DIR"/testout
for bash_version in 4.4.12 4.4.18 4.4 5.0 devel; do
  bash_version_str=$(docker run bash:$bash_version bash --version | head -1)
  echo "Testing bash:$bash_version ($bash_version_str)"
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR"/bash-$bash_version.log
  echo "Testing bash:$bash_version ($bash_version_str)" >"$LOG_FILE"
  docker run -v ~/bbva/test.sh/main:/mnt/test.sh  bash:$bash_version bash -c 'set -e; ln -s /usr/local/bin/bash /bin/bash; cd /mnt/test.sh; find runtest -type f -name test_\*.sh | while read test; do "$test"; done' >/dev/null >>"$LOG_FILE"
  if [[ $? = 0 ]]; then
    echo "SUPPORTED: bash:$bash_version ($bash_version_str)"
  else
    echo "NOT SUPPORTED: bash:$bash_version ($bash_version_str)"
  fi
done
