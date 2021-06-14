#!/bin/sh
#SBATCH -p v
#SBATCH --gres=gpu:1
#SBATCH -t 25:0:00
#SBATCH --mem=4G
# #SBATCH -o "/slurm.txt"

srun hostname

srun sh -c "singularity exec --nv /home/u00545/singularity/tensorflow-gpu python test.py "
