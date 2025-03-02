#!/bin/bash

git fetch --all && \
git reset --hard origin/main && \
git clean -fd && \
git submodule update --init --recursive --force && \
git submodule foreach --recursive 'git fetch --all && git reset --hard origin/main'
