#!/bin/bash
#SBATCH --account=def-gonzalez
#SBATCH --job-name=block3 
#SBATCH --output=slurm-block3.out 
#SBATCH --nodes=1               
#SBATCH --ntasks=1               
#SBATCH --cpus-per-task=1        
#SBATCH --mem-per-cpu=64G      
#SBATCH --time=04:00:00         


module load cuda
module load julia/1.8.5
module load cudnn 

export JULIA_DEPOT_PATH="/project/def-gonzalez/mcatchen/JuliaEnvironments/COBees"
export CLUSTER="true"

julia main.jl