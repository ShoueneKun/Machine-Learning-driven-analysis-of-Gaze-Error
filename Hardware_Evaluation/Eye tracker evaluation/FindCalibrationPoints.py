import numpy as np
import matlab.engine
import pandas as pd
import json
import sys
import os
from scipy.spatial.distance import cdist

mateng = matlab.engine.start_matlab()
print("Engine started")

PATH_TO_REPO = '/home/rakshit/Documents/MATLAB/gaze-in-wild'

PathDict = json.load(open(os.path.join(PATH_TO_REPO, 'path.json')))
PATH_TO_DATA = PathDict['path2data']
PATH_TO_INTRINSICS = os.path.join(PATH_TO_REPO, 'Camera_Calibration')

# Remove participants 7 and 21 from analysis
list_names = list(range(1, 24))
list_names.remove(7)
list_names.remove(21)

sys.path.append(os.path.join(PATH_TO_REPO, 'SupportFunctions', 'PythonSupport'))
from HelperFunctions import load_object, findClosest
from transformations import random_rotation_matrix, quaternion_matrix

CameraInfo = mateng.load(os.path.join(PATH_TO_INTRINSICS, 'SceneCameraParameters.mat'))
print('Intrinsics loaded')

IntrinsicMatrix = np.array(mateng.getfield(CameraInfo['SceneCameraParams'], 'IntrinsicMatrix'))

mateng.close()
print("Engine closed")

AngErr = []

def getAngError(v1, v2, I):
    v1 = np.append(v1, 1)
    v2 = np.append(v2, 1)
    v1 = v1.dot(np.linalg.inv(I))
    v2 = v2.dot(np.linalg.inv(I))
    v1 = v1/np.linalg.norm(v1) # Normalize
    v2 = v2/np.linalg.norm(v2) # Normalize
    angles_rad = v1.dot(v2)
    angles_deg = np.rad2deg(np.arccos(angles_rad))
    return angles_deg

EccPerf = dict()
EccPerf['PrName'] = []
EccPerf['Tr'] = []
EccPerf['AngErr'] = []
EccPerf['Ecc'] = []

Perf = dict()
Perf['PrName'] = []
Perf['Tr'] = []
Perf['MAngErr'] = []
Perf['CentralPt'] = []

for PrName in list_names:
    PATH_TO_PR = os.path.join(PATH_TO_DATA, PrName)
    TrList = os.listdir(PATH_TO_PR)
    for Tr in TrList:

        CalibErr = 0.0

        PATH_TO_GAZE = os.path.join(PATH_TO_PR, str(Tr) ,'Gaze')
        calib_data = load_object(os.path.join(PATH_TO_GAZE,
                                              'offline_data',
                                              'offline_calibration_gaze'), allow_legacy=False)['manual_ref_positions']

        if len(calib_data) != 0:
            gaze_data = pd.read_csv(os.path.join(PATH_TO_GAZE, 'exports' ,'gaze_positions.csv'))

            # Extract time stamps from gaze data
            T = np.array(gaze_data.loc[:, 'timestamp'])

            calib_pts = []
            for i in range(0, len(calib_data)):
                calibpt_px = calib_data[i]['screen_pos']
                calib_pts.append(calibpt_px)

            centralpt_px = np.mean(np.array(calib_pts), 0)
            print(centralpt_px)

            for i in range(0, len(calib_data)):
                calibpt_px = calib_data[i]['screen_pos']
                loc = findClosest(calib_data[i]['timestamp'], T)
                gazept_nm = np.array(gaze_data.loc[loc, ['norm_pos_x', 'norm_pos_y']])
                gazept_nm[1] = 1 - gazept_nm[1]
                gazept_px = gazept_nm*np.array([1920, 1080])
                AngErr = getAngError(gazept_px, calibpt_px, IntrinsicMatrix)

                # It is not fair to measure the calibration from the eyetracker
                # center. Hence, we measure it from the center of all
                # calibration points noted.

                #centralpt_px = np.array([1920, 1080])/2
                Ecc = getAngError(centralpt_px, calibpt_px, IntrinsicMatrix) # Eccentricity
                CalibErr += AngErr

                EccPerf['PrName'] = EccPerf['PrName'] + [PrName]
                EccPerf['Tr'] = EccPerf['Tr'] + [Tr]
                EccPerf['AngErr'] = EccPerf['AngErr'] + [AngErr]
                EccPerf['Ecc'] = EccPerf['Ecc'] + [Ecc]

            Perf['PrName'] = Perf['PrName'] + [PrName]
            Perf['Tr'] = Perf['Tr'] + [Tr]
            Perf['MAngErr'] = Perf['MAngErr'] + [CalibErr/len(calib_data)]
            Perf['CentralPt'] = Perf['CentralPt'] + [centralpt_px]

            print('Person: {}. Tr: {}. AngErr: {}'.format(PrName, Tr, CalibErr/len(calib_data)))

df = pd.DataFrame(data=EccPerf)
df.to_csv('ETGCalib_ecc.csv', index=False)
df = pd.DataFrame(data=Perf)
df.to_csv('ETGCalib.csv', index=False)