#!/bin/sh
#SBATCH -p big
#SBATCH -t 25:0:00
#SBATCH --mem=64G
#SBATCH -o "../slurm-output/rubyContext2TokenRawDataWithIdent.txt"

srun hostname
srun sh -c "ruby ../src/rubyContext2TokenRawDataWithIdent.rb"

srun echo "end"
