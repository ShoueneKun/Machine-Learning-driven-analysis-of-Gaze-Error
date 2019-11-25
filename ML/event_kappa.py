# -*- coding: utf-8 -*-
"""
Created on Sat Dec  1 21:41:48 2018

@author: Zhizhuo Yang

Note: This code has been retrofitted to work with our paradigm.
For more information, please refer to the work by Zemblys et al.
"""
import sys

from utils_lib.etdata import ETData
from utils_lib.ETeval import eval_evt
from distutils.dir_util import mkpath

import numpy as np
import pandas as pd
import os,copy
import re
import fnmatch

import scipy.io as scio

def map_func(val, dictionary):
    return dictionary[val] if val in dictionary else val
class_map_func  = np.vectorize(map_func)

#%% set up
#human format coding scheme
classes = [
    0, #undef
    1, #fixation
    2, #pursuit
    3, #saccade

    9  #everything else
]
#internal coding scheme
class_mapper = {k:v for k, v in zip (classes, np.arange(len(classes)))}

#%% Below is ETeval code
def calc_ke(etdata_gt,etdata_pr):
    #leaves original predictions untouched
    _etdata_gt = copy.deepcopy(etdata_gt)
    _etdata_pr = copy.deepcopy(etdata_pr)
    
    #internal class mapping
    _etdata_gt.data['evt'] = class_map_func(_etdata_gt.data['evt'], class_mapper)
    _etdata_pr.data['evt'] = class_map_func(_etdata_pr.data['evt'], class_mapper)
    
    #evaluate per trial
    ke, (evt_overlap, _evt_gt, _evt_pr) = eval_evt(_etdata_gt, _etdata_pr, len(classes))
    ke_single =tuple(ke[:3])
    return ke_single, ke[-1]

#%% convet data from mat file structure to ETData type, and calculate Kappa
def cal_from_mat(data_gt,data_pr):
#def cal_from_mat(data_pr,data_gt):
    T = data_gt['LabelData'][0][0]['T'].squeeze() #timestamps
    labels_gt = data_gt['LabelData'][0][0]['Labels'].squeeze() #ground truth labels
    labels_pr = data_pr['LabelData'][0][0]['Labels'].squeeze() #predicted labels
    ### clean the data ###
    # convert label 5 to label 1 (optokinetic fixation to gaze fixation)
    labels_gt[labels_gt==5] = 1
    labels_pr[labels_pr==5] = 1
    # find overlapped label region between two labelers
    # remove unlabeled region (label==0) and blinks (label==4)
    loc1 = (labels_gt==0) | (labels_gt==4)
    loc2 = (labels_pr==0) | (labels_pr==4)
    loc = loc1 | loc2
    labels_gt = labels_gt[~loc]
    labels_pr = labels_pr[~loc]
    T = T[~loc]
    L = len(T) #length of data
    # create ETData
    etdata_gt_ = np.core.records.fromarrays([T,
                          np.zeros(L), np.zeros(L),
                          np.ones(L), labels_gt],
                          dtype=ETData.dtype)
    etdata_pr_ = np.core.records.fromarrays([T,
                          np.zeros(L), np.zeros(L),
                          np.ones(L), labels_pr],
                          dtype=ETData.dtype)
    etdata_gt_ = np.array(etdata_gt_, dtype=ETData.dtype)
    etdata_pr_ = np.array(etdata_pr_, dtype=ETData.dtype)
    # create instances for ground truth label and predicted label
    etdata_gt = ETData()
    etdata_pr = ETData()
    etdata_gt.load(etdata_gt_,source='array')
    etdata_pr.load(etdata_pr_,source='array')
    ke, kappa_all = calc_ke(etdata_gt,etdata_pr)
    return ke, kappa_all

#%% setup parameters
# human label data
ROOT = '/run/user/1000/gvfs/smb-share:server=mvrlsmb.cis.rit.edu,share=performlab/FinalSet/Labels/'
# classifier data
ROOT_C = os.path.join(os.getcwd(), 'outputs_notest/')
#ROOT_C = os.path.join(os.getcwd(), 'outputs_kfold/')

