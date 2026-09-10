import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.ticker import LogLocator, FuncFormatter

def custom_log_format(y, pos):
    return f"{y:g}"

def plot_scaling_data(csv_file, output_prefix="ThMc_AMG_plot"):
    # Read the data
    df = pd.read_csv(csv_file)
    df = df[df['total'] > 0].copy()
    
    # Process for each refinement level
    for ref_level in df['ref_level'].unique():
        df_ref = df[df['ref_level'] == ref_level].copy()
        df_ref = df_ref.sort_values(by='proc')
        
        ranks = df_ref['proc'].values
        ranks_str = [str(r) for r in ranks]
        
        # Calculate base values early to use in the time distribution plot
        base_proc = ranks[0]
        base_time_total = df_ref.iloc[0]['total']
        base_time_thermal = df_ref.iloc[0]['thermal_mean']
        base_time_mechanics = df_ref.iloc[0]['mechanics_mean']
        
        # Calculate Memory per proc (GB)
        mem_problem_per_proc = df_ref['problem_footprint_GB'].values / ranks
        mem_solution_per_proc = df_ref['solution_footprint_GB'].values / ranks
        
        # 1. Memory Plot
        plt.figure(figsize=(8, 6))
        plt.plot(ranks_str, mem_problem_per_proc, marker='o', label='Problem', color='#009E73')
        plt.plot(ranks_str, mem_solution_per_proc, marker='o', label='Solution', color='#56B4E9')
        plt.axhline(y=1.8, color='red', linestyle='--', linewidth=2, label='Hardware limit (1.8 GB)')
        
        plt.xlabel('MPI ranks')
        plt.ylabel('Memory per proc (GB)')
        plt.ylim(bottom=0)
        plt.grid(True, linestyle=':', alpha=0.6)
        plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left', frameon=False)
        plt.tight_layout()
        plt.savefig(f"{output_prefix}_ref{ref_level}_memory.png")
        plt.close()
        
        # 2. Time Distribution Plot
        ideal_time_total = base_time_total * (base_proc / ranks)
        
        plt.figure(figsize=(8, 6))
        plt.plot(ranks_str, df_ref['total'], marker='o', label='Total', color='#9400D3')
        plt.plot(ranks_str, ideal_time_total, linestyle='--', label='Ideal Total', color='#9400D3', alpha=0.5)
        plt.plot(ranks_str, df_ref['thermal_mean'], marker='o', label='Thermal Solve', color='#009E73')
        plt.plot(ranks_str, df_ref['mechanics_mean'], marker='o', label='Mechanics Solve', color='#D55E00')
        plt.plot(ranks_str, df_ref['mesh_load_mean'], marker='o', label='Mesh load', color='#56B4E9')
        plt.plot(ranks_str, df_ref['mesh_ctor_mean'], marker='o', label='Mesh constructor', color='#E69F00')
        plt.plot(ranks_str, df_ref['fed_ctor_mean'], marker='o', label='FED constructor', color='#F0E442')
        
        plt.yscale('log')
        plt.xlabel('MPI ranks')
        plt.ylabel('Time (s)')
        
        ax = plt.gca()
        ax.yaxis.set_major_locator(LogLocator(base=2.0))
        ax.yaxis.set_major_formatter(FuncFormatter(custom_log_format))
        
        plt.grid(True, linestyle=':', alpha=0.6)
        plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left', frameon=False)
        plt.tight_layout()
        plt.savefig(f"{output_prefix}_ref{ref_level}_distribution.png")
        plt.close()
        
        # 3. Efficiency Plot
        measured_speedup_total = base_time_total / df_ref['total'].values * base_proc
        measured_speedup_thermal = base_time_thermal / df_ref['thermal_mean'].values * base_proc
        measured_speedup_mechanics = base_time_mechanics / df_ref['mechanics_mean'].values * base_proc
        
        efficiency_total = measured_speedup_total / ranks
        efficiency_thermal = measured_speedup_thermal / ranks
        efficiency_mechanics = measured_speedup_mechanics / ranks
        
        plt.figure(figsize=(8, 6))
        plt.plot(ranks_str, efficiency_total, marker='o', label='Efficiency (Total)', color='#9400D3')
        plt.plot(ranks_str, efficiency_thermal, marker='o', label='Efficiency (Thermal)', color='#009E73')
        plt.plot(ranks_str, efficiency_mechanics, marker='o', label='Efficiency (Mechanics)', color='#D55E00')
        
        plt.xlabel('MPI ranks')
        plt.ylabel('Parallel efficiency (-)')
        plt.ylim(bottom=0)
        plt.grid(True, linestyle=':', alpha=0.6)
        plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left', frameon=False)
        plt.tight_layout()
        plt.savefig(f"{output_prefix}_ref{ref_level}_efficiency.png")
        plt.close()
        
        # 4. Strong Scaling Plot
        plt.figure(figsize=(8, 6))
        plt.plot(ranks_str, measured_speedup_total, marker='o', label='Measured (Total)', color='#9400D3')
        plt.plot(ranks_str, measured_speedup_thermal, marker='o', label='Measured (Thermal)', color='#009E73')
        plt.plot(ranks_str, measured_speedup_mechanics, marker='o', label='Measured (Mechanics)', color='#D55E00')
        plt.plot(ranks_str, ranks, linestyle='--', label='Ideal', color='#009E73')
        
        plt.yscale('log', base=2)
        plt.xlabel('MPI ranks')
        plt.ylabel('Speedup (-)')
        
        ax = plt.gca()
        ax.yaxis.set_major_formatter(FuncFormatter(custom_log_format))
        
        plt.grid(True, linestyle=':', alpha=0.6)
        plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left', frameon=False)
        plt.tight_layout()
        plt.savefig(f"{output_prefix}_ref{ref_level}_strongscaling.png")
        plt.close()

        # Affichage des valeurs min et max dans la console
        print(f"\nStatistiques pour le raffinement {ref_level}")
        print(f"Thermique : Min = {thermal_pct.min():.2f}% | Max = {thermal_pct.max():.2f}%")
        print(f"Mécanique : Min = {mechanics_pct.min():.2f}% | Max = {mechanics_pct.max():.2f}%")

        plt.figure(figsize=(10, 6))
        plt.stackplot(ranks_str, 
                      thermal_pct, 
                      mechanics_pct, 
                      other_pct,
                      labels=['Thermique', 'Mécanique', 'Autres'],
                      colors=['#009E73', '#D55E00', '#CCCCCC'],
                      alpha=0.85)
        
        plt.xlabel('Rangs MPI')
        plt.ylabel('Proportion du temps total (%)')
        plt.xlim(ranks_str[0], ranks_str[-1])
        plt.ylim(0, 100)
        plt.legend(bbox_to_anchor=(1.02, 1), loc='upper left', frameon=False)
        plt.tight_layout()
        plt.savefig(f"{output_prefix}_ref{ref_level}_percentages_stacked.png")
        plt.close()

if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1:
        plot_scaling_data(sys.argv[1])
    else:
        print("Usage: python plot_script.py <aggregation.csv>")