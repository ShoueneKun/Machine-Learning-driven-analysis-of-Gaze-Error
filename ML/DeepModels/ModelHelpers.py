import torch
import torch.nn as nn

class linStack(nn.Module):
    """A stack of linear layers followed by batch norm and hardTanh

    Attributes:
        num_layers: the number of linear layers.
        in_dim: the size of the input sample.
        hidden_dim: the size of the hidden layers.
        out_dim: the size of the output.
    """
    def __init__(self, num_layers, in_dim, hidden_dim, out_dim, dp):
        super().__init__()

        layers_lin = []
        layers_norm = []
        for i in range(num_layers):
            m = nn.Linear(hidden_dim if i > 0 else in_dim,
                hidden_dim if i < num_layers - 1 else out_dim)
            layers_lin.append(m)
            layers_norm.append(nn.BatchNorm1d(hidden_dim if i < num_layers -1 else out_dim, affine=True))
        self.layersLin = nn.ModuleList(layers_lin)
        self.layersNorm = nn.ModuleList(layers_norm)
        self.act_func = nn.LeakyReLU()
        self.dp = nn.Dropout(p=dp)

    def forward(self, x):
        # Input shape (batch, sequence, features)
        for i, _ in enumerate(self.layersLin):
            x = self.layersLin[i](x)
            x = x.permute(0, 2, 1) # (batch, features, sequence)
            x = self.act_func(x)
            x = self.layersNorm[i](x)
            x = x.permute(0, 2, 1) # (batch, sequence, features)
            x = self.dp(x)
        return x

class gruStack(nn.Module):
    """A stack of GRU units with batch norm.
    Note that the last GRU unit will have not
    have batch norm. SOF says that batch norm before
    FC layer will effect performance.

    Attributes:
            num_layers: the number of stacked GRU units.
            in_dim: features in input.
            hidden_dim: hidden features.
            out_dim: final size of output.
    """
    def __init__(self, num_layers, in_dim, hidden_dim, out_dim, dir_flag=True):
        super().__init__()
        layers_gru = []
        layers_iNorm = []
        for i in range(num_layers):
            m = nn.BatchNorm1d(2*hidden_dim if i > 0 else in_dim, affine=False)
            layers_iNorm.append(m)
            m = nn.GRU(2*hidden_dim if i > 0 else in_dim, hidden_dim if i < num_layers - 1 else out_dim,
                1, batch_first=True, bidirectional=dir_flag)
            m.flatten_parameters()
            layers_gru.append(m)
        self.gruList = nn.ModuleList(layers_gru)
        self.normList = nn.ModuleList(layers_iNorm)

    def forward(self, x):
        # Input data: (batch, sequence, features)
        # Norm function format: (batch, features, sequence)
        # Optionally returns the hidden states as (2/1, batch, hidden, layers)
        hd = []
        for i, _ in enumerate(self.gruList):
            #x = x.permute(0, 2, 1) # Permute for norm
            #x = self.normList[i](x).permute(0, 2, 1)
            x, h = self.gruList[i](x) # Output from GRU
            hd.append(h)
        return (x, hd)

def weights_init(ObjVar):
    # Function to initialize weights
    for name, val in ObjVar.named_parameters():
        if 'weight' in name and len(val.shape) >= 2:
            nn.init.xavier_normal_(val, gain=1)
        elif 'bias' in name:
            nn.init.zeros_(val)
        elif ('nalu' in name) or ('nac' in name):
            nn.init.zeros_(val)
        else:
            print('{}. No init.'.format(name))
    return ObjVar

class dBlock(nn.Module):
    def __init__(self, in_c, out_c, dp=0.0):
        super().__init__()
        self.c1 = nn.Conv1d(in_channels=in_c,
                            out_channels=out_c,
                            kernel_size=3,
                            stride=2,
                            padding=1,
                            dilation=1,
                            bias=True)
        self.c2 = nn.Conv1d(in_channels=in_c,
                            out_channels=out_c,
                            kernel_size=3,
                            stride=2,
                            padding=3,
                            dilation=3,
                            bias=True)
        self.choke = nn.Conv1d(in_channels=2*out_c,
                               out_channels=out_c,
                               kernel_size=1,
                               stride=1)
        self.dp = nn.Dropout(dp)
    def forward(self, x):
        # The input is of the form [N, C, L]
        x1 = self.c1(x)
        x2 = self.c2(x)
        x = torch.cat([x1, x2], dim=1)
        x = self.dp(self.choke(x))
        return (x, [x1, x2])

class uBlock(nn.Module):
    def __init__(self, in_c, out_c):
        super().__init__()
        self.c1 = nn.ConvTranspose1d(in_channels=in_c,
                                     out_channels=out_c,
                                     kernel_size=3,
                                     stride=2,
                                     padding=1,
                                     dilation=1)
        self.c2 = nn.ConvTranspose1d(in_channels=in_c,
                                     out_channels=out_c,
                                     kernel_size=3,
                                     stride=2,
                                     padding=3,
                                     dilation=3)
        self.choke = nn.Conv1d(in_channels=out_c*2,
                               out_channels=out_c,
                               kernel_size=1,
                               stride=1)
    def forward(self, x, connList):
        x1 = torch.cat([x, connList[0]], dim=1)
        x2 = torch.cat([x, connList[1]], dim=1)
        x1 = self.c1(x1)
        x2 = self.c2(x2)
        x = self.choke(torch.cat([x1, x2], dim=1))
        return x