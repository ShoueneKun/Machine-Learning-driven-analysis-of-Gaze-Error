import torch
import numpy as np
from loss import getPerformance
from torchtools import EarlyStopping

def train(net, trainloader, validloader, testloader, TBwriter, args):
    cond = EarlyStopping(patience=75, mode='max', delta=7.5e-3, path2save=args.path2save, verbose=True)
    optimizer = torch.optim.Adam(net.parameters(), lr=args.lr, weight_decay=0)

    validTrack = trackPerf()
    trainTrack = trackPerf()
    for eps in range(0, args.epochs):
        net.train()
        for bt, data in enumerate(trainloader):
            optimizer.zero_grad()
            train_data, W, target = data
            y, loss, loss_ce, loss_dl = net(train_data.cuda(), target.cuda(), W.cuda())
            loss = torch.sum(loss)
            loss.backward()
            optimizer.step()

            pd = np.argmax(y.cpu().detach().numpy(), axis=2)
            gt = target.cpu().detach().numpy()
            perf = getPerformance(gt, pd, calc_evt=False)
            perf['loss'] = loss.detach().cpu().numpy()
            perf['loss_ce'] = loss_ce
            perf['loss_dl'] = loss_dl
            trainTrack.addEntry(eps, bt, perf)

        # Valid evaluation
        net.eval()
        with torch.no_grad():
            for bt, data in enumerate(validloader):
                valid_data, W, target = data
                y, loss, loss_ce, loss_dl = net(valid_data.cuda(), target.cuda(), W.cuda())
                pd = np.argmax(y.cpu().detach().numpy(), axis=2)
                gt = target.cpu().detach().numpy()
                perf = getPerformance(gt, pd, calc_evt=False)
                perf['loss'] = loss.cpu().numpy()
                perf['loss_ce'] = loss_ce
                perf['loss_dl'] = loss_dl
                validTrack.addEntry(eps, bt, perf)

        # Record best model
        cond(eps, validTrack.getPerf(eps, 'kappa'),
             net.state_dict() if torch.cuda.device_count() == 1 else net.module.state_dict())

        print('eps: {}. k: {}. p: {}. r: {}. k_evt: {}'.format(
                eps,
                validTrack.getPerf(eps, 'kappa'),
                validTrack.getPerf(eps, 'prec'),
                validTrack.getPerf(eps, 'recall'),
                validTrack.getPerf(eps, 'kappa_evt')))

        # Calculate test performance
        perf_test = test(net, testloader, cond.update_flag)[1]

        # Update tensorboard
        update_tensorboard(TBwriter, trainTrack, validTrack, perf_test, eps)
        if cond.early_stop:
            break

    TBwriter.close()
    return validTrack, cond.best_model

def update_tensorboard(TBwriter, trainTrack, validTrack, testTrack, eps):
    TBwriter.add_scalars('loss', {'train': trainTrack.getPerf(eps, 'loss'),
                                  'valid': validTrack.getPerf(eps, 'loss'),
                                  'test': testTrack.getPerf(0, 'loss')}, eps)

    TBwriter.add_scalars('loss/CE', {'train': trainTrack.getPerf(eps, 'loss_ce'),
                                  'valid': validTrack.getPerf(eps, 'loss_ce'),
                                  'test': testTrack.getPerf(0, 'loss_ce')}, eps)

    TBwriter.add_scalars('loss/gDL', {'train': trainTrack.getPerf(eps, 'loss_dl'),
                                  'valid': validTrack.getPerf(eps, 'loss_dl'),
                                  'test': testTrack.getPerf(0, 'loss_dl')}, eps)

    TBwriter.add_scalars('kappa', {'train': trainTrack.getPerf(eps, 'kappa'),
                                   'valid': validTrack.getPerf(eps, 'kappa'),
                                   'test': testTrack.getPerf(0, 'kappa')}, eps)

    TBwriter.add_scalars('iou', {'train': trainTrack.getPerf(eps, 'iou'),
                                   'valid': validTrack.getPerf(eps, 'iou'),
                                   'test': testTrack.getPerf(0, 'iou')}, eps)

    TBwriter.add_scalars('iou/fix', {'train': trainTrack.getPerf(eps, 'iou_class')[0],
                                   'valid': validTrack.getPerf(eps, 'iou_class')[0],
                                   'test': testTrack.getPerf(0, 'iou_class')[0]}, eps)

    TBwriter.add_scalars('iou/pur', {'train': trainTrack.getPerf(eps, 'iou_class')[1],
                                   'valid': validTrack.getPerf(eps, 'iou_class')[1],
                                   'test': testTrack.getPerf(0, 'iou_class')[1]}, eps)

    TBwriter.add_scalars('iou/sac', {'train': trainTrack.getPerf(eps, 'iou_class')[2],
                                   'valid': validTrack.getPerf(eps, 'iou_class')[2],
                                   'test': testTrack.getPerf(0, 'iou_class')[2]}, eps)
    return []

def test(net, testloader, talk=False):
    testTrack = trackPerf()
    net.eval()
    Y = []
    with torch.no_grad():
        for seqIdx, data in enumerate(testloader):
            test_data, W, target = data
            y, loss, loss_ce, loss_dl = net(test_data.cuda(), target.cuda(), W.cuda())
            pd = np.argmax(y.cpu().detach().numpy(), axis=2)
            gt = target.cpu().detach().numpy()
            perf = getPerformance(gt, pd, calc_evt=False)
            perf['loss'] = loss.cpu().numpy()
            perf['loss_ce'] = loss_ce
            perf['loss_dl'] = loss_dl
            testTrack.addEntry(0, seqIdx, perf)
            Y.append(pd)
    if talk:
        print('[UPDATE] eps: {}. k: {}. p: {}. r: {}. k_evt: {}'.format(
                    0,
                    testTrack.getPerf(0, 'kappa'),
                    testTrack.getPerf(0, 'prec'),
                    testTrack.getPerf(0, 'recall'),
                    testTrack.getPerf(0, 'kappa_evt')))
    return net, testTrack, Y

class trackPerf():
    def __init__(self):
        self.epoch = []
        self.bt = []
        self.loss = []
        self.loss_ce = []
        self.loss_dl = []
        self.kappa = []
        self.kappa_evt = []
        self.kappa_class_evt = []
        self.iou = []
        self.iou_class = []
        self.prec = []
        self.recall = []
        self.perf_list = []

    def addEntry(self, eps, bt, perf):
        self.epoch.append(eps)
        self.bt.append(bt)
        self.loss.append(perf['loss'])
        self.loss_ce.append(perf['loss_ce'])
        self.loss_dl.append(perf['loss_dl'])
        self.kappa.append(perf['kappa'])
        self.kappa_evt.append(perf['kappa_evt'])
        self.kappa_class_evt.append(perf['kappa_class_evt'])
        self.iou.append(perf['iou'])
        self.iou_class.append(perf['iou_class'])
        self.prec.append(perf['prec'])
        self.recall.append(perf['recall'])

    def getPerf(self, eps, attr):
        listeps = np.array(self.epoch)
        loc = listeps == eps
        temp = getattr(self, attr)
        temp = np.stack(temp, axis=0)
        temp = temp[loc, np.newaxis] if len(temp.shape) == 1 else temp[loc, :]
        op = np.mean(temp, axis=0)
        op = np.ma.round(op, 3)
        return op