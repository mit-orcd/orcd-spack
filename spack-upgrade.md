# Spack Version Upgrade Plan

## Background

This cluster serves a few thousand users. The software stack is built using Spack environments
following the Spack Stacks tutorial pattern. Three environments make up the stack:

- **base_stack** — previously built `gcc@12.2.0` as a compiler (special Spack treatment pre-v1.0);
  **no longer needed** in Spack v1.0+ where compilers are regular package dependencies
- **core_stack** — builds core software including compilers (gcc@14 in the new setup), cmake,
  cuda, nvhpc, openblas, r, rclone, apptainer, netlib-lapack, openmpi, netlib-scalapack, fftw
- **community_stack** — builds community software (openfoam, gromacs, quantum-espresso, hdf5,
  netcdf, lammps, fftw, lftp, openjdk, root, eigen, cdo, gsl, ffmpeg); uses core_stack as an
  upstream

### Current State

- Spack version: **v0.22** → upgrading to **v1.1**
- Production install paths:
  - Core/base packages: `/orcd/software/core/001/spack/pkg`
  - Community packages: `/orcd/software/community/001/spack/pkg/`
  - Core modulefiles: `/orcd/software/core/001/spack/modulefiles`
  - Community modulefiles: `/orcd/software/community/001/spack/modulefiles`
  - Spack install symlink: `/orcd/software/community/001/spack/install/spack`
- Dev staging area: `/orcd/software/community/001/spack/stage/<user>/<date>`

## Problem

Upgrading Spack version causes most packages to be rebuilt because the hash algorithm changed
between versions. Rebuilding the entire stack would be disruptive to users and unnecessary since
the existing installs are still valid.

## Strategy

**Do not rebuild existing packages.** Instead:

1. Remove all `specs:` entries from the three `spack.yaml` environment files (leave config,
   compilers, packages, modules, upstreams sections intact).
2. Install the new Spack version.
3. Set up a dev environment with blank specs and verify the empty environments concretize/install
   cleanly with the new Spack version.
4. Add only the **new** packages desired for the new stack into the environment files.
5. Deploy to production — existing installs and modulefiles remain untouched; only new packages
   are built.

This works because Spack only manages packages listed in the environment's `specs:` section.
Packages previously installed (and their modules) continue to work even after the environment
specs are cleared.

### Spack v1.0+ compiler model change

Prior to v1.0, compilers were a special class that had to be installed in a separate first pass
(hence base_stack existing solely to build gcc@12.2.0). In v1.0+, compilers are treated as
regular package dependencies. This means:

- **base_stack is no longer needed.** gcc@14 can be specified directly in core_stack as a regular
  package.
- The `compilers:` section in `spack.yaml` and the separate `spack compiler find` step in the
  deploy scripts may no longer be required (or works differently). The deploy scripts
  (`deploy_stacks.sh`, `dev_deploy_stacks.sh`) will need to be simplified to remove the base_stack
  pass and the `spack compiler find` calls.
- gcc@12.2.0 is still declared as an external so the new Spack can reference existing builds.

## Upgrade Steps

### Phase 1 — Prepare blank environment files

- [x] Create a new branch for the upgrade work
- [x] Update `SPACK_VERSION` in `stack-setup-env.sh` (and `dev_stack-setup-env.sh`) from `v0.22`
      to `v1.1`
- [x] Leave `base_stack/spack.yaml` specs empty (base_stack is retired as an active build
      environment but the directory can stay for reference)
- [x] Clear `specs:` list in `core_stack/spack.yaml`
- [x] Clear `specs:` list in `community_stack/spack.yaml`
- [x] Add `gcc@12.2.0` as an **external package** in `core_stack/spack.yaml` and
      `community_stack/spack.yaml` (see snippet below)
- [x] Update `deploy_stacks.sh`, `dev_deploy_stacks.sh`, `make_dev_stack.sh`, and
      `update_prod_stack.sh` to remove the base_stack pass and `spack compiler find` calls

#### gcc@12.2.0 external declaration (add to `packages:` in `core_stack` and `community_stack`)

```yaml
packages:
  gcc:
    externals:
    - spec: gcc@12.2.0
      prefix: /orcd/software/core/001/spack/pkg/gcc/12.2.0/yt6vabm
    buildable: false
```

> **Why:** gcc@12.2.0 was built by the old Spack; its hash format is incompatible with v1.1.
> Declaring it as an external with its known prefix lets the new Spack use it as a compiler and
> dependency without trying to rebuild or re-hash it.

