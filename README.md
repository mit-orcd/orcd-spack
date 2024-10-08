
# orcd-spack
This repository contains ORCD Spack environment files and how to use Spack to install new software for core and community software stacks. We will follow these recipes on the Rocky 8 nodes moving forward.

This repository contains three directories of Spack environment files:
- base_stack: Contains compilers used in core and community stacks
- core_stack: Contains core software. Same install root as base_stack.
- community_sack: Contains community software. Different install root, but has core install root as an upstream.

Each directory contains two files:
- `spack.yaml`: Contains the install specs and configuration settings for the environment. Edit this file to add new packages to the environment.
- `spack.lock`: Contains the exact hashes of the packages installed. With this file and `spack.yaml` you can exactly recreate a spack environment. Do not edit this file directly, it is managed by Spack.

There are a few supporting scripts to support installing new software:
- `stack-setup-env.sh`: This file runs Spack's `setup-env.sh` for the production environment. It sets environment variables for the Spack Version, Home, and Install location.
- `install_new_spack.sh`: Installs a new Spack and sets `$SPACK_HOME/spack` symlink to the latest install. Installs the `$SPACK_VERSION` set in `stack-setup-env.sh`.
- `deploy_stacks.sh`: Installs any software listed in the stack environments that are not already installed. Adds new compilers and creates new modulefiles as needed.
- `make_dev_stack.sh`: Creates a temporary "development" environment in `/orcd/software/community/001/spack/stage/$USER/$(date +"%Y%m%d")`. Links to existing spack install or installs if no existing spack exists. Creates `dev_stack-setup-env.sh`- copy of `stack-setup-env.sh` with `$SPACK_HOME` pointing to the development `$SPACK_HOME`. Updates local environment files to use the development space and add upstreams to existing production space.
- `dev_install_new_spack.sh`: Installs a new spack based on configuration in `dev_stack-setup-env.sh`.
- `dev_deploy_stacks.sh`: Deploys any changes in environment files to development stacks.
- `update_prod_stack.sh`: Updates environment files to install to production place, keeping any updates to the specs section.

## Adding New Packages

The production spack install space will already be set up when you add new packages. We will use a GitHub workflow to install new packages, similar to how we add new documentation pages.

1. Clone this repository on Engaging (if you haven't already). If you already have a clone run `git checkout main` and `git pull` to make sure you are on the main branch and have the latest updates.
1. Create a branch. We like to use the convention of using your initials as a prefix for the branch name. For example: `git checkout -b lm/adding_netcdf`
2. Run “make_dev_stack.sh” to set up dev stack, this:
    1. Creates symlink to existing spack installation in dev space or installs spack if it doesn’t exist
    3. Updates the environment configs install and module roots and adds upstreams to production spack install
    4. Creates `dev_stack-setup-env.sh` file for setting up dev environment
3. Run `dev_deploy_stacks.sh` to add existing packages to dev environments
4. Make changes, run `dev_deploy_stacks.sh` again to deploy to your dev environment, test installs
5. Copy changes back to production by running `update_prod_stack.sh`
6. Create a Pull Request for your branch. Check:
    1. You have run `update_prod_stack.sh`- the environment files should reflect the production space, not your development space
    2. Look at the *.yaml file diffs- do these make sense? The only thing that should have changed is the `specs` section.
    3. Pull and merge any changes from the main branch into your branch: `git checkout main`, `git pull`, `git checkout my_branch`, `git merge main`
    4. If all this looks good merge into the main branch. If you are not sure ask another team member to take a look.
7. Checkout the main branch and pull in your new changes (`git checkout main`, `git pull`). Run `deploy_stacks.sh` to install the new packages in the production space.

## Basic Spack Usage

We are using [Spack Environments](https://spack.readthedocs.io/en/latest/environments.html) to manage our software stacks, roughly following the [Stacks Tutorial](https://spack-tutorial.readthedocs.io/en/latest/tutorial_stacks.html).

You can run `source stack-setup-env.sh` to set up Spack, then for any of the environments run:

```
spack env activate path/to/core_stack
```

The above will activate the core stack environment located at `path/to/`. The production environments are kept with the production spack installation. The following commands assume you have an environment active.

### Listing Packages

To see the packages installed for core, you can run:

```
spack find -x
```

### Helpful Commands for Installing Software

To see if a software is available through spack run:

```
spack list [software]
```

Sometimes the name will be slightly different than you expect. Once you have the name spack uses you can use the `spack info` command to see the full information for that software, including what versions are available, what it depends on, and which options are available for that software during build.

```
spack info [package]
```

To add a package spec to your environment run the following in an active environment:

```
spack add [spec]
```

You can also add the spec manually to the `spack.yaml` environment file. Be sure to include the desired compiler, architecture, and any flags.

If you want to see what dependencies will be installed with this new package, run:

```
spack concretize
```

This can be helpful if you want to make sure spack is using a particular dependency that is already installed. You don't have to run this, Spack will do this step during the install that gets called in the `deploy_stacks.sh` script.

### Creating Modules

After the installation is successful, lua module files are created under the module root path.

Sometimes a module isn't created during the build or you'd like to regenerate them. You can run the command:

```
spack module lmod refresh [package]
```

to recreate a specific package, or

```
spack module lmod refresh
```

to recreate all missing modules. The `deploy_stacks.sh` file also runs these commands for you, so modules should be created.

## Configuration Files

Here is a summary of the `spack.yaml` sections and the settings they use.

***config:***
* Set the install root path. Installation files will be automatically created in there.
  - base: `/orcd/software/core/001/spack/pkg/`
  - core: `/orcd/software/core/001/spack/pkg/`
  - community: `/orcd/software/community/001/spack/pkg/` 
* Set install path scheme (`'{name}/{version}/{hash:7}'`)

***compilers:***
* Add compiling flags `-O3 -fPIC`, which are important to optimize the performance.
* When installing a new compiler it will be added to this section by the `deploy_stacks.sh` script.

***modules:***
* Set the module root path. Module files will be automatically created in there.
  - core: `/orcd/software/core/001/spack/modulefiles/`
  - community: `/orcd/software/community/001/spack/modulefiles/`
* No dependency modules are loaded in the software module. We may need to change this later if we find it doesn't work.
* Dependency (implicit) modules are hidden- users can load them but they won't show up when you run `module avail`
* If needed, add environment variables under the name of a package, so that Spack will set them in a module file. It is not recommended to set `LD_LIBRARY_PATH` here.

***packages:***
* Set the group `orcd_rg_engagingsw_orcd-sw` in the permission section
* This file also lists externals, system-installed libraries spack can make use of

***upstreams:***
* Set the core stack as an upstream of community
