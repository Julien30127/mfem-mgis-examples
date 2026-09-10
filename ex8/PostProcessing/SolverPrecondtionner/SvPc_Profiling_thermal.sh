#!/bin/bash

echo "Generating jobs for the study of thermal solver/preconditioner..."

EXEC="../../build/Thermomechanical"
LIB_U="../../build/src/libU3SI2-generic.so"
LIB_A="../../build/src/libALFENI-generic.so"

LOG_DIR="SvPc_th_logs"
JOB_DIR="SvPc_th_jobs"
mkdir -p "$LOG_DIR"
mkdir -p "$JOB_DIR"

MESH="../../mesh/Partitioning/CompleteMesh128/output-mesh128."

SOLVERS=("HyprePCG"
         "HypreGMRES"
         "HypreFGMRES"
         "MINRESSolver"
         "CGSolver"
         "MUMPSSolver"
         #"BiCGSTABSolver"
	 )

PRECONDS=("HypreBoomerAMG"
          "HypreDiagScale"
          #"HypreILU"
          #"HypreParaSails"
	  )

COUNT=0

# Fixed mechanics configuration
SV_MC="MUMPSSolver"
PC_MC="NONE"

for SV_TH in "${SOLVERS[@]}"; do

    if [[ "$SV_TH" == *"MUMPS"* ]]; then
        PRECONDS_TH=("NONE")
    else
        PRECONDS_TH=("${PRECONDS[@]}")
    fi

    for PC_TH in "${PRECONDS_TH[@]}"; do
        ((COUNT++))

        JOB_FILE="$JOB_DIR/job_sweep_${COUNT}.sh"
        LOG_FILE="$LOG_DIR/run_${MESH_NAME}_Th_${SV_TH}_${PC_TH}_Mc_${SV_MC}_${PC_MC}.log"

        echo "-> Submission [$COUNT] : $MESH_NAME | Th: $SV_TH+$PC_TH | Mc: $SV_MC+$PC_MC"

        cat <<EOF > "$JOB_FILE"
#!/bin/bash
#MSUB -n 128
#MSUB -T 3600
#MSUB -q milan
#MSUB -m work,scratch
#MSUB -J Swp_${COUNT}
#MSUB -o ${LOG_FILE}.out
#MSUB -e ${LOG_FILE}.err

echo "Exécution de la configuration $COUNT"

ccc_mprun "$EXEC" -m "$MESH" \\
    --libraryU3SI2 "$LIB_U" --libraryALFENI "$LIB_A" \\
    -r 0 \\
    -svTh "$SV_TH" -pcTh "$PC_TH" \\
    -svMc "$SV_MC" -pcMc "$PC_MC" > "$LOG_FILE" 2>&1

if [ \${PIPESTATUS[0]} -ne 0 ]; then
    echo "$MESH_NAME,$SV_TH,$PC_TH,$SV_MC,$PC_MC,FAILED,FAILED,FAILED" > "$CSV_PART"
fi
EOF

        ccc_msub "$JOB_FILE"
        sleep 0.5
    done
done

echo -e "\n===================================================================="
echo "All submissions ($COUNT jobs) are in the queue !"
echo "===================================================================="
echo "Once all jobs are finished, type this command to aggregate the results :"
echo ""
echo "bash aggregation_SvPc_th.sh"
echo "===================================================================="

