# Gaze-In-Wild dataset

This repository contains the code used to process, generate and maintain the GIW dataset. The GIW dataset contains the following datastreams:

* Eye-in-head vector: Using the Pupil labs tracker, we collected, filtered and upmsampled gaze to 300Hz. This dataset contains left, right and cyclopean gaze vectors.

* Head pose: Using a 6-axis IMU MPU-6050, we collected head pose measured from the forehead. Head pose is minimally filtered and upsampled to 300Hz. As is common with IMUs, situations wherein large drifts occured were manually corrected using approximations.

* Head vector: We calculate the head vector as the unit vector outward from the forehead.

* Depth data: We used a ZED depth camera to capture depth information at 1080p and 30Hz. A checkerboard is used to registed the ZED camera and Pupil labs scene camera into the same coordination space. This enables us to compute a 3D Point-of-Regard.

* Labels: Each stream is labeled by one or multiple human annotaters. Certain trials do not contain labels.

All streams are time synced and provided in a simple data structure, henceforth called, [ProcessData], which is a MATLAB structure. Each [ProcessData] may or may not have a corresponding [LabelData] which holds information about the labels.

To download all data files, please visit the project [webpage](http://www.cis.rit.edu/~rsk3900/gaze-in-wild/).

The raw data is well over 14TB and will not be provided over the internet. Please contact the authors for specific information or access to the raw data.

ELC metric can be found [here](https://bitbucket.org/GeorgeARYoung/elc_metric/src/master/)

----------------------------
## Basic instructions:

Please clone this repository and modify the path.json file.<br/>
path2repo: Paste the full path to the cloned repository.<br/>
path2data: Paste the full path to the folder containing ProcessData and LabelData<br/>
path2vids: Paste the full path to the folder containing the videos.<br/>

----------------------------
## Handy tools:

To easily get started, we provide access to five utilities to rapidly visualize the data.

#### PlotLabels.m
Unless manually choosing a particular subject, this script will plot all labels overlaid on top of head and eye-in-head velocities.

#### GIWapp

This is a MATLAB app designed to strafe through the vast amount of data rapidly.
Please following these instructions;
1. Open the GIWapp.
2. Click the set path button. This script will look for path.json file.
3. Select subject. Please wait for it to finish loading (approx 10 to 20 seconds).
4. Select labeller.

#### RapidStats.m
This script will rapidly plot all global statistics noted in the GIW paper.

#### PlotResults.m
This script will plot all ML related figures and generate multiple tables in the Results folder. Note that you would need to download the trained models from here and place them in their appropriate folders.

#### LabelMe.m
This script runs the labeller.m script which opens the labeller available to the human annotaters. If you wish to reuse this script, please do so with care. Note that Mathworks recommends moving to apps instead of GUIDE.

---------------------------
## ML:

To fully reproduce our baseline results, you will need to create staging data. This staging data is used to rapidly read information to and from Python and MATLAB. Note that you will need to change paths where indicated in each individual code file. Future work may include simplying the code base if requested by researchers. All machine learning operations for this project are conducted with the aid of SLURM, a job scheduling package retrofitted for [Research and Computing](https://www.rit.edu/researchcomputing/) at RIT. 

# Result replication
If you wish to replicate results by training from scratch, please run all files listed below for every testing condition.

Run "ML/RF/AssimilateDataset.m". This should produce "ML/RF/Data/Data_RF.mat" which is used to train seperate RF models for each individual subject. Note that RF models are very large and consume significant RAM. This makes them difficult to deploy. To begin training RF models, run the script "ML/RF_Model.m".

Run "ML/DeepModels/AssimilateDataset.m". This should produce a file named "ML/DeepModels/Data/Data.mat". To boost training, this file is further optimized using the script "ML/DeepModels/ConvMat2Pkl.py". To train all models from scratch, please follow script "main_kfold.py". Note that this process is time intensive and would be easier if you have access to SLURM (if you do, please run "ML/DeepModels/submit_jobs_kfold.sh").

Pretrained models are available [here](https://drive.google.com/open?id=176sbXB3sXF-gJqZEhWEV-OxQtgtXKq_P).

---------------------------
If you liked our work or wish to provide any feedback, please email me at rsk3900@rit.edu.

If you use this codebase or dataset in your work, please cite this [paper](https://arxiv.org/abs/1905.13146).
