#!/bin/bash

# Author: Rakshit Kothari
# Credit: Sanketh Moudgalya for sharing bash script

spack load opencv ^python@3
spack load /home/rakshit/sporc/gaze-in-wild/ML/DeepModels/submit_1_job.sh # Load pytorch by hash
spack load /5gjrsa2 # Load torchvision by hash
spack load /b4lfddj # Load scipy
spack load /5kmm4sh # Load matplotlib
spack load py-scikit-image ^python@3 # Load image manipulation library
spack load py-scikit-learn@0.21 # Load sklearn for metrics
spack load py-tensorboardx

PrIdx="12"
model_num="2"
baseJobName="CC_${PrIdx}_${model_num}"

echo "Submitting 1 job"

echo -e "#!/bin/bash \n python3 main_kfold.py --PrTest=${PrIdx} --lr=1e-4 --modeltype=${model_num} --batchsize=64 --epochs=150" > command.lock
sbatch -J ${baseJobName} --output="rc_log/${PrIdx}_${model_num}.o" --error="rc_log/${PrIdx}_${model_num}.e" --mem=16G -n 1 -t 0-8:0:0 -p tier3 -A riteyes --gres=gpu:1 --mail-user=rsk3900@rit.edu --mail-type=ALL command.lock