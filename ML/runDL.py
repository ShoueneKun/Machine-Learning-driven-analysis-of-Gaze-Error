#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Nov 16 16:06:05 2019

@author: rakshit
"""

'''
This script runs all K-models for each person per model type. The output from
the best model is saved as PrIdx_{}_TrIdx_{}_Lbr_{model_ID}. Each model_ID is
associated with a certain condition.
'''

import os
import torch
import pickle
import scipy.io as scio
from DeepModels.opts import test
from DeepModels.models import *
from DeepModels.DataLoader import GIW_readSeq

if __name__=='__main__':
    path2weights = '/home/rakshit/sporc/gaze-in-wild/ML/DeepModels/weights'
    f = open(os.path.join(os.path.join(os.getcwd(), 'DeepModels', 'Data'), 'Data.pkl'), 'rb')
    seq = pickle.load(f)[1]

    PrList = [1, 2, 3, 8, 9, 12, 16, 17, 22]
    ModelPresent = list(range(0, 7))
    ModelID = [14, 24, 34, 44, 54, 64, 74]
    for PrIdx in PrList:
        print('Evaluating PrIdx: {}'.format(PrIdx))
        testObj = GIW_readSeq(seq, PrIdx)
        testloader = torch.utils.data.DataLoader(testObj,
                                             batch_size=1,
                                             num_workers=1,
                                             shuffle=False)
        for model_num in ModelPresent:
            model = eval('model_{}'.format(model_num+1))
            net = model().cuda().to(torch.float32)
            for fold in range(0,5):
                path2weight = os.path.join(path2weights, 'PrTest_{}_model_{}_fold_{}.pt'.format(PrIdx, model_num+1, fold))
                if os.path.exists(path2weight):
                    net.load_state_dict(torch.load(path2weight)['net_params'])
                    Y = test(net, testloader, talk=True)[2]
                    assert len(Y) == testObj.idx.shape[0], "Something went wrong"

                    for i, y in enumerate(Y):
                        TrIdx = testObj.idx[i, 1] # TrIdx
                        fsave = os.path.join(os.getcwd(),
                                             'outputs',
                                             'PrIdx_{}_TrIdx_{}_Lbr_{}_WinSize_0'.format(PrIdx, TrIdx, ModelID[model_num]))
                        scio.savemat({'Labels': y.reshape(-1, 1),
                                      'PrIdx': PrIdx,
                                      'TrIdx': TrIdx}, appendmat=True)
                else:
                    print('Weights for this model does not exist')



