#!/bin/sh
#SBATCH -p big
#SBATCH -t 25:0:00
#SBATCH --mem=64G
#SBATCH -o "../slurm-output/rubyContext2Token.txt"

srun hostname
srun sh -c "ruby ../src/rubyContext2Token.rb"

srun echo "end"
