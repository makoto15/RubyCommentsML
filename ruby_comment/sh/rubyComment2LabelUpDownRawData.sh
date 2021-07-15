#!/bin/sh
#SBATCH -p big
#SBATCH -t 25:0:00
#SBATCH --mem=64G
#SBATCH -o "../slurm-output/repositories2TokenWithCommentUpDownRawData50Tokens.txt"

srun hostname
srun sh -c "ruby ../src/rubyComment2LabelUpDownRawData.rb"

srun echo "end"
