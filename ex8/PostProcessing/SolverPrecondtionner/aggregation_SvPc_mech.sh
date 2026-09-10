#!/bin/bash

set -euo pipefail

LOG_DIR_MECH="SvPc_mech_logs"
LOG_DIR_TH="SvPc_th_logs"

OUT_MECH="aggregation_SvPc_mech.csv"
OUT_TH="aggregation_SvPc_th.csv"

HEADER="physics,solver,preconditioner,dof,problem_footprint_GB,solution_footprint_GB,calls,min_s,mean_s,max_s,part_percent,stat_min,stat_max,stat_mean,stat_stddev"

echo "$HEADER" > "$OUT_MECH"
echo "$HEADER" > "$OUT_TH"

extract_timer() {
    local pattern="$1"
    local file="$2"
    local values

    values=$(
        grep -m1 "$pattern" "$file" \
            | grep -oE '[0-9]+(\.[0-9]+)?' \
            | head -5 \
            | paste -sd, \
            || true
    )

    if [[ -z "$values" ]]; then
        echo "0,0,0,0,0"
    else
        echo "$values"
    fi
}

extract_stats() {
    local block_name="$1"
    local file="$2"
    local values

    values=$(awk -F':' -v name="$block_name" '
        $0 ~ name {flag=1; next}
        flag && /Global MIN/ { min=$2 }
        flag && /Global MAX/ { max=$2 }
        flag && /MEAN/       { mean=$2 }
        flag && /STD DEV/    { std=$2; printf "%s,%s,%s,%s", min, max, mean, std; exit }
    ' "$file" | tr -d ' \t')

    if [[ -z "$values" ]]; then
        echo "N/A,N/A,N/A,N/A"
    else
        echo "$values"
    fi
}

process_log() {
    local f="$1"
    local output="$2"

    echo "Traitement : $f..."

    if ! grep -q "|--> Thermal" "$f" || ! grep -q "|--> Mechanics" "$f"; then
        echo "  Ignore : Incomplete run, diverges or timeout."
        return
    fi

    basename_f=$(basename "$f" .log)
    rest="${basename_f#run_}"

    th_part="${rest%%_Mc_*}"
    mc_part="${rest#*_Mc_}"

    th_solver="${th_part%%_*}"
    th_prec="${th_part#*_}"

    mc_solver="${mc_part%%_*}"
    mc_prec="${mc_part#*_}"

    [[ "$th_prec" == "NONE" ]] && th_prec="N/A"
    [[ "$mc_prec" == "NONE" ]] && mc_prec="N/A"

    dof=$(grep -m1 "Number of finite element unknowns" "$f" \
        | grep -oE '[0-9]+$' || echo 0)

    problem_mem=$(grep -m1 "After_problem_creation" "$f" \
        | grep -oE '[0-9]+(\.[0-9]+)?' \
        | tail -1 || echo 0)

    solution_mem=$(grep -m1 "After Solving" "$f" \
        | grep -oE '[0-9]+(\.[0-9]+)?' \
        | tail -1 || echo 0)

    thermal=$(extract_timer "|--> Thermal" "$f")
    mechanics=$(extract_timer "|--> Mechanics" "$f")

    temp_stats=$(extract_stats "DEBUG STATS : Temperature" "$f")
    disp_stats=$(extract_stats "DEBUG STATS : Displacement Magnitude" "$f")

    echo "Thermal,${th_solver},${th_prec},${dof},${problem_mem},${solution_mem},${thermal},${temp_stats}" \
        >> "$output"

    echo "Mechanics,${mc_solver},${mc_prec},${dof},${problem_mem},${solution_mem},${mechanics},${disp_stats}" \
        >> "$output"
}

echo "Aggregating mechanics study"

mech_files=("$LOG_DIR_MECH"/run_*.log)

if [ ${#mech_files[@]} -eq 0 ]; then
    echo "WARNING : No file was found in $LOG_DIR_MECH"
else
    for f in "${mech_files[@]}"; do
        process_log "$f" "$OUT_MECH"
    done
fi

echo "Aggregating thermal study"

th_files=("$LOG_DIR_TH"/run_*.log)

if [ ${#th_files[@]} -eq 0 ]; then
    echo "WARNING : No file was found in $LOG_DIR_TH"
else
    for f in "${th_files[@]}"; do
        process_log "$f" "$OUT_TH"
    done
fi

echo "Aggregation finished"
echo "Mechanics CSV : $OUT_MECH"
echo "Thermal CSV   : $OUT_TH"

