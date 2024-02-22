
# orcd-spack
ORCD configurations and best practices on Spack. 

Refer to this page to set up Spack to inherit the TSQ configuration on Rocky8 systems.
https://mit-orcd.github.io/orcd-docs-previews/PR/PR29/recipes/spack-basics/

Supposed the Spack work directory $spack_work is under the home directory of each RCF members.

This directory includes RCF configure files for Spack.

### Usage

Log in a Rocky 8 head node, such as eofe10.mit.edu. Set up Spack environment every time after login.

cd $spack_work
source spack/share/spack/setup-env.sh
export SPACK_USER_CONFIG_PATH=`pwd`/user_config

These congifure files are copied from TSQ and customized by the RCF team.
config.yaml, compilers.yaml modules.yaml  packages.yaml  upstreams.yaml.

Put them in $spack_work/use_config
They will overright the default.

For config.yaml, it also works to put it in $spack_work/spack/etc/spack


### Connfigure yaml files

config.yaml:
  --- Set install path
  --- Set install path scheme

compilers.yaml:
 --- add compling flags: -O3 -fPIC, which are important to optimize the performance.
 --- when installing a new compiler, will need to add it in the yaml file.

modules.yaml:
 --- Set the module root path
 --- Add the package name under "include" to let spack create module files for it. Use alphabetical order.
 --- When needed, add environment variables under the name of a package, so that Spack will set them in a module file. It is not recommended to set LD_LIBRARY_PATH here.

packages.yaml:
 --- change the group slurm_admin to orcd_rg_engagingsw_orcd-sw in the permsssion session.


### Set LD_LIBRARY_PATH in a module file

Execute these commands,

spack config add modules:prefix_inspections:lib64:[LD_LIBRARY_PATH]
spack config add modules:prefix_inspections:lib:[LD_LIBRARY_PATH]

This add the following lines in to the modules.yaml

  prefix_inspections:
    lib64: [LD_LIBRARY_PATH]
    lib:
    - LD_LIBRARY_PATH

Then install a package, for example,

spack install openmpi@3.1.6%gcc@12.2.0

then the LD_LIBRARY_PATH will be set in the module file.


###  Installation

Use gcc 12.2.0 built by TSQ for most packages

spack install openmpi@4.0.7%gcc@12.2.0

The build stage files are removed automatically by default. Keep it if needed:
spack install --keep-stage openmpi@4.0.7%gcc@12.2.0

It is sometimes useful to clean cache when a building failed and rebuild it.

spack clean -m



