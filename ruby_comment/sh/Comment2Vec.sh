#!/bin/sh
#SBATCH -p v
#SBATCH --gres=gpu:2
#SBATCH -t 25:0:00
#SBATCH --mem=64G
#SBATCH -o "../slurm-output/Comment2Vec.txt"

srun hostname
srun sh -c "singularity exec --nv /home/u00545/singularity/tensorflow-gpu python /home/u00545/comments/RubyCommentsML/ruby_comment/keras/py/Comment2Vec.py"

srun echo "end"
