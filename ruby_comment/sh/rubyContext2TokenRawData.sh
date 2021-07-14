#!/bin/sh
#SBATCH -p big
#SBATCH -t 25:0:00
#SBATCH --mem=64G
#SBATCH -o "../slurm-output/rubyContext2TokenRawData.txt"

srun hostname
srun sh -c "ruby ../src/rubyContext2TokenRawData.rb"

srun echo "end"
