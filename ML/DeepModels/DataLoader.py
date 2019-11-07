#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Nov  6 15:09:27 2019

@author: rakshit
"""
import os
import pickle
import numpy as np
from args import parse_args
from torch.utils.data import Dataset
from sklearn.model_selection import StratifiedKFold

def splitdata(chunk, PrTest, folds):
    ID = np.stack(chunk['id'], axis=0)
    freq = np.stack(chunk['freq'], axis=0)
    stratInd = freq[:, 1] > 0.0 # If pursuit is present, flag is 1
    train_loc = np.where(ID[:, 0] != PrTest)[0]
    skf = StratifiedKFold(n_splits=folds)
    trainIdx = []
    validIdx = []
    for train_index, valid_index in skf.split(train_loc, stratInd[train_loc]):
        trainIdx.append(train_index)
        validIdx.append(valid_index)
    return (trainIdx, validIdx)

class GIW_readChunk(Dataset):
    def __init__(self, Chunk, Idx):
        self.data = Chunk
        self.idx = Idx

    def __len__(self):
        return len(self.idx)

    def __getitem__(self, itr):
        idx = self.idx[itr]
        vel = self.data['vel'][idx]
        w = self.data['weights'][idx]
        target = self.data['targets'][idx]
        return vel, w, target

class GIW_readSeq(Dataset):
    def __init__(self, Seq, PrTest):
        self.data = Seq
        self.idx = np.where(np.stack(Seq['id'], axis=0)[:, 0] == PrTest)[0]

    def __len__(self):
        return len(self.idx)

    def __getitem__(self, itr):
        idx = self.idx[itr]
        vel = self.data['vel'][idx]
        w = self.data['weights'][idx]
        target = self.data['targets'][idx]
        return vel, w, target

if __name__=='__main__':
    args = parse_args()
    f = open(os.path.join(args.path2data, 'Data.pkl'), 'rb')
    chunk, seq = pickle.load(f)
    trainIdx, validIdx = splitdata(chunk, args.PrTest, args.folds)
    testObj = GIW_readSeq(seq, args.PrTest)
    trainObj = GIW_readChunk(chunk, trainIdx[0])
    validObj = GIW_readChunk(chunk, validIdx[0])


