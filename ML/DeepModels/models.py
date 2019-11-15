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
        self.dp = torch.nn.Dropout(p=0.15)
        self.linear_stack= linStack(self.num_layers, in_dim=6, hidden_dim=24*3, out_dim=24, dp=0.0)
        self.RNN_stack = torch.nn.GRU(input_size=24,
                                      hidden_size=24,
                                      num_layers=self.num_layers,
                                      batch_first=True,
                                      bidirectional=True,
                                      dropout=0.0)

        self.fc = torch.nn.Linear(24*2, 3)
        self = weights_init(self)

    def forward(self, x, target, weight):
        assert not (torch.isnan(x).any() or torch.isinf(x).any()), "NaN or Inf found in input"
        assert not (torch.isnan(target).any() or torch.isinf(target).any()), "NaN or Inf found in target"
        assert not (torch.isnan(weight).any() or torch.isinf(weight).any()), "NaN or Inf found in weight"

        # All packing and unpacking will be done inside forward
        x = x[:,:,:6].cuda()/350
        # The data structure at this point is (batch, sequence, features)
        x = self.linear_stack(x)
        x = self.dp(x)
        x, _ = self.RNN_stack(x)
        x = self.fc(x) + 0.00001 # Adding a small eps paramter
        loss, loss1, loss2 = loss_giw(x.permute(0, 2, 1), target, weight, -1)
        return x, loss, loss1, loss2

class model_2(torch.nn.Module):
    # Bi-directional with Conv layers - current SOTA
    def __init__(self):
        super(model_2, self).__init__()
        self.dp_prec = 0.1
        self.d1 = torch.nn.Conv1d(in_channels=6, out_channels=16, kernel_size=3, padding=1)
        self.bn1 = torch.nn.BatchNorm1d(num_features=16)
        self.d2 = torch.nn.Conv1d(in_channels=16, out_channels=16, kernel_size=3, padding=1)
        self.bn2 = torch.nn.BatchNorm1d(num_features=16)
        self.d3 = torch.nn.Conv1d(in_channels=16, out_channels=16, kernel_size=3, padding=1)
        self.bn3 = torch.nn.BatchNorm1d(num_features=16)
        self.RNN_stack = torch.nn.GRU(input_size=16+6,
                                      hidden_size=24,
                                      num_layers=2,
                                      batch_first=True,
                                      bidirectional=True,
                                      dropout=self.dp_prec)
        self.fc = torch.nn.Linear(24*2, 3)
        self.dp = torch.nn.Dropout(p=self.dp_prec)

    def forward(self, x, target, weight):
        assert not (torch.isnan(x).any() or torch.isinf(x).any()), "NaN or Inf found in input"
        assert not (torch.isnan(target).any() or torch.isinf(target).any()), "NaN or Inf found in target"
        assert not (torch.isnan(weight).any() or torch.isinf(weight).any()), "NaN or Inf found in weight"
        # All packing and unpacking will be done inside forward
        x = x[:,:,:6].cuda()/350 # Divide by 700 ensures abs(signal) < 1
        # The data structure at this point is (batch, sequence, features)
        x_in = x.permute(0, 2, 1)
        x = self.bn1(F.leaky_relu(self.d1(x_in)))
        x = self.bn2(F.leaky_relu(self.d2(x)))
        x = self.bn3(F.leaky_relu(self.d3(x)))
        x = self.dp(x)
        x = torch.cat([x, x_in], dim=1)
        x = x.permute(0, 2, 1)
        x, _ = self.RNN_stack(x)
        x = self.fc(x) + 0.00001 # Adding a small eps paramter
        loss, loss1, loss2 = loss_giw(x.permute(0, 2, 1), target, weight, -1)
        return x, loss, loss1, loss2

