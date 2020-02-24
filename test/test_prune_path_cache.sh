#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "#93: prune_path should put in the cache missing paths"
_PRUNE_PATH_CACHE=()
PRUNEFILE="$TEST_SCRIPT_DIR"/pepe
touch "$PRUNEFILE"
PRUNE_PATH= prune_path "$PRUNEFILE"
assert_equals "$PRUNEFILE" "${_PRUNE_PATH_CACHE[$PRUNEFILE]}"

start_test "#93: prune_path should retrieve cached paths from the cache"
realpath() {
  unset realpath
  fail "realpath called, should have hit the cache"
}
PRUNE_PATH="*/" prune_path "$PRUNEFILE"
unset realpath
assert_equals "$PRUNEFILE" "${_PRUNE_PATH_CACHE[$PRUNEFILE]}"

start_test "#93: init_prune_path_cache reprocesses the preinitialized cache in subtests"
_PRUNE_PATH_CACHE=([/hola/pepe]=/hola/pepe)
_SUBTEST= PRUNE_PATH="*/" INITIALIZE_SOURCE_CACHE= init_prune_path_cache
assert_equals pepe "${_PRUNE_PATH_CACHE[/hola/pepe]}"
