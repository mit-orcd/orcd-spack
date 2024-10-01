#!/bin/bash

# Updates to production stack environment files. Run "deploy_stacks.sh" to
# deploy new production stack environment files and install any changes.

source stack-setup-env.sh

spack env activate base_stack
spack config add config:install_tree:root:$SPACK_HOME/core/pkg
spack config remove upstreams:core_stack:install_tree
spack env deactivate

spack env activate core_stack
spack config add config:install_tree:root:$SPACK_HOME/core/pkg
spack config add modules:default:roots:lmod:$SPACK_HOME/core/modulefiles
spack config add upstreams:core_stack:install_tree:/orcd/software/core/001/spack/pkg
spack env deactivate

spack env activate $SPACK_HOME/community_stack
spack config add config:install_tree:root:$SPACK_HOME/community/pkg
spack config add modules:default:roots:lmod:$SPACK_HOME/community/modulefiles
spack config add upstreams:core_stack:install_tree:/orcd/software/community/001/spack/pkg
