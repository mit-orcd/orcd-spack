#!/bin/bash

#SBATCH -c 32 # cores available for building
#SBATCH -p mit_normal # use a partition that matches the target OS

# This script does a full install from scratch, including installing a new spack

source dev_stack-setup-env.sh

# Use a newer version of spack, date the install
git clone --depth=100 --branch=releases/$SPACK_VERSION https://github.com/spack/spack.git $SPACK_HOME/spack_$(date +"%Y%m")

if [ -L "$SPACK_INSTALL" ]; then
  unlink $SPACK_INSTALL
fi
ln -s $SPACK_HOME/spack_$(date +"%Y%m") $SPACK_INSTALL