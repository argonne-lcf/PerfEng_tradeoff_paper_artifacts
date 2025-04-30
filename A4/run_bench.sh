#!/bin/bash

declare -a benchmarks_tiny=("505.lbm_t" "513.soma_t" "535.weather_t" "532.sph_exa_t" "518.tealeaf_t" "519.clvleaf_t" "521.miniswp_t" "528.pot3d_t" "534.hpgmgfv_t")
declare -a uncore_frequencies=(800000000 900000000 1000000000 1100000000 1200000000 1300000000 1400000000 1500000000 1600000000 1700000000 1800000000 1900000000 2000000000 2100000000 2200000000 2300000000)
declare -a PLimits=(1800 1900 2000 2100 2200 2300 2400 2500 2600 2700 2800 2900 3000 3100 3200 3300 3400 3500)

for benchmark in "${benchmarks_tiny[@]}"; do
    for PLimit in "${PLimits[@]}"; do
      for uncore in "${uncore_frequencies[@]}"; do
         # Submit the job script to PBS, passing benchmark, Plimit and ufrequency
         job_id=$(qsub -v BENCHMARK="$benchmark",PLimit="$PLimit",UNCORE="$uncore" run_benchmark_PLimit_Uncore.sh)
         echo "Submitted $benchmark at $PLimit W and $uncore Hz with job ID $job_id"

         # Wait 
         while true; do
             # Check if the job is still in the queue
             if ! qstat | grep -q $job_id; then
                 echo "$benchmark at $PLimit W and $uncore Hz ($job_id) completed."
                 break
             else
                 echo "$benchmark at $PLimit W and $uncore Hz ($job_id) is still in queue or running..."
                 sleep 30  # Check every 30 seconds
             fi
         done
      done
    done
done

echo "All benchmarks have been executed sequentially at each frequency."
~                                                                          
