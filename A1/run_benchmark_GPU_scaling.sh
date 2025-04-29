#!/bin/bash -l
#PBS -N SPEC_GPU_FREQUENCY_SCALING
#PBS -l select=1
#PBS -l place=scatter
#PBS -l walltime=1:00:00
#PBS -q workq
#PBS -A Aurora_deployment

NNODES=`wc -l < $PBS_NODEFILE`
NRANKS=12 # Number of MPI ranks to spawn per node
NDEPTH=1 # Number of hardware threads per rank (i.e. spacing between MPI ranks)
NTHREADS=1 # Number of software threads per rank to launch (i.e. OMP_NUM_THREADS)

NTOTRANKS=$(( NNODES * NRANKS ))

echo "NUM_OF_NODES= ${NNODES} TOTAL_NUM_RANKS= ${NTOTRANKS} RANKS_PER_NODE= ${NRANKS} THREADS_PER_RANK= ${NTHREADS}"

module load geopm-runtime

declare -A commands
commands["505.lbm_t"]="mpiexec -np ${NTOTRANKS}  -ppn ${NRANKS} --depth=${NDEPTH} --cpu-bind depth  /soft/tools/mpi_wrapper_utils/gpu_tile_compact.sh  ./lbm 0<&- > lbm.out 2>> lbm.err"
commands["513.soma_t"]="mpiexec -np ${NTOTRANKS} --ppn ${NRANKS} --depth=${NDEPTH} --cpu-bind depth   /soft/tools/mpi_wrapper_utils/gpu_tile_compact.sh  ./soma -r 42 -t 200 --npoly=14000000 --gen-state-file 0<&- > soma.out 2>> soma.err"
commands["518.tealeaf_t"]="mpiexec -np ${NTOTRANKS} --ppn ${NRANKS} --depth=${NDEPTH} --cpu-bind depth   /soft/tools/mpi_wrapper_utils/gpu_tile_compact.sh  ./tealeaf 0<&- > output 2>> tea.err"
commands["519.clvleaf_t"]="mpiexec -np ${NTOTRANKS} --ppn ${NRANKS} --depth=${NDEPTH} --cpu-bind depth   /soft/tools/mpi_wrapper_utils/gpu_tile_compact.sh  ./clvleaf 0<&- 2>> clover.err"
commands["521.miniswp_t"]="mpiexec -np ${NTOTRANKS} --ppn ${NRANKS} --depth=${NDEPTH} --cpu-bind depth  /soft/tools/mpi_wrapper_utils/gpu_tile_compact.sh  ./sweep --niterations 40 --ncell_x 96 --ncell_y 64 --ncell_z 64 --ne 64 --na 32 --nblock_z 8 0<&- > sweep_1.out 2>> sweep_1.err"
commands["528.pot3d_t"]="mpiexec -np ${NTOTRANKS} --ppn ${NRANKS} --depth=${NDEPTH} --cpu-bind depth   /soft/tools/mpi_wrapper_utils/gpu_tile_compact.sh  ./pot3d 1 0<&- > pot3d.stdout.out 2>> pot3d.stderr.err"
commands["532.sph_exa_t"]="mpiexec -np ${NTOTRANKS} --ppn ${NRANKS} --depth=${NDEPTH} --cpu-bind depth   /soft/tools/mpi_wrapper_utils/gpu_tile_compact.sh  ./sph_exa -n 210 -s 80 -w -1 0<&- > sph_exa.out 2>> sph_exa.err"
commands["534.hpgmgfv_t"]="mpiexec -np ${NTOTRANKS} --ppn ${NRANKS} --depth=${NDEPTH} --cpu-bind depth   /soft/tools/mpi_wrapper_utils/gpu_tile_compact.sh  ./hpgmgfv 5 9 300 0<&- > hpgmgfv.out 2>> hpgmgfv.err"
commands["535.weather_t"]="mpiexec -np ${NTOTRANKS} --ppn ${NRANKS} --depth=${NDEPTH} --cpu-bind depth   /soft/tools/mpi_wrapper_utils/gpu_tile_compact.sh  ./weather output6.ref.txt 24000 10000 3000 1250 600 100 6 ; 0<&- > weather.1.stdout.out 2>> weather.1.stderr.err"
BENCH_BASE="/path/to/SPEC_home/benchspec/HPC"
RESULTS_BASE="/path/to/result"
RUN_DIR="$BENCH_BASE/${BENCHMARK}/run/run_base_ref_intel_tgtgpu.0000"
OUTPUT_DIR="$RESULTS_BASE/${BENCHMARK}"

COMMAND="${commands[$BENCHMARK]}"
frequency=$FREQUENCY
echo "$COMMAND"
# output directory
mkdir -p "$OUTPUT_DIR"
echo "$RUN_DIR"
# Navigate to the run directory
cd "$RUN_DIR"
geopmwrite GPU_CORE_FREQUENCY_MIN_CONTROL board 0 $frequency
geopmwrite GPU_CORE_FREQUENCY_MAX_CONTROL board 0 $frequency
# GEOPM setup
export GEOPM_NUM_PROCESS=2
GEOPM_PROFILE=$BENCHMARK \
GEOPM_REPORT="${OUTPUT_DIR}/${BENCHMARK}_${NNODES}_${NRANKS}_report.yaml" \
GEOPM_REPORT_SIGNALS=CPU_INSTRUCTIONS_RETIRED,CPU_UNCORE_FREQUENCY_STATUS,GPU_POWER,GPU_ENERGY,GPU_CORE_POWER,GPU_CORE_ENERGY,LEVELZERO::GPU_CORE_FREQUENCY_EFFICIENT,GPU_CORE_FREQUENCY_STATUS,GPU_UTILIZATION,LEVELZERO::GPU_CORE_UTILIZATION,LEVELZERO::GPU_UNCORE_UTILIZATION \
GEOPM_TRACE="${OUTPUT_DIR}/${BENCHMARK}_${NNODES}_${NRANKS}_trace.csv" \
GEOPM_TRACE_SIGNALS=CPU_INSTRUCTIONS_RETIRED,CPU_UNCORE_FREQUENCY_STATUS,GPU_POWER,GPU_ENERGY,GPU_CORE_POWER,GPU_CORE_ENERGY,LEVELZERO::GPU_CORE_FREQUENCY_EFFICIENT,GPU_CORE_FREQUENCY_STATUS,GPU_UTILIZATION,LEVELZERO::GPU_CORE_UTILIZATION,LEVELZERO::GPU_UNCORE_UTILIZATION \
LD_DYNAMIC_WEAK=true \
GEOPM_PERIOD=0.01 \
geopmctl &

# Record start time
start_time=$(date +%s)
# Execute the benchmark
GEOPM_PROFILE=$BENCHMARK \
LD_PRELOAD=libgeopm.so.2 \
$COMMAND
# Record end time
end_time=$(date +%s)

# Calculate the duration
duration=$((end_time - start_time))
echo "Execution time for $BENCHMARK: $duration seconds" > "${OUTPUT_DIR}/${NNODES}_${NRANKS}_output.txt"

# Wait for GEOPM to finish and reverse to default 
geopmwrite GPU_CORE_FREQUENCY_MIN_CONTROL board 0 1600000000
geopmwrite GPU_CORE_FREQUENCY_MAX_CONTROL board 0 1600000000
wait
                                                                                                                  71,18         Bot

