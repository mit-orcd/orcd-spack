#!/bin/bash

# Source this file to set environment variables for stacks

export SPACK_VERSION=v0.22

export SPACK_HOME=/orcd/software/core/001/spack
export SPACK_INSTALL=$SPACK_HOME/spack

export SPACK_DISABLE_LOCAL_CONFIG=true

if [ -d "$SPACK_INSTALL" ]; then
  source $SPACK_INSTALL/share/spack/setup-env.sh
fi