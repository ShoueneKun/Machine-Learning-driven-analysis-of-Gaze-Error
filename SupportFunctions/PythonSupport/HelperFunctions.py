import pickle
import logger
import numpy as np
import msgpack
import sklearn.metrics
import os
import torch
import time
import copy
from utils_lib.etdata import ETData
from utils_lib.ETeval import eval_evt
# A collection of helper functions written in Python

def load_object(file_path, allow_legacy=True):
    import gc
    file_path = os.path.expanduser(file_path)
    with open(file_path, 'rb') as fh:
        try:
            gc.disable()  # speeds deserialization up.
            data = msgpack.unpack(fh, raw=False)
        except Exception as e:
            if not allow_legacy:
                raise e
            else:
                logger.info('{} has a deprecated format: Will be updated on save'.format(file_path))
                data = _load_object_legacy(file_path)
        finally:
            gc.enable()
    return data


def save_object(object_, file_path):

    def ndarrray_to_list(o, _warned=[False]):  # Use a mutlable default arg
        # to hold a fn interal temp var.
        if isinstance(o, np.ndarray):
            if not _warned[0]:
                logger.warning("numpy array will be serialized as list. Invoked at:\n"+''.join(tb.format_stack()))
                _warned[0] = True
            return o.tolist()
        return o

    file_path = os.path.expanduser(file_path)
    with open(file_path, 'wb') as fh:
        msgpack.pack(object_, fh, use_bin_type=True,default=ndarrray_to_list)


def _load_object_legacy(file_path):
    file_path = os.path.expanduser(file_path)
    with open(file_path, 'rb') as fh:
        data = pickle.load(fh, encoding='bytes')
    return data


def findClosest(datapt, seq):
    # Given two numpy arrays with the same dimensionality
    # find the closest location
    #axval = np.argmax(datapt.shape == seq.shape)
    #return np.argmin(np.lingalg.norm(seq - datapt, axis=axval))
    return np.argmin(np.abs(seq - datapt))


def getPerformance(y_true, y_pred, calc_evt):
    # Return all relevant performance metrics
    # Do not consider elements with -1
    if calc_evt:
        labels_gt = copy.deepcopy(y_true)
        labels_pr = copy.deepcopy(y_pred)
        labels_gt, labels_pr = convertToZem_format(labels_gt, labels_pr)
        L = len(labels_gt)  # length of data
        T = np.array(range(0, L))

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

    if calc_evt:
        etdata_gt_ = np.core.records.fromarrays([T,
                              np.zeros(L), np.zeros(L),
                              np.ones(L), labels_gt],
                              dtype=ETData.dtype)
        etdata_pr_ = np.core.records.fromarrays([T,
                              np.zeros(L), np.zeros(L),
                              np.ones(L), labels_pr],
                              dtype=ETData.dtype)
        etdata_gt_ = np.array(etdata_gt_, dtype=ETData.dtype)
        etdata_pr_ = np.array(etdata_pr_, dtype=ETData.dtype)
        # create instances for ground truth label and predicted label
        etdata_gt = ETData()
        etdata_pr = ETData()
        etdata_gt.load(etdata_gt_,source='array')
        etdata_pr.load(etdata_pr_,source='array')
        ke = calc_ke(etdata_gt,etdata_pr)
    else:
        ke = (0, 0, 0)
    return (Perf, ke)


def convertToZem_format(gt, pd):
    # Current range: [-1, 0, 1, 2]
    gt = gt + 1
    pd = pd + 1
    # The unknown class should be 0.
    # Current range: [0, 1, 2, 3]
    return (gt, pd)


def generateIdx(Data_dict, batch_size, oversampleRatio=1):
    # Given the number of samples and a batch size,
    # Randomly divide the indices into batches.
    # Data_dict: Input dictionary with the following keys
    # Data_dict['Data']: Entries
    # Data_dict['Freq']: Distribution of samples in each entry
    if oversampleRatio <= 0.0:
        oversample = False
        print('Oversampling off')
    else:
        oversample = True

    # Find all entries with pursuits
    if oversample:
        #print('Over-sampling Pursuits. Ratio calculated automatically.')
        evtRatio = []
        for entry in Data_dict['Freq']:
            # Mark a one even if a single sample exists
            evtRatio.append(entry > 0)
        evtRatio = np.array(evtRatio)
        ratio = np.sum(evtRatio, axis=0)
        purUp = np.floor(oversampleRatio*ratio[0]/ratio[1])
        #print('Up-sampling pursuits by a factor of: {}'.format(purUp))

        loc = evtRatio[:, 1].astype(bool)
        loc = np.where(loc)[0].squeeze() # Return all indices with pursuits
        appenSeq = np.tile(loc, int(purUp)) # Repeat pursuits approximately 15 times
        origSeq = np.array(range(0, len(Data_dict['Data'])))
        samplesList = np.concatenate([origSeq, appenSeq], axis=0)
    else:
        origSeq = np.array(range(0, len(Data_dict['Data'])))
        samplesList = origSeq
        #print('Not over-sampling to protect original distribution.')

    num_samples = len(samplesList)
    num_batches = np.ceil(num_samples/batch_size).astype(np.int)
    np.random.shuffle(samplesList)
    batchIdx_list = []
    for i in range(0, num_batches):
        y = (i+1)*batch_size if (i+1)*batch_size<num_samples else num_samples
        batchIdx_list.append(samplesList[i*batch_size:y])
    return batchIdx_list


