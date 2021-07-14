#!/bin/sh
#SBATCH -p big
#SBATCH -t 25:0:00
#SBATCH --mem=64G
#SBATCH -o "../slurm-output/findDebug.txt"

srun hostname
srun sh -c "ruby ../src/finddebug.rb"

srun echo "end"
~               
