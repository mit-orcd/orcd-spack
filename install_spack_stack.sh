#!/bin/bash
 
#SBATCH -c 32 # cores available for building
#SBATCH -p mit_normal # use a partition that matches the target OS
 
SPACK_HOME=$(pwd)

# Use a newer version of spack, date the install
git clone --depth=100 --branch=releases/v0.22 https://github.com/spack/spack.git ./spack_$(date +"%Y%m")
SPACK_INSTALL=$SPACK_HOME/spack_$(date +"%Y%m")
 
source $SPACK_INSTALL/share/spack/setup-env.sh
export SPACK_DISABLE_LOCAL_CONFIG=true
 
pack env activate ./base_stack_env # Base environment has only compilers installed, has same install_tree root as core_stack_env
 
spack install # install the compilers
 
GCC_LOC=$(spack location -i gcc)
 
spack env deactivate
 
spack env activate ./core_stack_env # Core software environment has compilers + core software stack
 
spack compiler find $GCC_LOC # add compilers installed from base_stack_env
 
spack install # install the rest of the core software
 
spack module lmod refresh --delete-tree -y
 
spack env deactivate
 
spack env activate ./community_stack_env # Community stack has install root for base+core as upstream
 
spack compiler find $GCC_LOC
 
spack install
 
spack module lmod refresh --delete-tree -y