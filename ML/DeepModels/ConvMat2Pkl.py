#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jul 17 08:46:37 2019

@author: rakshit
"""
import matlab.engine
import numpy as np
import pickle
import torch
import itertools
import os
DATA_PATH = os.getcwd()

class makeparams():
    def __init__(self):
        self.PrTest_List = [1, 2, 3, 8, 9, 12, 16, 17, 22]
        self.prec = torch.float32

def extract(data, prec):
    # Split a chunk into data, targets and class counts.
    # Convert MATLAB format into numpy array
    tempVec = []
    tempTargets = []
    tempFreq = []
    tempWeight = []
    tempVel = []
    tempLen = []
    for chunk in data:
        # Weight needs to be extracted. It is the second last column.
        # First 7 columns are the vectors and head quaternion.
        # Next 6 are the velocity components.
        tempVec.append(torch.from_numpy(np.array(chunk)[:, :9]).to(prec))
        tempVel.append(torch.from_numpy(np.array(chunk)[:, 9:-2]).to(prec))
        tempWeight.append(torch.from_numpy(np.array(chunk)[:, -2]).to(prec))
        tempTargets.append(torch.from_numpy(np.array(chunk)[:, -1]).to(torch.long))
        tempLen.append(np.array(chunk).shape[0])
        numFix, numPur, numSac = calcfreq(np.array(chunk)[:, -1])
        tempFreq.append(np.array([numFix, numPur, numSac]))
    return (tempVec, tempTargets, tempFreq, tempWeight, tempVel, tempLen)

def calcfreq(targets):
    numFix = np.sum(np.asarray(targets)==0)
    numPur = np.sum(np.asarray(targets)==1)
    numSac = np.sum(np.asarray(targets)==2)
    tot = numFix + numPur + numSac
    return (numFix/tot, numPur/tot, numSac/tot)

def dataGen(Chunks, Data, Targets, Weights, ID, prec):
    ChunkTensors = {'vec':[], 'vel':[], 'targets':[], 'lens':[], 'freq':[], 'id':[], 'weights':[]}
    SeriesTensors = {'vec':[], 'vel':[], 'targets':[], 'lens':[], 'freq':[], 'id':[], 'weights':[]}

    for i in range(0, ID.shape[0]):
        ids = np.expand_dims(np.asarray(ID)[i, :], axis=0)
        print('Current ID in process: {}'.format(ids.squeeze()))
        # Unpack series
        SeriesTensors['vec'].append(torch.from_numpy(np.asarray(Data[i])[:, :9]).to(prec))
        SeriesTensors['vel'].append(torch.from_numpy(np.asarray(Data[i])[:, 9:]).to(prec))
        SeriesTensors['targets'].append(torch.from_numpy(np.asarray(Targets[i])).to(torch.long))
        SeriesTensors['weights'].append(torch.from_numpy(np.asarray(Weights[i])).to(prec))
        SeriesTensors['lens'].append(len(Targets[i]))
        SeriesTensors['freq'].append(calcfreq(Targets[i]))
        SeriesTensors['id'].append(np.asarray(ID)[i, :])

        # Unpack chunks.
        tempVec, tempTargets, tempFreq, tempWeight, tempVel, tempLen = extract(Chunks[i], prec)
        ChunkTensors['vec'].append(tempVec)
        ChunkTensors['vel'].append(tempVel)
        ChunkTensors['targets'].append(tempTargets)
        ChunkTensors['weights'].append(tempWeight)
        ChunkTensors['freq'].append(tempFreq)
        ChunkTensors['lens'].append(tempLen)
        ChunkTensors['id'].append(np.repeat(ids, len(tempVec), axis=0))

    ChunkTensors['vec'] = list(itertools.chain(*ChunkTensors['vec']))
    ChunkTensors['vel'] = list(itertools.chain(*ChunkTensors['vel']))
    ChunkTensors['targets'] = list(itertools.chain(*ChunkTensors['targets']))
    ChunkTensors['lens'] = list(itertools.chain(*ChunkTensors['lens']))
    ChunkTensors['freq'] = list(itertools.chain(*ChunkTensors['freq']))
    ChunkTensors['id'] = list(itertools.chain(*ChunkTensors['id']))
    ChunkTensors['weights'] = list(itertools.chain(*ChunkTensors['weights']))
    return ChunkTensors, SeriesTensors

# Load MATLAB
params = makeparams()
mateng = matlab.engine.start_matlab()
print('MATLAB engine started.')
Dataset = mateng.load(os.path.join(DATA_PATH, 'Data', 'Data.mat'))
print('Dataset loaded.')
mateng.close()
print('Closed MATLAB.')

# Chunks also contain Targets. Make note of architecture
Chunks = Dataset['Chunks']
Data = Dataset['TrainData']
Targets = Dataset['Targets']
Weights = Dataset['Weights']
ID = np.asarray(Dataset['ID'])

SeqTensors, SeriesTensors = dataGen(Chunks, Data, Targets, Weights, ID, params.prec)
f = open(os.path.join(DATA_PATH, 'Data', 'Data.pkl'), 'wb')
pickle.dump([SeqTensors, SeriesTensors], f)