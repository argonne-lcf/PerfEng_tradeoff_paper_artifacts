# SPEC Configuration File Description

This configuration file defines the compiler settings, compilation options, and runtime model for building and executing SPEC benchmarks.

## Purpose

The configuration specifies:
- **Compiler selection** 
- **Mode of compilation**:
  - MPI-only
  - OpenMP-only
  - Hybrid MPI+OpenMP on CPU
  - Hybrid MPI+OpenMP with GPU offloading

For these experiments, we specifically use the **MPI + OpenMP Offload** model to target GPU-accelerated systems.

---

## Usage Example

To generate the build and run directories and invoke the command for 513.soma_t benchmark:

```bash
runhpc --fake --loose --size ref --tune base --config my_config --define model=tgtgpu --ranks 12 513.soma_t
```
This will form the build and run directories with proper files. 
Go to the build directory:

```bash
specmake
```
Invoke the binary to generate the commandline

```bash
specinvoke -n
```




