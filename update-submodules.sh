#!/bin/bash

git submodule update --init --recursive
git submodule foreach 'git checkout main'
