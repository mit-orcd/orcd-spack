
# orcd-spack

First, refer to [this page](https://mit-orcd.github.io/orcd-docs-previews/PR/PR29/recipes/spack-basics/) to set up Spack to inherit the TSQ configuration on a Rocky8 systems.

Every RCF member creates a Spack work directory `$spack_work` under the home directory. The Spack progream is cloned from github and put under `$spack_work`.

Log in a Rocky 8 head node, such as `eofe10.mit.edu`. Set up Spack environment every time after login.
```
cd $spack_work
source spack/share/spack/setup-env.sh
export SPACK_USER_CONFIG_PATH=`pwd`/user_config
```

The congifure files include `config.yaml`, `compilers.yaml`, `modules.yaml`, `packages.yaml`, and `upstreams.yaml`. Put them in the directoty `$spack_work/use_config`. The variables set in the configure files will overright the default ones. 

> Especally for `config.yaml`, it also works to put it in `$spack_work/spack/etc/spack`.


## Connfigure yaml files

Here are notes of the modifications on the configure files.

***config.yaml:***
* Set the install root path as `orcd/software/community/001/rocky8`. Installation files will be automacitally created in there. 
* Set install path scheme.

***compilers.yaml:***
* Add compling flags `-O3 -fPIC`, which are important to optimize the performance.
* When installing a new compiler, add it in this yaml file.

***modules.yaml:***
* Set the module root path as `/orcd/software/community/001/spack/modulefiles`. Module files will be automacitally created in there. 
* Add the package name under the section `include` to let spack create module files for it. Use alphabetical order.
* If needed, add environment variables under the name of a package, so that Spack will set them in a module file. It is not recommended to set `LD_LIBRARY_PATH` here.

***packages.yaml:***
* Set the group `orcd_rg_engagingsw_orcd-sw` in the permsssion section.

***upstreams.yaml:***
* Set the isntall tree to inherit the pakcages built by TSQ.
  

## Set LD_LIBRARY_PATH in a module file

Execute these commands,
```
spack config add modules:prefix_inspections:lib64:[LD_LIBRARY_PATH]
spack config add modules:prefix_inspections:lib:[LD_LIBRARY_PATH]
```
then the following lines will be added to the `modules.yaml` file,
```
  prefix_inspections:
    lib64: [LD_LIBRARY_PATH]
    lib:
    - LD_LIBRARY_PATH
```
Then the `LD_LIBRARY_PATH` will be set in the module file.


##  Installation

Use the `gcc 12.2.0` compiler built by TSQ by default unless another version of compiler is needed. 

Here are exmaples to install packages,
```
spack install openmpi@4.1.4%gcc@12.2.0
spack install gromacs@2021.6%gcc@12.2.0 ^openmpi@4.1.4
```

Installation files of the package and its dependencies will be automacitally created in install root directory. All dependencies will be shared by future installtion of packages. 

After the installation is seccessful, lua module files are created under the module root path. There are complicated Spack-created tree paths within it, so it is not suitable to be exposed to users. To publish a package to users, make subdirectories with package names and soft links named `$version.lua` under `/orcd/software/community/001/modulefiles/rocky8` to point to the module files. 

The build stage files are removed automatically by default. Keep them using `--keep-stage` if needed, for example,
```
spack install --keep-stage openmpi@4.1.4%gcc@12.2.0
```

> Keeping build stage files may affect future installation unexpectedly, so it is not recommended unless very necessary. 

When a building process fails, sometimes it is necessary to clean cache, which unsets environment variables,
```
spack clean -m
```
and then rebuild it.



