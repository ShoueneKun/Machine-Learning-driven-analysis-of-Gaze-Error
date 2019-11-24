#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Nov  6 15:09:27 2019

@author: rakshit
"""
import os
import torch
import pickle
import numpy as np
from args import parse_args
from torch.utils.data import Dataset
from sklearn.model_selection import KFold

def noiseAdd(x):
    # Input is a NxM matrix. Each column represents an eye, head or GIW
    # velocity vector. This function calculates the RMS value of each channel
    # and adds AWGN between [0, 0.2]. Each column is treated as an
    # independant signal source. Hence, they'll have different noise levels.
    SgnShape = x.shape
    for i in range(0, SgnShape[1]):
        RMS = torch.pow(torch.mean(torch.pow(x[:, i], 2)), 0.5)
        NoiseRMS = np.random.rand(1)*0.2*RMS.numpy() # Noise should be upto 0.2 RMS
        NoiseSgn = np.random.normal(0, NoiseRMS**0.5, size=(SgnShape[0], ))
        x[:, i] = x[:, i] + torch.from_numpy(NoiseSgn).type(x.type())
    return x

def splitdata(chunk, PrTest, folds):
    ID = np.stack(chunk['id'], axis=0)
    freq = np.stack(chunk['freq'], axis=0)
    train_loc = np.where(ID[:, 0] != PrTest)[0] # Ignore chunks from testing subject
    if folds!=0:
        # Only split locations without pursuits.
        # Reasoning: Pursuit samples are rare. Stratification can cause shifts
        # in behavior. Best to avoid.

        # Find all pursuit locations
        loc_Pur = np.intersect1d(np.where(freq[:, 1] >= 0.05)[0], train_loc)

        # Find all locations without pursuits and intersect with locations without the testing person
        loc_toSplit = np.intersect1d(np.where(freq[:, 1] < 0.05)[0], train_loc)

        trainIdx = []
        validIdx = []
        kf = KFold(shuffle=True, n_splits=folds)
        for train_index, valid_index in kf.split(loc_toSplit):
            temp = np.append(loc_toSplit[train_index], loc_Pur)
            trainIdx.append(temp)
            temp = np.append(loc_toSplit[valid_index], loc_Pur)
            validIdx.append(temp)

        return (trainIdx, validIdx)
    else:
        trainIdx = train_loc.tolist()
        print('No folds selected. Validation only.')
        return (trainIdx, [])


class GIW_readChunk(Dataset):
    def __init__(self, Chunk, Idx, oversample=0.0, perturbate=False):
        self.perturbate = perturbate
        self.data = Chunk
        if oversample > 0.0:
            Idx = self.upsample(Idx, oversample)
        self.idx = Idx

    def __len__(self):
        return len(self.idx)

    def __getitem__(self, itr):
        idx = self.idx[itr]
        vel = self.data['vel'][idx]
        w = self.data['weights'][idx]
        target = self.data['targets'][idx]

        # This ensures it does not "fit" to the data.
        # a) Add noise
        # b) Flip Az and El. Abs velocity is not affected (not included).
        if self.perturbate:
            vel = noiseAdd(vel)
        return vel, w, target

    def upsample(self, Idx, oversample):
        '''
        A function to upsample pursuit chunks to speed up the training process.
        '''
        freq = np.stack(self.data['freq'], 0)
        extra_pursuits = np.concatenate([Idx[freq[Idx, 1] > 0.1]]*oversample, axis=0)
        Idx = np.concatenate([Idx, extra_pursuits], axis=0)
        return Idx


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
        ID = torch.tensor(self.data['id'][idx])
        target = self.data['targets'][idx]
        n = int(4*np.floor(w.shape[0]/4))
        return vel[:n, :], w[:n], target[:n], ID

if __name__=='__main__':
    args = parse_args()
    f = open(os.path.join(args.path2data, 'Data.pkl'), 'rb')
    chunk, seq = pickle.load(f)
    trainIdx, validIdx = splitdata(chunk, args.PrTest, args.folds)
    testObj = GIW_readSeq(seq, args.PrTest)
    trainObj = GIW_readChunk(chunk, trainIdx[0])
    validObj = GIW_readChunk(chunk, validIdx[0])


