#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Nov  7 11:57:48 2019

@author: rakshit
"""
import torch
import torch.nn.functional as F
from ModelHelpers import linStack, weights_init
from loss import loss_giw

class model_1(torch.nn.Module):
    # Bi-directional linear LSTM for GIW paper
    def __init__(self):
        super(model_1, self).__init__()
        self.num_layers = 3
        self.linear_stack= linStack(self.num_layers, in_dim=6, hidden_dim=12*3, out_dim=24)
        self.RNN_stack = torch.nn.GRU(input_size=24,
                                      hidden_size=24,
                                      num_layers=self.num_layers,
                                      batch_first=True,
                                      bidirectional=True,
                                      dropout=0.0)

        self.fc = torch.nn.Linear(24*2, 3)
        self.dp = torch.nn.dropout(p=0.1)
        self = weights_init(self)

    def forward(self, x, target, weight):
        # All packing and unpacking will be done inside forward
        x = x[:,:,:6].cuda()/700
        # The data structure at this point is (batch, sequence, features)
        x = self.linear_stack(x)
        x, _ = self.RNN_stack(x)
        x = self.dp(x)
        x = self.fc(x) + 0.00001 # Adding a small eps paramter
        loss = loss_giw(x.permute(0, 2, 1), target, weight, -1)
        return x, loss.unsqueeze(0)

class model_2(torch.nn.Module):
    # Bi-directional with Conv layers - current SOTA
    def __init__(self):
        super(model_2, self).__init__()
        self.d1 = torch.nn.Conv1d(in_channels=6, out_channels=8, kernel_size=3, padding=1)
        self.bn1 = torch.nn.BatchNorm1d(num_features=8)
        self.d2 = torch.nn.Conv1d(in_channels=8, out_channels=8, kernel_size=3, padding=1)
        self.bn2 = torch.nn.BatchNorm1d(num_features=8)
        self.d3 = torch.nn.Conv1d(in_channels=8, out_channels=8, kernel_size=3, padding=1)
        self.bn3 = torch.nn.BatchNorm1d(num_features=8)
        self.RNN_stack = torch.nn.GRU(input_size=8+6,
                                      hidden_size=12,
                                      num_layers=2,
                                      batch_first=True,
                                      bidirectional=True)
        self.fc = torch.nn.Linear(12*2, 3)

    def forward(self, x, target, weight):
        # All packing and unpacking will be done inside forward
        x = x[:,:,:6].cuda()/700 # Divide by 700 ensures abs(signal) < 1
        # The data structure at this point is (batch, sequence, features)
        x_in = x.permute(0, 2, 1)
        x = F.leaky_relu(self.bn1(self.d1(x_in)))
        x = F.leaky_relu(self.bn2(self.d2(x)))
        x = F.leaky_relu(self.bn3(self.d3(x)))
        x = torch.cat([x, x_in], dim=1)
        x = x.permute(0, 2, 1)
        x, _ = self.RNN_stack(x)
        x = self.fc(x) + 0.00001 # Adding a small eps paramter
        loss = loss_giw(x.permute(0, 2, 1), target, weight, -1)
        return x, loss.unsqueeze(0)

class model_3(torch.nn.Module):
    # RITnet - offline
    def __init__(self):





    def forward(self, x, target, weight):








    return x, loss.unsqeeze(0)