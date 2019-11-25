#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Nov  7 10:13:08 2019

@author: rakshit
"""

import os
import torch
import pickle
import datetime
from args import parse_args
from opts import train, test
from models import model_1, model_2, model_3, model_4, model_5, model_6, model_7, model_8, model_9
from tensorboardX import SummaryWriter
from DataLoader import splitdata, GIW_readChunk, GIW_readSeq

if __name__=='__main__':
    print('Training ...' )
    args = parse_args()
    args.prec = torch.float64

    if args.modeltype == 1:
        print('Model 1. GIW journal.')
        model = model_1
    elif args.modeltype == 2:
        print('Model 2. GIW journal. Only Eyes.')
        model = model_2
    elif args.modeltype == 3:
        print('Model 3. GIW journal. Only Abs.')
        model = model_3
    elif args.modeltype == 4:
        print('Model 4. GIW journal. F-RNN')
        model = model_4
    elif args.modeltype == 5:
        print('Model 5. GIW journal. Only GiW')
        model = model_5
    elif args.modeltype == 6:
        print('Model 6. GIW journal. Dense->GRU.')
        model = model_6
    elif args.modeltype == 7:
        print('Model 7. GIW journal. Dual task.')
        model = model_7
    elif args.modeltype == 8:
        print('Model 8. GIW journal. Experiments.')
        model = model_8
    elif args.modeltype == 9:
        print('Model 9. ZipNet.')
        model = model_9

    f = open(os.path.join(args.path2data, 'Data.pkl'), 'rb')
    chunk, seq = pickle.load(f)

    trainIdx, validIdx = splitdata(chunk, args.PrTest, args.folds)
    testObj = GIW_readSeq(seq, args.PrTest)
    testloader = torch.utils.data.DataLoader(testObj,
                                             batch_size=1,
                                             num_workers=1)

    # Create summary writer
    now = datetime.datetime.now()
    for k in range(0, args.folds):
        # Path to save model
        args.path2save = os.path.join(os.getcwd(), 'weights', 'PrTest_{}_model_{}_fold_{}.pt'.format(args.PrTest, args.modeltype, k))

        TBwriter = SummaryWriter(os.path.join(os.getcwd(), 'TB.lock', 'kfold_{}_{}_'.format(args.modeltype, k)+str(now)))
        print('Fold: {}'.format(k))
        trainObj = GIW_readChunk(chunk, trainIdx[k], oversample=0, perturbate=True)
        validObj = GIW_readChunk(chunk, validIdx[k], oversample=0, perturbate=False)
        trainloader = torch.utils.data.DataLoader(trainObj,
                                                  shuffle=True,
                                                  batch_size=args.batchsize,
                                                  num_workers=torch.cuda.device_count())
        validloader = torch.utils.data.DataLoader(validObj,
                                                  shuffle=True,
                                                  batch_size=args.batchsize,
                                                  num_workers=torch.cuda.device_count())

        net = []
        net = model().to(args.prec).cuda()
        print(net)
        torch.cuda.manual_seed(32)
        if torch.cuda.device_count() > 1:
            args.multiGPU = 1
            net = torch.nn.DataParallel(net)
            print('Training on {} GPUs'.format(torch.cuda.device_count()))
        else:
            args.multiGPU = 0
            print('Training on 1 GPU.')

        perf_valid, best_model = train(net, trainloader, validloader, testloader, TBwriter, args)
        net.load_state_dict(best_model['net_params'])
        perf_test_run = test(net, testloader, args, True)[1]

        # Load saved best model
        net.load_state_dict(torch.load(args.path2save)['net_params'])
        perf_test_saved = test(net, testloader, args, True)[1]

        print('Best valid kappa: {}'.format(best_model['metric']))
        print('Best saved test kappa: {}'.format(perf_test_saved.getPerf(0, 'kappa')))
        print('Best run test kappa: {}'.format(perf_test_run.getPerf(0, 'kappa')))

        if perf_test_run.getPerf(0, 'kappa') > perf_test_saved.getPerf(0, 'kappa'):
            print('Difference observed. Update the best model.')
            torch.save(best_model, args.path2save)
        else:
            print('Best model already saved.')

