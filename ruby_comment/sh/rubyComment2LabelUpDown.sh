#!/bin/sh
#SBATCH -p big
#SBATCH -t 25:0:00
#SBATCH --mem=64G
#SBATCH -o "../slurm-output/repositories2TokenWithCommentUpDown50Tokens.txt"

srun hostname
srun sh -c "ruby ../src/rubyComment2LabelUpDown.rb"

srun echo "end"
