#!/bin/bash

git fetch --all && \
git reset --hard origin/msys2 && \
git clean -fd && \
git submodule update --init --recursive --force && \
git submodule foreach --recursive 'git fetch --all && git reset --hard origin/msys2'
