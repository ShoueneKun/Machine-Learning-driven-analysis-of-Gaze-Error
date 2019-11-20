#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Nov  8 15:46:57 2019

@author: rakshit
"""
import os
import copy
import torch
import numpy as np
import quaternion as qt

class EarlyStopping:
    """Early stops the training if validation loss doesn't improve after a given patience."""
    # Modified by Rakshit Kothari
    def __init__(self,
                patience=7,
                verbose=False,
                delta=0,
                path2save=os.getcwd(),
                mode='min'):
        """
        Args:
            patience (int): How long to wait after last time validation loss improved.
                            Default: 7
            verbose (bool): If True, prints a message for each validation loss improvement.
                            Default: False
            delta (float): Minimum change in the monitored quantity to qualify as an improvement.
                            Default: 0
            fName (str): Name of the checkpoint file.
            path2save (str): Location of the checkpoint file.
        """
        self.patience = patience
        self.verbose = verbose
        self.counter = 0
        self.best_score = None
        self.early_stop = False
        self.update_flag = False
        self.best_model = dict()
        self.path2save = path2save

        if mode is 'min':
            self.val_loss_min = np.Inf
        elif mode is 'max':
            self.val_loss_min = -np.Inf
        else:
            print('Undefined mode. Exit.')
        self.delta = delta
        self.mode = mode

    def __call__(self,eps, val_loss, model):
        if self.mode == 'min':
            score = -val_loss
        else:
            score = val_loss

        if self.best_score is None:
            self.best_score = score
            self.save_checkpoint(eps, val_loss, model)

        elif score < self.best_score + self.delta:
            self.update_flag = False
            self.counter += 1
            print('EarlyStopping counter: {} out of {}'.format(self.counter, self.patience))
            if self.counter >= self.patience:
                self.early_stop = True
        else:
            self.update_flag = True
            self.best_score = score
            self.save_checkpoint(eps, val_loss, model)
            self.val_loss_min = score.item()
            self.counter = 0

    def save_checkpoint(self, eps, val_loss, model_dict):
        '''Saves model when validation loss decrease.'''
        if self.verbose and self.mode is 'min':
            print('Validation metric decreased ({:.6f} --> {:.6f}).  Saving model ...'.format(self.val_loss_min, val_loss.item()))
        elif self.verbose and self.mode is 'max':
            print('Validation metric increased ({:.6f} --> {:.6f}).  Saving model ...'.format(self.val_loss_min, val_loss.item()))
        self.best_model['net_params'] = copy.deepcopy(model_dict)
        self.best_model['eps'] = eps
        self.best_model['metric'] = val_loss
        torch.save(self.best_model, self.path2save)

def verify_weights(best_model_dict, net_dict):
    for key in net_dict.keys():
        val = torch.sum(net_dict[key] - best_model_dict[key])
        if val != 0:
            print('WTF! Values do not match')
        else:
            print('Match')

def noiseAdd(x):
    # Input is a Nx3 or Nx6 matrix. Each row represents an eye or eye+head
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

def perturbate(ip, mode=1):
    # Input is a list of L data, wherein each entry needs to be perturbed by a
    # random Az rotation or additive noise across all 3 axis.
    if mode is 1:
        M = list(map(rotator, ip))
    elif mode is 2:
        M = list(map(noiseAdd, ip))
    else:
        # No perturbation
        M = ip
    return M

def rotateVector(vec, rotMat=None):
    if rotMat is not None:
        R = rotMat
    else:
        # Returns a 4x4 matrix. Take the first 3.
        # R = random_rotation_matrix()[:3, :3]
        R = rotation_matrix((2*np.random.rand()-1.0)*np.pi, [0, 1, 0])[:3, :3]
    if vec.shape[1] == 3:
        return R, np.matmul(vec, R)
    elif vec.shape[1] == 4:
        # Input is a quaternion. Be careful.
        # Prefer to keep using Quaternion as
        # it is blazingly fast.
        Q = qt.as_quat_array(vec)
        Qmov = qt.from_rotation_matrix(R)
        Q_out = Qmov.conj()*Q*Qmov
        return R, qt.as_float_array(Q_out)
    else:
        print('Incorrect shape')

def rotator(x):
    # Input is a Nx3, Nx6 or Nx7 matrix. Each row represents an eye or eye+head
    # vector which needs to be rotated by the same rotation matrix. Head can
    # also be a quaternion to describe pose.
    R, A = rotateVector(x[:, :3].numpy(), None)
    A = torch.from_numpy(A).type(x.type())
    _, B = rotateVector(x[:, 3:].numpy(), R)
    B = torch.from_numpy(B).type(x.type())
    return torch.cat((A, B), dim=1)