### Phase 2 — Set up dev environment with new Spack

- [x] Run `make_dev_stack.sh` to create a dated dev staging area under
      `/orcd/software/community/001/spack/stage/<user>/<date>/`
- [x] Run `dev_install_new_spack.sh` to clone Spack v1.1 into the dev staging area and update
      the dev `spack` symlink (called automatically by `make_dev_stack.sh` since production spack
      is still v0.22)
- [x] Verify dev environment activates cleanly with new Spack version

### Phase 3 — Verify blank environments

- [x] `spack env activate core_stack && spack install` — confirmed no-op
- [x] `spack env activate community_stack && spack install` — confirmed no-op

### Phase 4 — Add new packages

- [x] Build `gcc@14%gcc@8.5.0` in `core_stack` — built as gcc@14.3.0
- [ ] Add `openmpi@5 %gcc@14` to `core_stack` specs and build
- [ ] Regenerate modules: `spack module lmod refresh -y`
- [ ] Test that new modules load correctly

### Phase 5 — Production deployment

- [ ] Run `install_new_spack.sh` to clone Spack v1.1 into the production install space and
      update the production `spack` symlink
- [ ] Run `update_prod_stack.sh` to promote dev configs to production paths
- [ ] Run `deploy_stacks.sh` to install in production
- [ ] Verify existing modules still load for users
- [ ] Verify new modules are available

## New Packages to Add

| Package | Stack | Compiler | Notes |
|---------|-------|----------|-------|
| `gcc@14` | core_stack | `%gcc@8.5.0` (system) | Compilers are regular deps in v1.0+ |
| `openmpi@5` | core_stack | TBD — `%gcc@12.2.0` and/or `%gcc@14` | May build both |
| `gromacs` | community_stack | TBD — `%gcc@12.2.0` | Needs SIMD support (will need to test) |

## Notes and Decisions

_Running log of decisions, issues encountered, and resolutions._

- **2026-05-06** Request to update Gromacs and build with SIMD support. Currently it gives a warning that it doesn't support SIMD, and seems to be running slower than it should. Would like to try to rebuild with SIMD support (may require rebuilding FFTW with SIMD support as well).
- **2026-05-01** (Phase 4 in progress): gcc@14.3.0 built successfully in dev environment.
  Next step: add openmpi@5 %gcc@14 to core_stack specs and build.
- **2026-05-01** (Phase 4 started): Added gcc@14%gcc@8.5.0 to core_stack specs; concretizes
  as gcc@14.3.0. openmpi@5 must wait until gcc@14 is built — Spack v1.1 requires the compiler to
  be a concrete or external package before dependents can concretize. Also fixed slurm and munge
  external specs in both core_stack and community_stack by removing `%gcc@12.2.0` annotations
  (system externals don't need compiler provenance in v1.1).
- **2026-05-01** (Phase 3 complete): Both core_stack and community_stack install as no-ops under
  Spack v1.1.1. During the first run Spack auto-migrated the deprecated `compilers:` section into
  `packages:` externals with `extra_attributes`. Cleaned up both spack.yaml files: removed
  `compilers:` section, removed duplicate gcc@12.2.0 entry, removed `buildable: false` on gcc
  package (needed so gcc@14 can be built later).
- **2026-05-01** (Phase 2 complete): Dev staging area created at
  `/orcd/software/community/001/spack/stage/milechin/20260501`. Spack v1.1.1 cloned and symlinked.
  Both `core_stack` and `community_stack` activate cleanly under the new Spack.
- **2026-05-01** (Phase 1 complete): Updated SPACK_VERSION to v1.1 in setup-env scripts. Cleared
  specs from all three environment files. Added gcc@12.2.0 external declaration to core_stack and
  community_stack. Simplified deploy scripts (base_stack pass and spack compiler find removed).
- **2026-05-01**: Initiated upgrade plan. Upgrading v0.22 → v1.1. New packages: gcc@14 and
  openmpi@5, both in core_stack. gcc@12.2.0 must be declared as an external (prefix:
  `/orcd/software/core/001/spack/pkg/gcc/12.2.0/yt6vabm`) in core_stack and community_stack.
  Compiler for openmpi@5 TBD — may build with both gcc@12.2.0 and gcc@14.
- **2026-05-01**: Spack v1.0+ treats compilers as regular package dependencies, so base_stack
  is no longer needed as a separate first-pass environment. gcc@14 goes directly into core_stack.
  Deploy scripts need updating to remove the base_stack pass and `spack compiler find` calls.
