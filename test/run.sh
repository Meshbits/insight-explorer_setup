#!/usr/bin/env bash

git reset --hard
git pull
$(dirname $0)/../bin/setup.sh --dont-build
