#!/bin/bash

echo "Generating jobs for the study of mechanics solver/preconditioner..."

EXEC="../../build/Thermomechanical"
LIB_U="../../build/src/libU3SI2-generic.so"
LIB_A="../../build/src/libALFENI-generic.so"

LOG_DIR="SvPc_mech_logs"
JOB_DIR="SvPc_mech_jobs"

mkdir -p "$LOG_DIR"
mkdir -p "$JOB_DIR"

MESH="../../mesh/Partitioning/CompleteMesh1024/output-mesh1024."

SV_TH="HypreGMRES"
PC_TH="HypreBoomerAMG"

SOLVERS=("HyprePCG"
         "HypreGMRES"
         "HypreFGMRES"
         "MINRESSolver"
         "CGSolver"
         "MUMPSSolver"
         "BiCGSTABSolver"
)

PRECONDS=("HypreBoomerAMG"
          "HypreDiagScale"
          "HypreILU"
          #"HypreParaSails"
)

COUNT=0

for SV_MC in "${SOLVERS[@]}"; do

    if [[ "$SV_MC" == *"MUMPS"* ]]; then
        PRECONDS_MC=("NONE")
    else
        PRECONDS_MC=("${PRECONDS[@]}")
    fi

    for PC_MC in "${PRECONDS_MC[@]}"; do
        ((COUNT++))

        JOB_FILE="$JOB_DIR/job_sweep_${COUNT}.sh"
        LOG_FILE="$LOG_DIR/run_${SV_TH}_${PC_TH}_Mc_${SV_MC}_${PC_MC}.log"

        echo "-> Submission [$COUNT] : Th: $SV_TH+$PC_TH | Mc: $SV_MC+$PC_MC"

        cat <<EOF > "$JOB_FILE"
#!/bin/bash
#MSUB -n 1024
#MSUB -T 3600
#MSUB -q milan
#MSUB -m work,scratch
#MSUB -J SvPcMech_${COUNT}
#MSUB -o ${LOG_FILE}.out
#MSUB -e ${LOG_FILE}.err

echo "Execution of configuration $COUNT"
echo "Thermal: $SV_TH + $PC_TH"
echo "Mechanical: $SV_MC + $PC_MC"

ccc_mprun "$EXEC" -m "$MESH" \\
    --libraryU3SI2 "$LIB_U" --libraryALFENI "$LIB_A" \\
    -r 0 \\
    -svTh "$SV_TH" -pcTh "$PC_TH" \\
    -svMc "$SV_MC" -pcMc "$PC_MC" \\ 
    --verbose 1 > "$LOG_FILE" 2>&1

echo "Run finished : \$(date)"
EOF

        ccc_msub "$JOB_FILE"
        sleep 0.5
    done
done

echo -e "\n===================================================================="
echo "All submissions ($COUNT jobs) are in the queue!"
echo "===================================================================="

