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
- [x] Add `openmpi@5 %gcc@14` to `core_stack` specs and build — built as openmpi@5.0.8
- [x] Add `openmpi@5 %gcc@12.2.0` to `core_stack` specs and build — built as openmpi@5.0.8
- [x] Regenerate modules: `spack module lmod refresh -y` — modules confirmed present in staging
- [x] Uninstall Lustre-linked openmpi builds and reinstall — forced by hash (`/tlbikgq` %gcc@14,
      `/ksnfg6p` %gcc@12.2.0); new gcc@14 build is `cxdbpjk`
- [x] Rebuild with `+internal-pmix` — bundles pmix and prrte inside openmpi so `prted` lives in
      openmpi's own `bin/` (like `orted` in v4); forced by uninstalling by hash and reinstalling
- [x] Regenerate modules after rebuild
- [x] Test that new modules load and MPI works over InfiniBand — OSU-Microbenchmarks osu_bw
      passed on both openmpi@5.0.8 %gcc@14 and %gcc@12.2.0

#### OSU-Microbenchmarks InfiniBand test procedure

The benchmarks must be recompiled against the new openmpi@5 before running. Note: the
`module use` line for the gcc subdirectory is not needed — openmpi loads correctly without it.

**Step 1 — Load the staged modules**

```bash
STAGING=/orcd/software/community/001/spack/stage/milechin/20260501

module use $STAGING/core/modulefiles/Core
module load gcc/14.3.0
module load openmpi/5.0.8
```

**Step 2 — Compile against the new MPI**

```bash
export INSTALL_DIR=~/mpitutorial/OSU-MicroBenchmarks/install_ompi5_gcc14/
cd ~/mpitutorial/OSU-MicroBenchmarks/osu-micro-benchmarks-7.3
./configure CC=mpicc CXX=mpicxx --prefix=$INSTALL_DIR >log.config
make clean
make >log.make
make install >log.install
```

**Step 3 — Submit the bandwidth test as a job**

A ready-to-use run script is at:
`~/mpitutorial/OSU-MicroBenchmarks/install/libexec/osu-micro-benchmarks/mpi/pt2pt/run_ompi5_gcc14.sh`

Key differences from older run scripts:
- Uses staged module paths (not production paths)
- Use `mpirun` not `srun` — `srun --mpi=pmi2` causes openmpi@5/prrte to start each task as an
  independent MPI singleton rather than a connected job; `mpirun` uses prrte directly and works
  correctly within the SLURM allocation
- Pass `--mca smsc ^knem` to suppress knem warnings (`/dev/knem` not loaded on compute nodes;
  OpenMPI falls back to xpmem for single-copy shared memory)
- Runs `osu_bw` from the new `install_ompi5_gcc14/` prefix

**What to look for:** Bandwidth should be in the range of tens of GB/s on InfiniBand nodes (not
~1 GB/s, which would indicate Ethernet fallback). Latency for small messages should be low (< 5 µs).

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
| `openmpi@5~lustre` | core_stack | `%gcc@12.2.0` and `%gcc@14` | Both variants; `~lustre` required — cluster does not use Lustre |
| `gromacs` | community_stack | TBD — `%gcc@12.2.0` | Needs SIMD support (will need to test) |

## Notes and Decisions

_Running log of decisions, issues encountered, and resolutions._

- **2026-06-24** (Phase 4 complete): Both openmpi@5.0.8 builds (%gcc@14 and %gcc@12.2.0) passed
  the OSU-Microbenchmarks `osu_bw` point-to-point bandwidth test. InfiniBand confirmed working.
  Phase 5 (production deployment) is the next step.
- **2026-06-23** (Phase 4 in progress): OSU-Microbenchmarks configure fails — `ldd` confirms
  `libmpi.so` from staged openmpi@5.0.8 has a runtime dependency on `liblustreapi.so.1` (not
  present on this cluster). Spack database already records both builds (`tlbikgq` %gcc@14,
  `ksnfg6p` %gcc@12.2.0) as `~lustre`, so `spack concretize -f && spack install` is a no-op.
  The builds were likely done on a node where Lustre client libs were present and got auto-detected
  by OpenMPI's configure. Fix: uninstall by hash to force a clean rebuild:
  `spack uninstall /tlbikgq && spack uninstall /ksnfg6p && spack install`.
- **2026-06-23** (Phase 4 in progress): Confirmed modules are present in staging area at
  `/orcd/software/community/001/spack/stage/milechin/20260501/core/modulefiles/` — both
  `gcc/14.3.0/openmpi/5.0.8.lua` and `gcc/12.2.0/openmpi/5.0.8.lua` are generated. Module refresh
  step marked complete. Next step: compile OSU-Microbenchmarks against openmpi@5 and run pt2pt
  bandwidth test to verify InfiniBand is being used.
- **2026-05-08**: openmpi@5 `+pmi` variant is only valid for openmpi@:4 and was dropped.
  openmpi@5 uses PMIx via prrte automatically when `schedulers=slurm`. This cluster's SLURM does
  not have a PMIx plugin (`srun --mpi=list` shows only `none`, `cray_shasta`, `pmi2`). Using
  `srun --mpi=pmi2` causes prrte to treat each task as an independent MPI singleton — tasks don't
  connect. **Fix: use `mpirun` within the SLURM allocation.** Also: in openmpi@5, the process
  daemon (`prted`) is part of a separate prrte project and lives outside openmpi's `bin/` when
  built against external prrte. The openmpi module does not add prrte's bin to PATH, so `prted`
  can't be found when mpirun tries to spawn it on remote nodes. **Fix: rebuild with
  `+internal-pmix`** — bundles prrte inside openmpi so `prted` is in openmpi's own `bin/`,
  exactly like `orted` was in v4. **User-facing impact:** job scripts using openmpi@5 modules
  should use `mpirun` instead of `srun`.
- **2026-05-06** Request to update Gromacs and build with SIMD support. Currently it gives a warning that it doesn't support SIMD, and seems to be running slower than it should. Would like to try to rebuild with SIMD support (may require rebuilding FFTW with SIMD support as well).
- **2026-05-08** (Phase 4 in progress): openmpi@5.0.8 built successfully in dev environment — both %gcc@14 and %gcc@12.2.0 variants. Next steps: regenerate modules and test.
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
