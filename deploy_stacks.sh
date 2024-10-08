#!/bin/bash

#SBATCH -c 32 # cores available for building
#SBATCH -p mit_normal # use a partition that matches the target OS

# This script updates all stacks to reflect changes from the spack.yaml files

source stack-setup-env.sh

spack env activate base_stack
if spack config get config | grep -q "root: $SPACK_HOME"; then
    spack env deactivate

    cp -r base_stack $SPACK_HOME
    cp -r core_stack $SPACK_HOME
    cp -r community_stack $SPACK_HOME

    # Base environment has only compilers installed, has same install_tree root as core_stack_env
    spack env activate $SPACK_HOME/base_stack
    spack install
    GCC_LOC=$(spack location -i gcc)
    spack env deactivate

    # Core software environment has compilers + core software stack
    spack env activate $SPACK_HOME/core_stack
    spack compiler find $GCC_LOC # add compilers installed from base_stack_env
    spack install # install the rest of the core software
    spack module lmod -y refresh
    spack env deactivate

    # Community stack has install root for base+core as upstream
    spack env activate $SPACK_HOME/community_stack
    spack compiler find $GCC_LOC
    spack install
    spack module lmod -y refresh
else
    echo "Not a production install root, skipping deployment. Run \"update_prod_stack.sh\" to convert to a production environment."
fi
spack env deactivate
