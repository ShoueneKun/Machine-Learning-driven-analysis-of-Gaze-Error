#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Nov  7 10:26:19 2019

@author: rakshit
"""

from pprint import pprint
import argparse
import os

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--PrTest', type=int, default=1)
    parser.add_argument('--lr', type=float, default=1e-5)
    parser.add_argument('--batchsize', type=int, default=64)
    parser.add_argument('--modeltype', type=int, default=3)
    parser.add_argument('--epochs', type=int, default=500)
    parser.add_argument('--folds', type=int, default=5)
    parser.add_argument('--path2data', type=str,
                        default=os.path.join(os.getcwd(), 'Data'))

    args = parser.parse_args()
    opt = vars(args)
    print('----------')
    print('parsed arguments:')
    pprint(opt)
    return args

if __name__=='__main__':
    opt = parse_args()
