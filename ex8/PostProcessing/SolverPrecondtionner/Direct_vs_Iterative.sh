#!/bin/bash

echo "Generating jobs for solver comparison..."

EXEC="../../build/Thermomechanical"
LIB_U="../../build/src/libU3SI2-generic.so"
LIB_A="../../build/src/libALFENI-generic.so"

LOG_DIR="direct_vs_iterative_logs"
JOB_DIR="direct_vs_iterative_jobs"

mkdir -p "$LOG_DIR"
mkdir -p "$JOB_DIR"

MESH="../../mesh/Partitioning/CompleteMesh1024/output-mesh1024."

JOB_FILE="$JOB_DIR/job_mumps.sh"
LOG_FILE="$LOG_DIR/run_mumps.log"

cat <<EOF > "$JOB_FILE"
#!/bin/bash
#MSUB -n 1024
#MSUB -T 3600
#MSUB -q milan
#MSUB -m work,scratch
#MSUB -J MUMPS
#MSUB -o ${LOG_FILE}.out
#MSUB -e ${LOG_FILE}.err

echo "Execution of MUMPS configuration"
echo "Thermal: MUMPSSolver + NONE"
echo "Mechanical: MUMPSSolver + NONE"

ccc_mprun "$EXEC" -m "$MESH" \\
    --libraryU3SI2 "$LIB_U" --libraryALFENI "$LIB_A" \\
    -r 0 \\
    -svTh "MUMPSSolver" -pcTh "NONE" \\
    -svMc "MUMPSSolver" -pcMc "NONE" \\
    --verbose 1 > "$LOG_FILE" 2>&1

echo "Run finished : \$(date)"
EOF

ccc_msub "$JOB_FILE"

sleep 0.5

JOB_FILE="$JOB_DIR/job_gmres_amg_minres_diagscale.sh"
LOG_FILE="$LOG_DIR/run_gmres_amg_minres_diagscale.log"

cat <<EOF > "$JOB_FILE"
#!/bin/bash
#MSUB -n 1024
#MSUB -T 3600
#MSUB -q milan
#MSUB -m work,scratch
#MSUB -J GMRES_AMG_MINRES
#MSUB -o ${LOG_FILE}.out
#MSUB -e ${LOG_FILE}.err

echo "Execution of GMRES/AMG + MINRES/DiagScale configuration"
echo "Thermal: HypreGMRES + HypreBoomerAMG"
echo "Mechanical: MINRESSolver + HypreDiagScale"

ccc_mprun "$EXEC" -m "$MESH" \\
    --libraryU3SI2 "$LIB_U" --libraryALFENI "$LIB_A" \\
    -r 0 \\
    -svTh "HypreGMRES" -pcTh "HypreBoomerAMG" \\
    -svMc "MINRESSolver" -pcMc "HypreDiagScale" \\
    --verbose 1 > "$LOG_FILE" 2>&1

echo "Run finished : \$(date)"
EOF

ccc_msub "$JOB_FILE"

echo -e "\n===================================================================="
echo "All submissions (2 jobs) are in the queue!"
echo "===================================================================="
echo "Jobs : $JOB_DIR"
echo "Logs : $LOG_DIR"
echo "===================================================================="
