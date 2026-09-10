#!/bin/bash

REF=0

PROC_LIST=(
32
64
128
256
512
1024
2048
4096
8192
16384
)

EXEC="../../build/Thermomechanical"

JOB_DIR="strong_scaling_jobs"
LOG_DIR="strong_scaling_logs"

mkdir -p "$JOB_DIR"
mkdir -p "$LOG_DIR"

echo "Strong Scaling starting (Refinement: $REF)"

for NPROC in "${PROC_LIST[@]}"; do

    JOB_FILE="$JOB_DIR/ThMc_scaling_${NPROC}.sh"

    echo "-> Generate and submit for $NPROC ranks..."

    cat <<EOF > $JOB_FILE
#!/bin/bash

#MSUB -n $NPROC
#MSUB -T 3600
#MSUB -q milan
#MSUB -m work,scratch
#MSUB -o $LOG_DIR/ThMc_scaling_${NPROC}.o
#MSUB -e $LOG_DIR/ThMc_scaling_${NPROC}.e

# module purge
# module load gnu/12.3.0 mpi cmake/3.29.6
# module load ipm

echo "Run starts"
echo "Refinement : $REF"

ccc_mprun "$EXEC" \
    --mesh "../Partitioning_full/CompleteMesh${NPROC}/output-mesh${NPROC}." \
    --refinement "$REF" \
    -lU "../../build/src/libU3SI2-generic.so" \
    -lA "../../build/src/libALFENI-generic.so"

echo "Run ends : \$(date)"
EOF

    ccc_msub $JOB_FILE

    sleep 1

done

echo "All tasks are in the queue."
