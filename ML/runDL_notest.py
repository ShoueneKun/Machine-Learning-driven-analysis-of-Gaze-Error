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
import numpy as np
import scipy.io as scio
from DeepModels.args import parse_args
from DeepModels.opts import test
from DeepModels.models import *
from DeepModels.DataLoader import GIW_readSeq

'''
WARNING
This is a slow process
'''

if __name__=='__main__':
    args = parse_args()
    args.prec = torch.float64
    path2weights = '/home/rakshit/sporc/gaze-in-wild/ML/DeepModels/weights'
    f = open(os.path.join(os.path.join(os.getcwd(), 'DeepModels', 'Data'), 'Data.pkl'), 'rb')
    seq = pickle.load(f)[1]
    ID_info = np.stack(seq['id'], axis=0)

    PrList = [1, 2, 3, 6, 8, 9, 12, 16, 17, 22]
    ModelPresent = list(range(0, 9))
    ModelPresent = [x for x in ModelPresent if x not in [6, 7]] # Remove these from analysis
    ModelID = [14, 24, 34, 44, 54, 64, 74, 84, 94]
    for PrIdx in PrList:
        print('Evaluating PrIdx: {}'.format(PrIdx))
        testObj = GIW_readSeq(seq, PrIdx)
        testloader = torch.utils.data.DataLoader(testObj,
                                             batch_size=1,
                                             num_workers=1,
                                             shuffle=False)
        for model_num in ModelPresent:
            print('eval model: {}'.format(model_num+1))
            model = eval('model_{}'.format(model_num+1))
            net = model().cuda().to(args.prec)
            fold = 20 # Hard coded for no test condition
            path2weight = os.path.join(path2weights, 'PrTest_{}_model_{}_fold_{}.pt'.format(int(PrIdx), model_num+1, fold))
            if os.path.exists(path2weight):
                try:
                    net.load_state_dict(torch.load(path2weight)['net_params'])
                except:
                    print('Dict mismatch. Training not complete yet.')
                    continue
                _, _, Y, id_trIdx = test(net, testloader, args, talk=True)
                assert len(Y) == testObj.idx.shape[0], "Something went wrong"

                for i, y in enumerate(Y):
                    TrIdx = id_trIdx[i, 1]
                    fsave = os.path.join(os.getcwd(),
                                         'outputs_notest',
                                         'PrIdx_{}_TrIdx_{}_Lbr_{}_WinSize_0.mat'.format(int(PrIdx), int(TrIdx), ModelID[model_num]))
                    scio.savemat(fsave, {'Y': y.reshape(-1, 1),
                                         'PrIdx': PrIdx,
                                         'TrIdx': TrIdx,
                                         'Lbr': ModelID[model_num]})
            else:
                print('Weights for this model does not exist')



