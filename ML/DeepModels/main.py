#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Nov  7 10:13:08 2019

@author: rakshit
"""

import os
import torch
import pickle
from args import parse_args
from opts import train, test
from models import model_1, model_2
from DataLoader import splitdata, GIW_readChunk, GIW_readSeq

if __name__=='__main__':
    print('Training ...' )
    args = parse_args()

    if args.modeltype == 1:
        print('Model 1. GIW journal.')
        model = model_1
    elif args.modeltype == 2:
        print('Model 2. Dense->GRU')
        model = model_2

    f = open(os.path.join(args.path2data, 'Data.pkl'), 'rb')
    chunk, seq = pickle.load(f)

    trainIdx, validIdx = splitdata(chunk, args.PrTest, args.folds)
    testObj = GIW_readSeq(seq, args.PrTest)
    testloader = torch.utils.data.DataLoader(testObj,
                                             batch_size=1,
                                             num_workers=1)

    for k in range(0, args.folds):
        print('Fold: {}'.format(k))
        trainObj = GIW_readChunk(chunk, trainIdx[k])
        validObj = GIW_readChunk(chunk, validIdx[k])
        trainloader = torch.utils.data.DataLoader(trainObj,
                                                  shuffle=True,
                                                  batch_size=args.batchsize,
                                                  num_workers=torch.cuda.device_count())
        validloader = torch.utils.data.DataLoader(validObj,
                                                  shuffle=True,
                                                  batch_size=args.batchsize,
                                                  num_workers=torch.cuda.device_count())

        net = model().cuda().to(torch.float32)
        torch.cuda.manual_seed(32)
        if torch.cuda.device_count() > 1:
            args.multiGPU = 1
            net = torch.nn.DataParallel(net)
            print('Training on {} GPUs'.format(torch.cuda.device_count()))
        else:
            args.multiGPU = 0
            print('Training on 1 GPU.')

        net, perf_valid = train(net, trainloader, validloader, args)
        perf_test = test(net, testloader, args)
        print('Best valid kappa: {}'.format(perf_valid['kappa']))
        print('Best test kappa: {}'.format(perf_test['kappa']))

        if args.multiGPU:
            print('Moving to single GPU.')
            print('Saving ...')
            state_dict = net.module.state_dict()
        else:
            print('Saving ...')
            state_dict = net.state_dict()

        path2save = os.path.join(os.getcwd(), 'weights', 'model_{}_fold_{}.pt'.format(args.modeltype, k))
        torch.save(state_dict.cpu(), path2save)

