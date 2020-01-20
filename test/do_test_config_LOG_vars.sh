#!/bin/bash

eval $1
source "$(dirname "$(readlink -f "$0")")"/../test.sh

echo "lorem ipsum"
