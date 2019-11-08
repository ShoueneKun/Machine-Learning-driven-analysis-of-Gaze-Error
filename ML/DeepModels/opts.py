import torch
import numpy as np
from loss import getPerformance
from torchtools import EarlyStopping

def train(net, trainloader, validloader, args):
    cond = EarlyStopping(patience=100, mode='max')
    best_model = dict()
    optimizer = torch.optim.Adam(net.parameters(), lr=args.lr)

    validTrack = trackPerf()
    for eps in range(0, args.epochs):
        net.train()
        for bt, data in enumerate(trainloader):
            optimizer.zero_grad()
            train_data, W, target = data
            _, loss = net(train_data.cuda(), target.cuda(), W.cuda())
            loss = torch.sum(loss)
            loss.backward()
            optimizer.step()
            print('bt:{}. loss: {}'.format(bt, loss.cpu().item()))

        net.eval()
        with torch.no_grad():
            for bt, data in enumerate(validloader):
                valid_data, W, target = data
                y, loss = net(valid_data.cuda(), target.cuda(), W.cuda())
                pd = np.argmax(y.cpu().detach().numpy(), axis=2)
                gt = target.cpu().detach().numpy()
                perf = getPerformance(gt, pd, calc_evt=True)
                perf['loss'] = loss.cpu().numpy()
                validTrack.addEntry(eps, bt, perf)
        best_model = cond(eps, validTrack.getPerf('kappa'),
             net.state_dict() if torch.cuda.device_count() == 1 else net.module.state_dict(),
             best_model)
        print('eps: {}. k: {}. p: {}. r: {}. k_evt: {}'.format(
                validTrack.getPerf(eps, 'kappa'),
                validTrack.getPerf(eps, 'prec'),
                validTrack.getPerf(eps, 'recall'),
                validTrack.getPerf(eps, 'kappa_evt')))
    return net, validTrack


def test(net, testloader, args):
    print('Testing ...')
    for seqIdx, data in enumerate(testloader):
        testdata, W, target = data
        print('seq: {}'.format(seqIdx))
        print(testdata.shape)
        print(W.shape)
        print(target.shape)
    return [], []

class trackPerf():
    def __init__(self):
        self.epoch = []
        self.bt = []
        self.loss = []
        self.kappa = []
        self.kappa_evt = []
        self.kappa_class_evt = []
        self.iou = []
        self.prec = []
        self.recall = []
        self.perf_list = []

    def addEntry(self, eps, bt, perf):
        self.epoch.append(eps)
        self.bt.append(bt)
        self.loss.append(perf['loss'])
        self.kappa.append(perf['kappa'])
        self.kappa_evt.append(perf['kappa_evt'])
        self.kappa_class_evt.append(perf['kappa_class_evt'])
        self.iou.append(perf['iou'])
        self.prec.append(perf['prec'])
        self.recall.append(perf['recall'])

    def getPerf(self, eps, attr):
        listeps = np.array(self.epoch)
        loc = listeps == eps
        temp = getattr(self, attr)
        temp = np.stack(temp, axis=0)
        temp = temp[loc, np.newaxis] if len(temp.shape) == 1 else temp[loc, :]
        op = np.mean(temp, axis=0) if eps == -1 else np.mean(temp[listeps == eps, :], axis=0)
        op = np.ma.round(op, 3)
        return op