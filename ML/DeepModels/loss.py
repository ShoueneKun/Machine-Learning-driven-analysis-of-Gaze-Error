import torch
import sklearn
import numpy as np
from elc_metric.ELC import elc

# Metrics
def getPerformance(y_true, y_pred, calc_evt):
    # Return all relevant performance metrics
    # Do not consider elements with -1
    loc = y_true != -1
    y_pred = y_pred[loc]
    y_true = y_true[loc]

    Perf = dict()
    Perf['kappa'] = sklearn.metrics.cohen_kappa_score(y_true, y_pred, labels=[0,1,2])
    Perf['mpca'] = sklearn.metrics.accuracy_score(y_true, y_pred)
    Perf['conf'] = sklearn.metrics.confusion_matrix(y_true, y_pred, labels=[0,1,2])
    Perf['prec'] = sklearn.metrics.precision_score(y_true, y_pred, average=None, labels=[0,1,2])
    Perf['mpcp'] = sklearn.metrics.precision_score(y_true, y_pred, average='macro', labels=[0,1,2])
    Perf['recall'] = sklearn.metrics.recall_score(y_true, y_pred, average=None, labels=[0,1,2])
    Perf['mpcr'] = sklearn.metrics.recall_score(y_true, y_pred, average='macro', labels=[0,1,2])
    Perf['iou'] = sklearn.metrics.jaccard_score(y_true, y_pred, average='macro', labels=[0,1,2])
    Perf['iou_class'] = sklearn.metrics.jaccard_score(y_true, y_pred, average=None, labels=[0,1,2])

    if calc_evt:
        cmat_list = [elc(y_true[i, ...].squeeze(), y_pred[i, ...].squeeze(), 15)[2] for i in range(0, y_true.shape[0])]
        Perf['kappa_evt'] = np.mean([kappa_confusion(cmat) for cmat in cmat_list])
        Perf['kappa_class_evt'] = np.mean(np.stack([kappa_perClass(cmat) for cmat in cmat_list], axis=0), axis=0)
    else:
        Perf['kappa_evt'] = 0
        Perf['kappa_class_evt'] = np.array([0, 0, 0])

    return Perf

def kappa_perClass(cmat):
    '''
    Computes the kappa score per class for a given confusion matrix
    '''
    kappa_class = []
    C = cmat.shape[0]
    classes_present = np.arange(0, C)
    for k in range(0, C):
        x = classes_present[classes_present!=k]
        y = k
        a = cmat[k, k]
        b = np.sum(cmat[x, y])
        c = np.sum(cmat[y, x])
        d = np.sum(cmat[x, x])
        assert np.sum([a,b,c,d]) == np.sum(cmat), "Incorrect calculation"
        cmat_c = np.array([[a, c], [b, d]])
        kappa_class.append(kappa_confusion(cmat_c))
    return np.array(kappa_class)

def kappa_confusion(cmat):
    '''
    Computes the kappa score from a given confusion matrix
    '''
    w = np.eye(cmat.shape[0])
    n = np.sum(cmat) # Total elements
    x = cmat/n
    r = np.sum(x, axis=1) # Sum across rows
    s = np.sum(x, axis=0) # Sum across columns
    Ex = r.reshape(3,1)*s.reshape(1,3) # Expected proportion for random agreement
    #pom = np.sum(np.min(np.stack([r, s], axis=0), axis=0))
    po = np.sum(x.dot(w))
    pe = np.sum(Ex.dot(w))
    kappa = (po - pe)/(1 - pe)
    return kappa

# Loss functions
def loss_giw(ip, target, weight, ignore_index):
    loss1 = torch.mean(loss_ce(ip, target, weight, ignore_index))
    GD = GeneralizedDiceLoss(ignore_index=ignore_index).cuda()
    loss2 = GD(ip, target)
    loss = loss1 + loss2
    return loss, loss1.detach().cpu().item(), loss2.detach().cpu().item()

def loss_giw_dual(ip, target, weight, ignore_index, task_2):
    loss1 = torch.mean(loss_ce(ip[:,:3,:], target, weight, ignore_index))
    GD = GeneralizedDiceLoss(ignore_index=ignore_index).cuda()
    loss2 = GD(ip[:,:3,:], target)
    loss3 = torch.nn.MSELoss()
    loss = loss1 + loss2 + loss3(ip[:,3:,:], task_2)
    return loss, loss1.detach().cpu().item(), loss2.detach().cpu().item()

def loss_ce(ip, target, weight, ignore_index):
    # Computes the loss based on given input and target.
    # Input: batch, sequence, features
    # Target: batch, sequence, class
    #cE = torch.nn.CrossEntropyLoss(reduction='none', ignore_index=-1)
    #loss_ce = cE(ip, target.to(torch.long))
    cE = torch.nn.CrossEntropyLoss(reduction='none', ignore_index=-1, weight=torch.tensor([0.3, 0.8, 0.5]).cuda())
    sampleWeight = weight/torch.sum(weight, dim=1, keepdim=True)
    loss_ce = sampleWeight*cE(ip, target.to(torch.long))

    loss_ce = torch.sum(loss_ce, dim=1)
    return loss_ce

class GeneralizedDiceLoss(torch.nn.Module):
    # Author: Rakshit Kothari
    # Input: (B, C, ...)
    # Target: (B, C, ...)
    def __init__(self, epsilon=1e-5, weight=None, softmax=True, reduction=True, ignore_index=-1):
        super(GeneralizedDiceLoss, self).__init__()
        self.epsilon = epsilon
        self.weight = []
        self.reduction = reduction
        self.ignore_index = ignore_index
        if softmax:
            self.norm = torch.nn.Softmax(dim=1)
        else:
            self.norm = torch.nn.Sigmoid()

    def forward(self, ip, target):
        mask = target.clone().ne_(self.ignore_index)
        mask = [mask for i in range(0, ip.shape[1])]
        mask = torch.stack(mask, dim=1)
        mask.requires_grad = False

        ip = ip*mask.to(torch.float)

        # Rapid way to convert to one-hot. For future version, use functional
        Label = (np.arange(3) == target.cpu().numpy()[..., None]).astype(np.uint8)
        target = torch.from_numpy(np.rollaxis(Label, 2, start=1)).cuda()

        if not (ip.shape == target.shape):
            print('Shapes do not match')
            print('Input shape: {}'.format(ip.shape))
            print('Target shape: {}'.format(target.shape))
        ip = self.norm(ip)

        # Flatten for multidimensional data
        ip = torch.flatten(ip, start_dim=2, end_dim=-1).cuda().to(torch.float32)
        target = torch.flatten(target, start_dim=2, end_dim=-1).cuda().to(torch.float32)

        numerator = ip*target
        denominator = ip + target

        class_weights = 1./(torch.sum(target, dim=2)**2).clamp(min=self.epsilon)

        A = class_weights*torch.sum(numerator, dim=2)
        B = class_weights*torch.sum(denominator, dim=2)

        dice_metric = 2.*torch.sum(A, dim=1)/torch.sum(B, dim=1)
        if self.reduction:
            return torch.mean(1. - dice_metric.clamp(min=self.epsilon))
        else:
            return 1. - dice_metric.clamp(min=self.epsilon)