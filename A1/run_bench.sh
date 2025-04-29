#!/bin/bash

# Define benchmark-specific commands

declare -a benchmarks_tiny=("505.lbm_t" "513.soma_t" "535.weather_t" "532.sph_exa_t" "518.tealeaf_t" "519.clvleaf_t" "521.miniswp_t" "528.pot3d_t" "534.hpgmgfv_t")
declare -a gpu_frequencies=(800000000 900000000 1000000000 1100000000 1200000000 1300000000 1400000000 1500000000 1600000000)

for benchmark in "${benchmarks_tiny[@]}"; do
# Loop through each frequency
    for  frequency in "${gpu_frequencies[@]}"; do
    # Loop through each benchmark
            # Submit the job script to PBS, passing both frequency and benchmark
            job_id=$(qsub -v BENCHMARK="$benchmark",FREQUENCY="$frequency" run_benchmark_GPU_scaling.sh)
            echo "Submitted $benchmark at $frequency Hz with job ID $job_id"
            # Wait for the job to complete
            while true; do
                # Check if the job is still in the queue
                if ! qstat | grep -q $job_id; then
                    echo "$benchmark at $frequency Hz ($job_id) completed."
                    break
                else
                    echo "$benchmark at $grequency Hz ($job_id) is still in queue or running..."
                    sleep 30  # Check every 30 seconds
                fi
            done
    done
done

echo "All benchmarks have been executed sequentially at each frequency."
