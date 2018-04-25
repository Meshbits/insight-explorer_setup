#!/usr/bin/env bash

git reset --hard
git pull
../bin/setup.sh --dont-build --ac-start 001 --ac-end 100
