# Spack Setup Notes

Set Spack location containing spack install (note update the release version as needed):

```
SPACK_HOME=/orcd/software/community/001/spack/
cd $SPACK_HOME
git clone --depth=100 --branch=releases/v0.22 https://github.com/spack/spack.git ./spack_v0.22
```

If it hasn't already, clone this repository to `$SPACK_HOME` for all the config files. If the repository is already there, run `git pull` to grab any updates:

```
cd $SPACK_HOME
git clone https://github.com/mit-orcd/orcd-spack.git
```

or

```
cd $SPACK_HOME/orcd-spack
git pull
```

Config files for core software will be in orcd-spack/core_configs, similarly config files for community software will be on orcd-spack/community_configs. You can point to specific sets of config files, or scopes, with the `-C` flag in any spack command.
