#!/bin/bash

spack load opencv ^python@3
spack load /ou2ujbv # Load pytorch by hash
spack load /5gjrsa2 # Load torchvision by hash
spack load /b4lfddj # Load scipy
spack load /5kmm4sh # Load matplotlib
spack load py-scikit-image ^python@3 # Load image manipulation library
spack load py-scikit-learn@0.21 # Load sklearn for metrics
spack load py-tensorboardx

baseJobName="GIW"
model_num="1"

echo "Submitting jobs ..."
declare -a PrTest=("1" "2" "3" "8" "9" "12" "16" "17" "22")

for PrIdx in "${PrTest[@]}"
do
    echo "Submitting $PrIdx"
    echo -e "#!/bin/bash \n python3 main.py --PrTest=${PrIdx} --model=${model_num} --lr=1e-5 --modeltype=1 --batchsize=32 --epochs=1000 &\n python3 main.py --PrTest=${PrIdx} --model=${model_num} --lr=1e-5 --modeltype=1 --batchsize=32 --epochs=1000 &" > command.lock
    sbatch -J ${baseJobName} --output="rc_log/${PrIdx}.o" --error="rc_log/${PrIdx}.e" --mem=16G -n 1 -t 2-4:0:0 -p tier3 -A riteyes --gres=gpu:p4:1 --mail-user=rsk3900@rit.edu --mail-type=ALL command.lock
done