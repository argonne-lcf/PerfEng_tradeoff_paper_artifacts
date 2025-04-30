# Artifact Scripts Overview

This directory contains two scripts used for automating benchmark execution and job submission for the experiments in A4.

## Scripts

### `run_bench.sh`
- **Purpose**: A wrapper script to automate batch job submissions.
- **Functionality**:
  - Iterates over a list of benchmarks and node-level power caps and CPU uncore frequency levels.
  - Submits jobs to the scheduler in a **batch scheduling** fashion.
  - Pass necessary variables for the job script before invoking.

### `run_benchmark_PLimit_Uncore.sh`
- **Purpose**: A PBS job script submitted by `run_bench.sh`.
- **Functionality**:
  - Loads necessary environment modules.
  - Executes the benchmark based on parameters passed by `run_bench.sh`.
- **Notes**:
  - The script is designed to be flexible and parametrized by environment variables set externally by `run_bench.sh`.

## Usage

To launch the benchmark experiments:

```bash
bash run_bench.sh
