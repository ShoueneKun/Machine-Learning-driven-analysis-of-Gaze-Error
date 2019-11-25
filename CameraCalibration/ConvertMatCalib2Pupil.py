import sys
import numpy as np
import matlab.engine
import os

# Instructions:
# Install MATLAB and Python bindings. Instructions are easy to follow from Mathworks website.

# Change path to wherever you have saved HelperFunctions.py
sys.path.append('/home/rakshit/Documents/MATLAB/event_detection_mark_1/SupportFunctions/PythonSupport')
from HelperFunctions import load_object, save_object

def __main__():
    # Change name to whatever you want.
    # world - world camera
    # eye0 - right camera (guessing, please verify)
    # eye1 - left camera (guessing, please verify)
    strFileName = 'world'
    strMatName = 'SceneCameraParameters.mat'

    mateng = matlab.engine.start_matlab()
    CalibObj = mateng.load(strMatName)['SceneCameraParams'] # Change this string to whatever your variable is named
    iMat = np.array(mateng.getfield(CalibObj, 'IntrinsicMatrix'))
    rMat = np.array(mateng.getfield(CalibObj, 'RadialDistortion')).squeeze()
    tMat = np.array(mateng.getfield(CalibObj, 'TangentialDistortion')).squeeze()

    mateng.close()

    camera_matrix = iMat.T.tolist()
    dist_coefs = np.hstack((rMat[:2], tMat[:2], rMat[2:]))
    dist_coefs = dist_coefs[:, None]
    dist_coefs = dist_coefs.tolist()
    cam_type = 'radial'
    resolution = [1920, 1080]
    
    data = {}
    data['(1920, 1080)'] = {}
    data['version'] = 1

    fields = ('cam_type', 'camera_matrix', 'dist_coefs', 'resolution')
    for i in fields:
        data['(1920, 1080)'][i] = locals()[i]

    print(data)
    directory = os.getcwd()
    save_path = os.path.join(directory, '{}.intrinsics'.format(strFileName))
    save_object(data, save_path)

__main__()