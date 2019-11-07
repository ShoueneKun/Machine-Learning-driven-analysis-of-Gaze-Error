import torch

def train(net, trainloader, validloader, args):
    for eps in range(0, args.epochs):
        net.train()
        for bt, data in enumerate(trainloader):
            traindata, W, target = data
            print('eps: {}. bt: {}'.format(eps, bt))
            print(traindata.shape)
            print(W.shape)
            print(target.shape)
    return [], []


def test(net, testloader, args):
    print('Testing ...')
    for seqIdx, data in enumerate(testloader):
        testdata, W, target = data
        print('seq: {}'.format(seqIdx))
        print(testdata.shape)
        print(W.shape)
        print(target.shape)
    return [], []

def loss(ip, target, weight, ignore_index):
    # Computes the loss based on given input and target.
    # Input: batch, sequence, features
    # Target: batch, sequence, class
    cE = torch.nn.CrossEntropyLoss(reduction='none', ignore_index=-1)
    sampleWeight = weight/