
# orcd-spack
This repository contains ORCD Spack configurations and how to use Spack to install new software for core and community software stacks. We will follow these recipes on the Rocky 8 nodes moving forward.

This repository contains two directories of Spack config files:
- core_configs
- community_configs

Each of these define different scopes for installing software, including where the software and modules should be installed. Spack scopes can be specified with each Spack command with the `-C` (`--config-scope`) flag. See the section on usage for more information.

The `SETUP.md` file describes how new a new version of spack can be installed. This may also require reinstalling all packages.

## Basic Usage

To start using spack to install to the ORCD software stack run the following to set the locations of the Spack install and config files, then activate spack and disable any local config files you have.

```
SPACK_HOME=/orcd/software/community/001/spack/
SPACK_INSTALL=$SPACK_HOME/spack_v0.22

CORE_CONFIGS=$SPACK_HOME/core_configs
COMMUNITY_CONFIGS=$SPACK_HOME/community_configs

source $SPACK_INSTALL/share/spack/setup-env.sh
export SPACK_DISABLE_LOCAL_CONFIG=true
```

### Listing Packages

To see the packages installed for core, you can run:

```
spack -C $CORE_CONFIGS find -x
```

For community:

```
spack -C $COMMUNITY_CONFIGS find -x
```

### Installing Software

To see if a software is available through spack run:

```
spack list [software]
```

Sometimes the name will be slightly different than you expect. Once you have the name spack uses you can use the `spack info` command to see the full information for that software, includign what versions are available, what it depends on, and which options are available for that software during build.

```
spack info [package]
```

To view the full concretized (showing all the dependencies it will install) spec of a package you would like to install, for example for community, run:

```
spack -C $COMMUNITY_CONFIGS spec -I -L [package spec]
```

For example:

```
spack -C $CORE_CONFIGS spec -I -L openmpi@4.1.4%gcc@12.2.0
spack -C $COMMUNITY_CONFIGS spec  -I -L gromacs@2021.6%gcc@12.2.0 ^openmpi@4.1.4
```

Then when you want to install the package run:

```
spack -C $COMMUNITY_CONFIGS install [package spec]
```

Installation files of the package and its dependencies will be automatically created in install root directory. All dependencies will be shared by future installation of packages.

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


### Creating Modules

After the installation is successful, lua module files are created under the module root path.

Sometimes a module isn't created during the build or you'd like to regenerate them. You can run the command:

```
spack -C core_configs/ module lmod refresh [package]
```

to recreate a specific package, or

```
spack -C core_configs/ module lmod refresh
```

to recreate all missing modules.

As described in the [Configuration Files](#configuration-files) section below, modules for all link and run dependencies will also be created, but set to be hidden.

The modules are created with complicated tree paths within it, so it is not suitable to be exposed to users. We also want to display all modules in one place, rather than show spack modules separately. To publish a package to users, copy all of the software level directories into the user facing modulefile location. For example:

```
cp /orcd/software/community/001/spack/modulefiles/core/linux-rocky8-x86_64/gcc/12.2.0/* /orcd/software/community/001/modulefiles/core
cp /orcd/software/community/001/spack/modulefiles/community/linux-rocky8-x86_64/openmpi/4.1.4-6yzpa5p/gcc/12.2.0/* /orcd/software/community/001/modulefiles/community
```

There may be multiple branches in the module directory tree, so you may need to do this a few times. We may also need to adjust how we organize modules if we see conflicts between modules in separate branches. Dependency modules have a short hash on them so that should help minimize conflicts with dependency modules.

## Configuration Files

Here is a summary of the config files and the settings they use.

***config.yaml:***
* Set the install root path. Installation files will be automatically created in there.
  - core: `/orcd/software/community/001/spack/install/core/`
  - community: `/orcd/software/community/001/spack/install/community/` 
* Set install path scheme (`'{name}/{version}/{hash:7}'`)

***compilers.yaml:***
* Add compiling flags `-O3 -fPIC`, which are important to optimize the performance.
* When installing a new compiler, add it in this yaml file.

***modules.yaml:***
* Set the module root path. Module files will be automatically created in there.
  - core: `/orcd/software/community/001/spack/modulefiles/core`
  - community: `/orcd/software/community/001/spack/modulefiles/community`
* Both link and run dependency modules are loaded in the software module
* Dependency (implicit) modules are hidden- users can load them but they won't show up when you run `module avail`
* If needed, add environment variables under the name of a package, so that Spack will set them in a module file. It is not recommended to set `LD_LIBRARY_PATH` here.

***packages.yaml:***
* Set the group `orcd_rg_engagingsw_orcd-sw` in the permission section
* This file also lists externals, system-installed libraries spack can make use of

***upstreams.yaml:***
* Set the core stack as an upstream of community
