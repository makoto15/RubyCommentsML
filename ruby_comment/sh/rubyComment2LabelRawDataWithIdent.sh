#!/bin/sh
#SBATCH -p big
#SBATCH -t 25:0:00
#SBATCH --mem=64G
#SBATCH -o "../slurm-output/repositories2TokenWithCommentDownOnlyRawDataWithIdent50Tokens.txt"

srun hostname
srun sh -c "ruby ../src/rubyComment2LabelRawDataWithIdent.rb"

srun echo "end"
