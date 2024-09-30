#!/bin/bash

source stack-setup-env.sh

export DEV_SPACK_HOME=/orcd/software/community/001/spack/stage/$USER/$(date +"%Y%m%d")/
cp stack-setup-env.sh dev_stack-setup-env.sh
sed -i s+$SPACK_HOME+$DEV_SPACK_HOME+ dev_stack-setup-env.sh
if [ -L "$SPACK_INSTALL" ]; then
  ln -s $SPACK_INSTALL $DEV_SPACK_HOME/spack
else
  bash dev_install_new_spack.sh
fi

source dev_stack-setup-env.sh

cp -r base_stack $DEV_SPACK_HOME
cp -r core_stack $DEV_SPACK_HOME
cp -r community_stack $DEV_SPACK_HOME

spack env activate $DEV_SPACK_HOME/base_stack
spack config add config:install_tree:root:$DEV_SPACK_HOME/core/pkg
spack config add upstreams:core_stack:install_tree:/orcd/software/core/001/spack/pkg
spack env deactivate

spack env activate $DEV_SPACK_HOME/core_stack
spack config add config:install_tree:root:$DEV_SPACK_HOME/core/pkg
spack config add modules:default:roots:lmod:$DEV_SPACK_HOME/core/modulefiles
spack config add upstreams:core_stack:install_tree:/orcd/software/core/001/spack/pkg
spack env deactivate

spack env activate $DEV_SPACK_HOME/community_stack
spack config add config:install_tree:root:$DEV_SPACK_HOME/community/pkg
spack config add modules:default:roots:lmod:$DEV_SPACK_HOME/community/modulefiles
spack config add upstreams:core_stack:install_tree:/orcd/software/community/001/spack/pkg
