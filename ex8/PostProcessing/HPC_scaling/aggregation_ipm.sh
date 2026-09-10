#!/bin/bash

set -euo pipefail

OUT="ipm_scaling_analysis.csv"

echo "ranks,nodes,wallclock_avg_s,mpi_avg_s,comm_percent,allreduce_count,isend_count,mem_avg_gb" > "$OUT"

for f in $(ls strong_scaling_logs/ThMc_scaling_ref1_*.o | sort -V); do
    
    if ! grep -q "IPMv" "$f"; then
        continue
    fi
    
    echo "Processing $f..."

    ranks=$(grep -E "^# mpi_tasks :" "$f" | awk '{print $4}')
    nodes=$(grep -E "^# mpi_tasks :" "$f" | awk '{print $6}')
    
    comm_pct=$(sed -n 's/.*%comm[ \t]*:[ \t]*\([0-9.]*\).*/\1/p' "$f")
    
    wallclock=$(grep -E "^# wallclock :" "$f" | awk '{print $5}')

    mpi_avg=$(grep -E "^# MPI\s+:" "$f" | awk '{print $5}')
    
    allreduce_count=$(grep "MPI_Allreduce" "$f" | awk '{print $4}')
    allreduce_count=${allreduce_count:-0}

    isend_count=$(grep "MPI_Isend" "$f" | awk '{print $4}')
    isend_count=${isend_count:-0}
    
    mem_avg=$(grep -E "^# mem \[GB\]\s+:" "$f" | tail -n 1 | awk '{print $6}')

    echo "$ranks,$nodes,$wallclock,$mpi_avg,$comm_pct,$allreduce_count,$isend_count,$mem_avg" >> "$OUT"

done

(head -n 1 "$OUT" && tail -n +2 "$OUT" | sort -t, -k1,1n) > "${OUT}.tmp" && mv "${OUT}.tmp" "$OUT"

echo "Extraction terminée. Fichier généré : $OUT"
