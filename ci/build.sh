#!/bin/bash

# Build base image first
docker build -f ci/Dockerfile.base -t buddycompiler-base:v1.0 .

# Build variant images
docker build -f ci/Dockerfile.default -t buddycompiler-default:v1.0 .
docker build -f ci/Dockerfile.lld -t buddycompiler-lld:v1.0 .
docker build -f ci/Dockerfile.python-bindings -t buddycompiler-python-bindings:v1.0 .

# Build CUDA image separately as it has a different base
docker build -f ci/Dockerfile.cuda -t buddycompiler-cuda:v1.0 .