files = os.listdir(ROOT)
files_c = os.listdir(ROOT_C)
mat_files = fnmatch.filter(files,"*.mat")
mat_files_c = fnmatch.filter(files_c,"*.mat")
FileIdx = []
FileIdx_c = []
results = []
for mat_file in mat_files:
    fileIdx = [int(s) for s in re.findall(r'\d+', mat_file)]
    FileIdx.append(fileIdx)
for mat_file in mat_files_c:
    fileIdx = [int(s) for s in re.findall(r'\d+', mat_file)]
    FileIdx_c.append(fileIdx)
FileIdx.sort()
FileIdx_c.sort()
FileIdx = np.array(FileIdx)
FileIdx_c = np.array(FileIdx_c)
PrIds = np.unique(FileIdx[:, 0])
TrIds = np.unique(FileIdx[:, 1])
FileIdx = pd.DataFrame(FileIdx, columns=['PrIdx','TrIdx','LbrIdx'])
FileIdx_c = pd.DataFrame(FileIdx_c, columns=['PrIdx','TrIdx','LbrIdx','WinSize'])
for person in PrIds:
    for trial in TrIds:
        labelers = FileIdx[(FileIdx['PrIdx']==person)&(FileIdx['TrIdx']==trial)]
        classifiers = fnmatch.filter(mat_files_c,'PrIdx_{0}_TrIdx_{1}_*'.format(person,trial))
        if len(labelers)>1:
            for i in range(len(labelers)):
                # compare with other human labelers
                for j in range(len(labelers)):
                    if i==j: continue
                    lbrId_gt = labelers.iloc[i,2]
                    lbrId_pr = labelers.iloc[j,2]
                    data_gt = scio.loadmat(ROOT+'/PrIdx_{0}_TrIdx_{1}_Lbr_{2}'.format(person,trial,lbrId_gt))
                    data_pr = scio.loadmat(ROOT+'/PrIdx_{0}_TrIdx_{1}_Lbr_{2}'.format(person,trial,lbrId_pr))
                    ke, kappa_all = cal_from_mat(data_gt,data_pr)
                    ke_single = [person, trial, lbrId_gt, lbrId_pr, None, ke, kappa_all]
                    results.append(ke_single)
                # compare classifiers with multiple human labelers
                for cls in classifiers:
                    lbrId_gt = labelers.iloc[i,2]
                    data_gt = scio.loadmat(ROOT+'/PrIdx_{0}_TrIdx_{1}_Lbr_{2}'.format(person,trial,lbrId_gt))
                    data_pr = scio.loadmat(ROOT_C+cls)
                    ke, kappa_all = cal_from_mat(data_gt,data_pr)
                    nums = [int(s) for s in re.findall(r'\d+',cls)]
                    ke_single = [person, trial, lbrId_gt, nums[2],nums[3],ke, kappa_all]
                    results.append(ke_single)
        elif len(labelers)==1:
            # compare classifiers with the only human labeler
            for cls in classifiers:
                lbrId_gt = labelers.iloc[0,2]
                data_gt = scio.loadmat(ROOT+'/PrIdx_{0}_TrIdx_{1}_Lbr_{2}'.format(person,trial,lbrId_gt))
                data_pr = scio.loadmat(ROOT_C+cls)
                ke, kappa_all = cal_from_mat(data_gt,data_pr)
                nums = [int(s) for s in re.findall(r'\d+',cls)]
                ke_single = [person, trial, lbrId_gt, nums[2],nums[3],ke, kappa_all]
                results.append(ke_single)
mat2save = np.array(results)
mat2save[mat2save[:,4]==None,4] = -1
resultsDict = {"PrIdx":mat2save[:,0],"TrIdx":mat2save[:,1],"ref_LbrIdx":mat2save[:,2],"test_LbrIdx":mat2save[:,3],
             "WinSize":mat2save[:,4],"evtKappa":mat2save[:,5], "allKappa":mat2save[:,6]}
scio.savemat('kappaResults.mat', resultsDict)
