#!/bin/bash

#SBATCH -c 32 # cores available for building
#SBATCH -p mit_normal # use a partition that matches the target OS

# This script updates all stacks to reflect changes from the spack.yaml files

source stack-setup-env.sh

spack env activate core_stack
if spack config get config | grep -q "root: /orcd/software/core/001/spack/pkg"; then
    spack env deactivate

    cp -r core_stack $SPACK_HOME
    cp -r community_stack $SPACK_HOME

    spack env activate $SPACK_HOME/core_stack
    spack install
    spack module lmod refresh -y
    spack env deactivate

    spack env activate $SPACK_HOME/community_stack
    spack install
    spack module lmod refresh -y
else
    echo "Not a production install root, skipping deployment. Run \"update_prod_stack.sh\" to convert to a production environment."
fi
spack env deactivate
