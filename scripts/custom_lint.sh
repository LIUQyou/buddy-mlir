#!/bin/bash

# Example: Check for TODO comments
if grep -rnw 'TODO' $@; then
  echo "Please address all TODO comments before committing."
  exit 1
fi