class model_3(torch.nn.Module):
    # F-directional linear LSTM for GIW paper
    def __init__(self):
        super(model_3, self).__init__()
        self.num_layers = 3
        self.dp = torch.nn.Dropout(p=0.15)
        self.linear_stack= linStack(self.num_layers, in_dim=6, hidden_dim=24*3, out_dim=24, dp=0.0)
        self.RNN_stack = torch.nn.GRU(input_size=24,
                                      hidden_size=24,
                                      num_layers=self.num_layers,
                                      batch_first=True,
                                      bidirectional=False,
                                      dropout=0.0)

        self.fc = torch.nn.Linear(24, 3)
        self = weights_init(self)

    def forward(self, x, target, weight):
        assert not (torch.isnan(x).any() or torch.isinf(x).any()), "NaN or Inf found in input"
        assert not (torch.isnan(target).any() or torch.isinf(target).any()), "NaN or Inf found in target"
        assert not (torch.isnan(weight).any() or torch.isinf(weight).any()), "NaN or Inf found in weight"

        # All packing and unpacking will be done inside forward
        x = x[:,:,:6].cuda()/350
        # The data structure at this point is (batch, sequence, features)
        x = self.linear_stack(x)
        x = self.dp(x)
        x, _ = self.RNN_stack(x)
        x = self.fc(x) + 0.00001 # Adding a small eps paramter
        loss, loss1, loss2 = loss_giw(x.permute(0, 2, 1), target, weight, -1)
        return x, loss, loss1, loss2

class model_4(torch.nn.Module):
    # Bi-directional linear LSTM for GIW paper (only eyes)
    def __init__(self):
        super(model_4, self).__init__()
        self.num_layers = 3
        self.dp = torch.nn.Dropout(p=0.15)
        self.linear_stack= linStack(self.num_layers, in_dim=3, hidden_dim=24*3, out_dim=24, dp=0.0)
        self.RNN_stack = torch.nn.GRU(input_size=24,
                                      hidden_size=24,
                                      num_layers=self.num_layers,
                                      batch_first=True,
                                      bidirectional=False,
                                      dropout=0.0)

        self.fc = torch.nn.Linear(24, 3)
        self = weights_init(self)

    def forward(self, x, target, weight):
        assert not (torch.isnan(x).any() or torch.isinf(x).any()), "NaN or Inf found in input"
        assert not (torch.isnan(target).any() or torch.isinf(target).any()), "NaN or Inf found in target"
        assert not (torch.isnan(weight).any() or torch.isinf(weight).any()), "NaN or Inf found in weight"

        # All packing and unpacking will be done inside forward
        x = x[:,:,:3].cuda()/350
        # The data structure at this point is (batch, sequence, features)
        x = self.linear_stack(x)
        x = self.dp(x)
        x, _ = self.RNN_stack(x)
        x = self.fc(x) + 0.00001 # Adding a small eps paramter
        loss, loss1, loss2 = loss_giw(x.permute(0, 2, 1), target, weight, -1)
        return x, loss, loss1, loss2

class model_5(torch.nn.Module):
    # Bi-directional linear LSTM for GIW paper (only abs)
    def __init__(self):
        super(model_5, self).__init__()
        self.num_layers = 3
        self.dp = torch.nn.Dropout(p=0.15)
        self.linear_stack= linStack(self.num_layers, in_dim=2, hidden_dim=24*3, out_dim=24, dp=0.0)
        self.RNN_stack = torch.nn.GRU(input_size=24,
                                      hidden_size=24,
                                      num_layers=self.num_layers,
                                      batch_first=True,
                                      bidirectional=False,
                                      dropout=0.0)

        self.fc = torch.nn.Linear(24, 3)
        self = weights_init(self)

    def forward(self, x, target, weight):
        assert not (torch.isnan(x).any() or torch.isinf(x).any()), "NaN or Inf found in input"
        assert not (torch.isnan(target).any() or torch.isinf(target).any()), "NaN or Inf found in target"
        assert not (torch.isnan(weight).any() or torch.isinf(weight).any()), "NaN or Inf found in weight"

        # All packing and unpacking will be done inside forward
        x = x[:,:,[0, 3]].cuda()/350
        # The data structure at this point is (batch, sequence, features)
        x = self.linear_stack(x)
        x = self.dp(x)
        x, _ = self.RNN_stack(x)
        x = self.fc(x) + 0.00001 # Adding a small eps paramter
        loss, loss1, loss2 = loss_giw(x.permute(0, 2, 1), target, weight, -1)
        return x, loss, loss1, loss2