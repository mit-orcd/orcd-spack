#!/bin/bash

# Source this file to set environment variables for stacks

export SPACK_VERSION=v0.22

export SPACK_HOME=/orcd/software/community/001/spack/stage/lauren/20240927/
export SPACK_INSTALL=$DEV_STACK_BASE/spack

export SPACK_DISABLE_LOCAL_CONFIG=true

if [ -d "$SPACK_INSTALL" ]; then
  source $SPACK_INSTALL/share/spack/setup-env.sh
fi