#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Nov  7 11:57:48 2019

@author: rakshit
"""
import torch
import torch.nn.functional as F
import numpy as np
from ModelHelpers import linStack, weights_init, uBlock, dBlock
from loss import loss_giw, loss_giw_dual

class model_1(torch.nn.Module):
    # Bi-directional linear LSTM for GIW paper
    # Note Dropout is 0.
    def __init__(self):
        super(model_1, self).__init__()
        self.num_layers = 3
        self.dp = torch.nn.Dropout(p=0.10)
        self.linear_stack= linStack(self.num_layers, in_dim=6, hidden_dim=12*3, out_dim=12, dp=0.0)
        self.RNN_stack = torch.nn.GRU(input_size=12,
                                      hidden_size=24,
                                      num_layers=self.num_layers,
                                      batch_first=True,
                                      bidirectional=True,
                                      dropout=0.10)

        self.fc = torch.nn.Linear(24*2, 3)
        self = weights_init(self)

    def forward(self, x, target, weight):
        assert not (torch.isnan(x).any() or torch.isinf(x).any()), "NaN or Inf found in input"
        assert not (torch.isnan(target).any() or torch.isinf(target).any()), "NaN or Inf found in target"
        assert not (torch.isnan(weight).any() or torch.isinf(weight).any()), "NaN or Inf found in weight"

        # All packing and unpacking will be done inside forward
        x = x[:,:,:6].cuda()
        # The data structure at this point is (batch, sequence, features)
        x = self.linear_stack(x)
        x = self.dp(x)
        x, _ = self.RNN_stack(x)
        x = self.fc(x) + 0.00001 # Adding a small eps paramter
        loss, loss1, loss2 = loss_giw(x.permute(0, 2, 1), target, weight, -1)
        return x, loss, loss1, loss2

class model_2(torch.nn.Module):
    # Bi-directional linear LSTM for GIW paper (only eyes)
    def __init__(self):
        super(model_2, self).__init__()
        self.num_layers = 3
        self.dp = torch.nn.Dropout(p=0.10)
        self.linear_stack= linStack(self.num_layers, in_dim=1, hidden_dim=12*3, out_dim=12, dp=0.0)
        self.RNN_stack = torch.nn.GRU(input_size=12,
                                      hidden_size=24,
                                      num_layers=self.num_layers,
                                      batch_first=True,
                                      bidirectional=True,
                                      dropout=0.10)

        self.fc = torch.nn.Linear(24*2, 3)
        self = weights_init(self)

    def forward(self, x, target, weight):
        assert not (torch.isnan(x).any() or torch.isinf(x).any()), "NaN or Inf found in input"
        assert not (torch.isnan(target).any() or torch.isinf(target).any()), "NaN or Inf found in target"
        assert not (torch.isnan(weight).any() or torch.isinf(weight).any()), "NaN or Inf found in weight"

        # All packing and unpacking will be done inside forward
        x = x[:,:,0].cuda().unsqueeze(-1)
        # The data structure at this point is (batch, sequence, features)
        x = self.linear_stack(x)
        x = self.dp(x)
        x, _ = self.RNN_stack(x)
        x = self.fc(x) + 0.00001 # Adding a small eps paramter
        loss, loss1, loss2 = loss_giw(x.permute(0, 2, 1), target, weight, -1)
        return x, loss, loss1, loss2

class model_3(torch.nn.Module):
    # Bi-directional linear LSTM for GIW paper (only abs)
    def __init__(self):
        super(model_3, self).__init__()
        self.num_layers = 3
        self.dp = torch.nn.Dropout(p=0.10)
        self.linear_stack= linStack(self.num_layers, in_dim=2, hidden_dim=12*3, out_dim=12, dp=0.0)
        self.RNN_stack = torch.nn.GRU(input_size=12,
                                      hidden_size=24,
                                      num_layers=self.num_layers,
                                      batch_first=True,
                                      bidirectional=True,
                                      dropout=0.10)

        self.fc = torch.nn.Linear(24*2, 3)
        self = weights_init(self)

    def forward(self, x, target, weight):
        assert not (torch.isnan(x).any() or torch.isinf(x).any()), "NaN or Inf found in input"
        assert not (torch.isnan(target).any() or torch.isinf(target).any()), "NaN or Inf found in target"
        assert not (torch.isnan(weight).any() or torch.isinf(weight).any()), "NaN or Inf found in weight"

        # All packing and unpacking will be done inside forward
        x = x[:,:,[0, 3]].cuda()
        # The data structure at this point is (batch, sequence, features)
        x = self.linear_stack(x)
        x = self.dp(x)
        x, _ = self.RNN_stack(x)
        x = self.fc(x) + 0.00001 # Adding a small eps paramter
        loss, loss1, loss2 = loss_giw(x.permute(0, 2, 1), target, weight, -1)
        return x, loss, loss1, loss2

class model_4(torch.nn.Module):
    # F-directional linear LSTM for GIW paper
    def __init__(self):
        super(model_4, self).__init__()
        self.num_layers = 3
        self.dp = torch.nn.Dropout(p=0.100)
        self.linear_stack= linStack(self.num_layers, in_dim=6, hidden_dim=12*3, out_dim=12, dp=0.0)
        self.RNN_stack = torch.nn.GRU(input_size=12,
                                      hidden_size=24,
                                      num_layers=self.num_layers,
                                      batch_first=True,
                                      bidirectional=False,
                                      dropout=0.10)

        self.fc = torch.nn.Linear(24, 3)
        self = weights_init(self)

    def forward(self, x, target, weight):
        assert not (torch.isnan(x).any() or torch.isinf(x).any()), "NaN or Inf found in input"
        assert not (torch.isnan(target).any() or torch.isinf(target).any()), "NaN or Inf found in target"
        assert not (torch.isnan(weight).any() or torch.isinf(weight).any()), "NaN or Inf found in weight"

        # All packing and unpacking will be done inside forward
        x = x[:,:,:6].cuda()
        # The data structure at this point is (batch, sequence, features)
        x = self.linear_stack(x)
        x = self.dp(x)
        x, _ = self.RNN_stack(x)
        x = self.fc(x) + 0.00001 # Adding a small eps paramter
        loss, loss1, loss2 = loss_giw(x.permute(0, 2, 1), target, weight, -1)
        return x, loss, loss1, loss2

class model_5(torch.nn.Module):
    # Bi-directional linear LSTM for GIW paper - Only GiW velocity
    def __init__(self):
        super(model_5, self).__init__()
        self.num_layers = 3
        self.dp = torch.nn.Dropout(p=0.100)
        self.linear_stack= linStack(self.num_layers, in_dim=3, hidden_dim=12*3, out_dim=12, dp=0.0)
        self.RNN_stack = torch.nn.GRU(input_size=12,
                                      hidden_size=24,
                                      num_layers=self.num_layers,
                                      batch_first=True,
                                      bidirectional=True,
                                      dropout=0.10)

        self.fc = torch.nn.Linear(24*2, 3)
        self = weights_init(self)

    def forward(self, x, target, weight):
        assert not (torch.isnan(x).any() or torch.isinf(x).any()), "NaN or Inf found in input"
        assert not (torch.isnan(target).any() or torch.isinf(target).any()), "NaN or Inf found in target"
        assert not (torch.isnan(weight).any() or torch.isinf(weight).any()), "NaN or Inf found in weight"

        # All packing and unpacking will be done inside forward
        x = x[:,:,6:].cuda()
        # The data structure at this point is (batch, sequence, features)
        x = self.linear_stack(x)
        x = self.dp(x)
        x, _ = self.RNN_stack(x)
        x = self.fc(x) + 0.00001 # Adding a small eps paramter
        loss, loss1, loss2 = loss_giw(x.permute(0, 2, 1), target, weight, -1)
        return x, loss, loss1, loss2

class model_6(torch.nn.Module):
    # Bi-directional with Conv layers - current SOTA
    def __init__(self):
        super(model_6, self).__init__()
        self.dp_prec = 0.1
        self.d1 = torch.nn.Conv1d(in_channels=6, out_channels=16, kernel_size=3, padding=1)
        self.bn1 = torch.nn.BatchNorm1d(num_features=16, affine=True)
        self.d2 = torch.nn.Conv1d(in_channels=16, out_channels=16, kernel_size=3, padding=1)
        self.bn2 = torch.nn.BatchNorm1d(num_features=16, affine=True)
        self.d3_1 = torch.nn.Conv1d(in_channels=16, out_channels=4, kernel_size=3, padding=1, dilation=1)
        self.d3_2 = torch.nn.Conv1d(in_channels=16, out_channels=4, kernel_size=3, padding=2, dilation=2)
        self.d3_3 = torch.nn.Conv1d(in_channels=16, out_channels=4, kernel_size=3, padding=3, dilation=3)
        self.d3_4 = torch.nn.Conv1d(in_channels=16, out_channels=4, kernel_size=3, padding=4, dilation=4)
        self.bn3 = torch.nn.BatchNorm1d(num_features=16, affine=False)
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
        x = x[:,:,:6].cuda() # Divide by 700 ensures abs(signal) < 1
        # The data structure at this point is (batch, sequence, features)
        x_in = x.permute(0, 2, 1)
        x = self.bn1(F.leaky_relu(self.d1(x_in)))
        x = self.bn2(F.leaky_relu(self.d2(x)))
        x = self.dp(x)
        x = torch.cat([self.d3_1(x), self.d3_2(x), self.d3_3(x), self.d3_4(x)], dim=1)
        x = self.bn3(F.leaky_relu(x))
        x = torch.cat([x, x_in], dim=1)
        x = x.permute(0, 2, 1)
        x, _ = self.RNN_stack(x)
        x = self.fc(x) + 0.00001 # Adding a small eps paramter
        loss, loss1, loss2 = loss_giw(x.permute(0, 2, 1), target, weight, -1)
        return x, loss, loss1, loss2

class model_7(torch.nn.Module):
    # Bi-directional linear LSTM for GIW paper - Predict GiW velocity. Dual task.
    def __init__(self):
        super(model_7, self).__init__()
        self.num_layers = 3
        self.dp = torch.nn.Dropout(p=0.10)
        self.linear_stack= linStack(self.num_layers, in_dim=6, hidden_dim=12*3, out_dim=12, dp=0.0)
        self.RNN_stack = torch.nn.GRU(input_size=12,
                                      hidden_size=24,
                                      num_layers=self.num_layers,
                                      batch_first=True,
                                      bidirectional=True,
                                      dropout=0.10)

        self.fc = torch.nn.Linear(24*2, 6)
        self = weights_init(self)

    def forward(self, x, target, weight):
        assert not (torch.isnan(x).any() or torch.isinf(x).any()), "NaN or Inf found in input"
        assert not (torch.isnan(target).any() or torch.isinf(target).any()), "NaN or Inf found in target"
        assert not (torch.isnan(weight).any() or torch.isinf(weight).any()), "NaN or Inf found in weight"

        giw_vel = x[:,:,6:].cuda().to(torch.float64)

        # All packing and unpacking will be done inside forward
        x = x[:,:,:6].cuda()
        # The data structure at this point is (batch, sequence, features)
        x = self.linear_stack(x)
        x = self.dp(x)
        x, _ = self.RNN_stack(x)
        x = self.fc(x) + 0.00001 # Adding a small eps paramter
        loss, loss1, loss2 = loss_giw_dual(x.permute(0, 2, 1), target, weight, -1, giw_vel.permute(0,2,1))
        return x[:,:,:3], loss, loss1, loss2

class model_8(torch.nn.Module):
    # Bi-directional linear LSTM for GIW paper - dropout experiments
    def __init__(self):
        super(model_8, self).__init__()
        self.num_layers = 3
        self.dp = torch.nn.Dropout(p=0.00)
        self.linear_stack= linStack(self.num_layers, in_dim=6, hidden_dim=12*3, out_dim=12, dp=0.0)
        self.RNN_stack = torch.nn.GRU(input_size=12,
                                      hidden_size=24,
                                      num_layers=self.num_layers,
                                      batch_first=True,
                                      bidirectional=True,
                                      dropout=0.00)

        self.fc = torch.nn.Linear(24*2, 3)
        self = weights_init(self)

    def forward(self, x, target, weight):
        assert not (torch.isnan(x).any() or torch.isinf(x).any()), "NaN or Inf found in input"
        assert not (torch.isnan(target).any() or torch.isinf(target).any()), "NaN or Inf found in target"
        assert not (torch.isnan(weight).any() or torch.isinf(weight).any()), "NaN or Inf found in weight"

        # All packing and unpacking will be done inside forward
        x = x[:,:,:6].cuda()
        # The data structure at this point is (batch, sequence, features)
        x = self.linear_stack(x)
        x = self.dp(x)
        x, _ = self.RNN_stack(x)
        x = self.fc(x) + 0.00001 # Adding a small eps paramter
        loss, loss1, loss2 = loss_giw(x.permute(0, 2, 1), target, weight, -1)
        return x, loss, loss1, loss2

class model_9(torch.nn.Module):
    # Encoder-decoder arch.
    def __init__(self):
        super(model_9, self).__init__()
        self.dp = 0.10

        self.head = torch.nn.Conv1d(in_channels=6, out_channels=16, kernel_size=3, padding=1, bias=True)
        self.choke = torch.nn.Conv1d(in_channels=16+6, out_channels=16, kernel_size=1, bias=True)

        self.down_1 = dBlock(16, 16, dp=self.dp)
        self.down_2 = dBlock(16, 16, dp=self.dp)

        self.rnn_zip = torch.nn.GRU(input_size=16, hidden_size=16, num_layers=1, batch_first=True, bidirectional=True)
        #self.choke_time = torch.nn.Conv1d(in_channels=16*2, out_channels=16, kernel_size=1, bias=True)

        self.up_2 = uBlock(16, 16)
        self.up_1 = uBlock(16, 16)

        self.fc = torch.nn.Conv1d(in_channels=16, out_channels=3, kernel_size=1, padding=0, bias=True)
        self.avgpool = torch.nn.AvgPool1d(kernel_size=2, padding=0, stride=2)

    def forward(self, ip, target, weight):
        '''
        N = int(np.floor(ip.shape[1]/4))
        ip = ip[:,:N*4,:6]
        target = target[:,:N*4]
        weight = weight[:,:N*4]
        '''
        ip = ip[:,:,:6].cuda().permute(0, 2, 1)
        x = self.head(ip)
        x = torch.cat([x, ip], dim=1)
        x = self.choke(x)

        # Down 1
        d1 = self.avgpool(x)
        d1 = self.down_1(d1)

        # Down 2
        d2 = self.avgpool(d1)
        d2 = self.down_2(d2)

        # Zip
        u2 = self.rnn_zip(d2.permute(0, 2, 1))[0]

        # Up 2
        u2 = self.up_2(u2.permute(0, 2, 1))
        u1 = torch.cat([u2, d1], dim=1)

        # Up 1
        u1 = self.up_1(u1)

        #Output
        op = self.fc(u1)
        loss, loss1, loss2 = loss_giw(op, target, weight, -1)
        return op.permute(0,2,1), loss, loss1, loss2

