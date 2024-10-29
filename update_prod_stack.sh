#!/bin/bash

# Updates to production stack environment files. Run "deploy_stacks.sh" to
# deploy new production stack environment files and install any changes.

source stack-setup-env.sh

spack env activate base_stack
spack config add config:install_tree:root:/orcd/software/core/001/spack/pkg
spack config remove upstreams:core_stack
spack env deactivate

spack env activate core_stack
spack config add config:install_tree:root:/orcd/software/core/001/spack/pkg
spack config add modules:default:roots:lmod:/orcd/software/core/001/spack/modulefiles
spack config remove upstreams:core_stack
spack env deactivate

spack env activate community_stack
spack config add config:install_tree:root:/orcd/software/community/001/spack/pkg/
spack config add modules:default:roots:lmod:/orcd/software/community/001/spack/modulefiles
spack config remove upstreams:community_stack
