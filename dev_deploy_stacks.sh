#!/bin/bash

#SBATCH -c 32 # cores available for building
#SBATCH -p mit_normal # use a partition that matches the target OS

# This script updates all stacks to reflect changes from the spack.yaml files

source dev_stack-setup-env.sh

# Base environment has only compilers installed, has same install_tree root as core_stack_env
spack env activate base_stack
if [ spack config get config | grep -q "root: $SPACK_HOME" ]; then
    spack install
    GCC_LOC=$(spack location -i gcc)
    spack env deactivate

    # Core software environment has compilers + core software stack
    spack env activate core_stack
    spack compiler find $GCC_LOC # add compilers installed from base_stack_env
    spack install # install the rest of the core software
    spack env deactivate

    # Community stack has install root for base+core as upstream
    spack env activate community_stack
    spack compiler find $GCC_LOC
    spack install
else
    echo "Not a dev install root, skipping deployment. Run \"make_dev_stack.sh\" to convert to a development environment."
fi
spack env deactivate