import numpy as np
import matlab.engine
import pickle

def __main__():
    strFileName = 'Scene'
    strMatName = 'SceneCameraParameters.mat'
    mateng = matlab.engine.start_matlab()
    CalibObj = mateng.load(strMatName)['SceneCameraParams']
    iMat = np.array(mateng.getfield(CalibObj, 'IntrinsicMatrix'))
    rMat = np.array(mateng.getfield(CalibObj, 'RadialDistortion')).squeeze()
    tMat = np.array(mateng.getfield(CalibObj, 'TangentialDistortion')).squeeze()
    mateng.close()
    camera_matrix = iMat.T
    dist_coefs = np.hstack((rMat[:2], tMat[:2], rMat[2:]))
    dist_coefs = dist_coefs[:, None]
    with open(strFileName + '.pkl', 'wb') as fIO:
        pickle.dump([iMat, dist_coefs], fIO)

__main__()