def getListEntries(ListSource, Idx):
    return [ListSource[i] for i in Idx]


def orderData(ip, iplens):
    # This function sorts the input lists by their len. By default, argsort returns
    # the ascending order. Simply negate the elements to get the descending order.
    # Do not add padding at this stage, padding and should be done independently.
    idx = np.argsort(-np.asarray(iplens))
    ip = getListEntries(ip, idx)
    return ip


def extract(data, onlyEyes):
    # Split a chunk into data, targets and class counts.
    # Convert MATLAB format into numpy array
    tempTrain = []
    tempTargets = []
    tempFreq = []
    tempWeight = []
    for chunk in data:
        if onlyEyes:
            # Extract only the first 3, i.e, EIH vectors.
            tempTrain.append(torch.from_numpy(np.array(chunk)[:, :3]))
        else:
            if np.array(chunk).shape[1] <= 8:
                # Extract all the dimensions except the final label column
                tempTrain.append(torch.from_numpy(np.array(chunk)[:, :-1]))
            elif np.array(chunk).shape[1] == 9:
                # Weight needs to be extracted. It is the second last column
                tempTrain.append(torch.from_numpy(np.array(chunk)[:, :-2]))
                tempWeight.append(torch.from_numpy(np.array(chunk)[:, -2]))
        tempTargets.append(torch.from_numpy(np.array(chunk)[:, -1]))
        numFix = np.sum(np.array(chunk)[:, -1] == 0)
        numPur = np.sum(np.array(chunk)[:, -1] == 1)
        numSac = np.sum(np.array(chunk)[:, -1] == 2)
        tempFreq.append(np.array([numFix, numPur, numSac]))
    if not tempWeight:
        return (tempTrain, tempTargets, tempFreq)
    else:
        return (tempTrain, tempTargets, tempFreq, tempWeight)

def convertToSet(ip1=None, ip2=None, ip3=None, typeClass=torch.double):
    # Function smashes all elements into one giant list
    # ip1 -> Input features
    # ip2 -> Targets (forced to torch.long)
    # ip3 -> Weights
    temp1 = []
    temp2 = []
    temp3 = []
    SeqLens = []

    for i in range(len(ip1)):
        t = time.time()
        SeqLens.append(np.asarray(ip1[i]).shape[0])
        temp1.append(torch.from_numpy(np.asarray(ip1[i])).type(typeClass))
        temp2.append(torch.from_numpy(np.asarray(ip2[i])).type(torch.long))
        if ip3 is not None:
            temp3.append(torch.from_numpy(np.asarray(ip3[i])).type(typeClass))
        #print('Trial {} of {} done. Time taken: {}'.format(i, len(ip1), time.time() - t))
    return (temp1, temp2, temp3, SeqLens)


def velocityFromVector(ip):
    A = np.sum(ip[2:,:]*ip[:-2,:], axis=1)
    B = np.cross(ip[2:,:], ip[:-2,:])
    B = np.sqrt(np.sum(np.square(B), axis=1))
    V = np.tanh(B/A)
    return np.pad(V, (1,1), 'reflect')

def calc_ke(etdata_gt,etdata_pr):

    class_map_func  = np.vectorize(map_func)

    #human format coding scheme
    classes = [
        0, #undef
        1, #fixation
        2, #pursuit
        3, #saccade
        9  #everything else
    ]
    #internal coding scheme
    class_mapper = {k:v for k, v in zip (classes, np.arange(len(classes)))}

    #leaves original predictions untouched
    _etdata_gt = copy.deepcopy(etdata_gt)
    _etdata_pr = copy.deepcopy(etdata_pr)

#    #analyse only fixations, saccades and pso
#    mask_gt = _etdata_gt.data['evt']==0 # original undef
#    _etdata_gt.data['evt'][mask_gt] = 0
#    mask_pr = ~np.in1d(_etdata_pr.data['evt'], [1, 2, 3, 4, 5])
#    _etdata_pr.data['evt'][mask_pr] = 9 #sets everything else to "other"
#    _etdata_pr.data['evt'][mask_gt] = 0 #undef must be the same in both

    #internal class mapping
    _etdata_gt.data['evt'] = class_map_func(_etdata_gt.data['evt'], class_mapper)
    _etdata_pr.data['evt'] = class_map_func(_etdata_pr.data['evt'], class_mapper)

    #evaluate per trial
    ke, (evt_overlap, _evt_gt, _evt_pr) = eval_evt(_etdata_gt, _etdata_pr, len(classes))
    ke_single =tuple(ke[:3])
    return ke_single

def map_func(val, dictionary):
    return dictionary[val] if val in dictionary else val


def __main__():
    print('Main function')
