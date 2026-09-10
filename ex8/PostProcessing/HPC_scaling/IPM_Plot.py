import pandas as pd
import matplotlib.pyplot as plt

def plot_ipm_analysis(csv_file="ipm_scaling_analysis.csv", output_prefix="IPM_scaling"):
    df = pd.read_csv(csv_file)
    
    ranks = df['ranks'].values
    ranks_str = [str(r) for r in ranks]
    
    df['allreduce_per_rank'] = df['allreduce_count'] / df['ranks']
    df['isend_per_rank'] = df['isend_count'] / df['ranks']

    # 1. Temps Total vs Temps MPI
    plt.figure(figsize=(8, 6))
    plt.plot(ranks_str, df['wallclock_avg_s'], marker='o', label='Temps Total', color='#9400D3', linewidth=2)
    plt.plot(ranks_str, df['mpi_avg_s'], marker='o', label='Temps MPI', color='#D55E00', linewidth=2)
    plt.yscale('log', base=10)
    plt.xlabel('MPI ranks')
    plt.ylabel('Temps (s)')
    plt.grid(True, linestyle=':', alpha=0.6)
    plt.legend(frameon=False)
    plt.tight_layout()
    plt.savefig(f"{output_prefix}_time.png", dpi=300)
    plt.close()

    plt.figure(figsize=(8, 6))
    plt.plot(ranks_str, df['comm_percent'], marker='s', color='#D55E00', linewidth=2)
    plt.xlabel('MPI ranks')
    plt.ylabel('Part des communications MPI (%)')
    plt.ylim(0, 100)
    plt.grid(True, linestyle=':', alpha=0.6)
    plt.tight_layout()
    plt.savefig(f"{output_prefix}_mpi_percent.png", dpi=300)
    plt.close()

    plt.figure(figsize=(8, 6))
    plt.plot(ranks_str, df['mem_avg_gb'], marker='o', color='#009E73', linewidth=2)
    plt.xlabel('MPI ranks')
    plt.ylabel('Mémoire moyenne par processus (Go)')
    plt.ylim(bottom=0)
    plt.grid(True, linestyle=':', alpha=0.6)
    plt.tight_layout()
    plt.savefig(f"{output_prefix}_memory.png", dpi=300)
    plt.close()

    plt.figure(figsize=(8, 6))
    plt.plot(ranks_str, df['allreduce_per_rank'], marker='o', label='MPI_Allreduce par cœur', color='#56B4E9')
    plt.plot(ranks_str, df['isend_per_rank'], marker='^', label='MPI_Isend par cœur', color='#E69F00')
    plt.yscale('log', base=10)
    plt.xlabel('MPI ranks')
    plt.ylabel('Nombre d\'appels moyen par processus')
    plt.grid(True, linestyle=':', alpha=0.6)
    plt.legend(frameon=False)
    plt.tight_layout()
    plt.savefig(f"{output_prefix}_network_calls.png", dpi=300)
    plt.close()

    print(f"Graphiques générés avec le préfixe '{output_prefix}'")

if __name__ == '__main__':
    plot_ipm_analysis()