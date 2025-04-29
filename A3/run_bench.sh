#!/bin/bash
declare -a benchmarks_tiny=("505.lbm_t" "513.soma_t" "535.weather_t" "532.sph_exa_t" "518.tealeaf_t" "519.clvleaf_t" "521.miniswp_t" "528.pot3d_t" "534.hpgmgfv_t")
declare -a PLimits=(1800 1900 2000 2100 2200 2300 2400 2500 2600 2700 2800 2900 3000 3100 3200 3300 3400 3500)
for benchmark in "${benchmarks_tiny[@]}"; do
# Loop through each frequency
    for PLimit in "${PLimits[@]}"; do
    # Loop through each benchmark
        # Submit the job script to PBS, passing both frequency and benchmark
        job_id=$(qsub -v BENCHMARK="$benchmark",PLimit="$PLimit" run_benchmark_UpullUp.sh)
        echo "Submitted $benchmark at $PLimit W and $uncore Hz with job ID $job_id"
        # Wait for the job to complete
         while true; do
             # Check if the job is still in the queue
             if ! qstat | grep -q $job_id; then
                 echo "$benchmark at $PLimit W ($job_id) completed."
                 break
             else
                 echo "$benchmark at $PLimit W ($job_id) is still in queue or running..."
                 sleep 30  # Check every 30 seconds
             fi
         done
    done
done

echo "All benchmarks have been executed sequentially at each frequency."
