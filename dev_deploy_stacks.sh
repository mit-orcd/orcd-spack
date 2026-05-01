#!/bin/bash

#SBATCH -c 32 # cores available for building
#SBATCH -p mit_normal # use a partition that matches the target OS

# This script updates all stacks to reflect changes from the spack.yaml files

source dev_stack-setup-env.sh

spack env activate core_stack
if spack config get config | grep -q "root: $SPACK_HOME"; then
    spack install
    spack env deactivate

    # Community stack has install root for core as upstream
    spack env activate community_stack
    spack install
else
    echo "Not a dev install root, skipping deployment. Run \"make_dev_stack.sh\" to convert to a development environment."
fi
spack env deactivate
