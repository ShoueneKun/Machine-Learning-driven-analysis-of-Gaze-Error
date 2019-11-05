#!/bin/bash -l
#SBATCH --job-name=RF_train
#SBATCH --output=rc_log/RF.out
#SBATCH --error=rc_log/RF.err
#SBATCH --mail-user rsk3900@rit.edu
#SBATCH --mail-type=ALL
#SBATCH --mem=360G
#SBATCH --nodes=1
#SBATCH -t 2-4:0
#SBATCH -p tier3 -A riteyes -n 36

# Loading MATLAB
module load matlab
matlab -nodesktop -nosplash -nodisplay < RF_Model.m
