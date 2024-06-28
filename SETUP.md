# Spack Setup Notes

Set Spack location containing spack install:

```
SPACK_HOME=$HOME/software_stack/spack/
```

Copy the config.yaml file. This file sets the software install locations, unfortunately there is one per spack so that means separate spack installs? Let's try with a single spack install and separate configs for now.

```
cp /orcd/software/community/001/spack/orcd-spack/*.yaml $SPACK_HOME/community_configs/
cp /orcd/software/community/001/spack/orcd-spack/*.yaml $SPACK_HOME/core_configs/
```

Edit the config.yaml files, they should each be:

config:
  install_tree:
    root: /orcd/home/001/milechin/software_stack/[community/core]/install/spack
  install_path_scheme: '{name}/{version}/{hash:7}'

Keep compilers.yaml the same for now, we may want a "fresh" gcc so we aren't dependent on the old Spack

modules.yaml:

Set root for lmod to $SPACK_HOME/modulefiles/core/
Will need to add modules as needed

upstreams.yaml:

delete the "core" upstream.yaml
set community upstream.yaml:

upstreams:
  core-202405:
   install_tree: /orcd/home/001/milechin/software_stack/core/install/spack


We will want spaces and configs for testing as well. This way we can try out a spack install and make sure it works without adding a whole bunch of stuff we may not need to the install.