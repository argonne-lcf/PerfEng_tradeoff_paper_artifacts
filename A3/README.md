# Artifact A3: U-PullUp Agent and Benchmark Scripts

This artifact contains the source code, build files, and benchmark automation scripts related to the U-PullUp agent and experiments described in the paper.
The agent requires GEOPM installation for compilation and deployment.
## Contents

| File | Description |
|:-----|:------------|
| `UPullUpAgent.cpp`, `UPullUpAgent.hpp` | Source code for the custom U-PullUp agent that boosts CPU uncore frequency based on utilization and power thresholds. |
| `Makefile` | Build script to compile the U-PullUp agent. |
| `run_bench.sh` | Wrapper script that automates batch submission of benchmarks over different power settings |
| `run_benchmark_UpullUp.sh` | PBS job script invoked by `run_bench.sh` to run individual benchmark jobs |



## Building the U-PullUp Agent

To compile the U-PullUp agent:

```bash
make

```
The agent should be linked with GEOPM runtime through GEOPM_AGENT environment variable.

