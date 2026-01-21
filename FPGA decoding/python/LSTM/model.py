# -*- coding: utf-8 -*-
"""
Created on Mon Jul 11 00:54:53 2022

@author: 24233
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
import scipy.io as io
import scipy.io
import time
import math
import os

class LSTM_Net(nn.Module):
    
    def __init__(self,input_size,hidden_size,output_size,bidirectional):
        super(LSTM_Net,self).__init__()
        self.input_size=input_size
        self.output_size=output_size
        self.dropout1=nn.Dropout(0.2)
        self.lstm=nn.LSTM(input_size,hidden_size,1,batch_first=True,bidirectional=bidirectional)
        self.dropout2=nn.Dropout(0.2)
        if bidirectional:
            self.fc1=nn.Linear(2*hidden_size, output_size)
        else:
            self.fc1=nn.Linear(hidden_size, output_size)
        
    def forward(self,x,hc=0,drop=1):


        res=x.t()
        if drop==1:
            res=self.dropout1(res)
        if type(hc)!=int:
            res,hcn=self.lstm(res.unsqueeze(0),hc)
        elif type(hc)==int and hc!=0:
            res,hcn=self.lstm(res.unsqueeze(0))
        else:
            res,_=self.lstm(res.unsqueeze(0))
        if drop==1:
            res=self.dropout2(res)
        io.savemat('res.mat', {'res': res.detach()})
        io.savemat('res_elu.mat', {'res_elu': (F.elu(res)).detach()})
        res=self.fc1(F.elu(res))

        io.savemat('resfc.mat', {'resfc': res.detach()})
        if type(hc)!=int:
            hcn=tuple([i.detach() for i in hcn])
            return res.squeeze(0).t(),hcn
        elif type(hc)==int and hc!=0:
            hcn=tuple([i.detach() for i in hcn])
            return res.squeeze(0).t(),hcn
        else:
            return res.squeeze(0).t()
        


class trainer():
    
    def __init__(self,net,optimizer,loss_fn):
        self.net=net
        self.optimizer=optimizer
        self.loss_fn=loss_fn

    def train_one_turn(self,data_list,vel_list):
        train_loss=np.zeros(len(data_list))
        for i in range(len(data_list)):
            res=self.net(data_list[i],drop=0)
            
            los=self.loss_fn(res,vel_list[i])
            
            self.optimizer.zero_grad()
            los.backward()
            self.optimizer.step()
            train_loss[i]=float(los)
        return train_loss
    
    def test(self,test,vel,return_res=0):
        res=self.net(test,drop=0)
        

        # 读取MAT文件
        mat_data = scipy.io.loadmat('example_data.mat')

        # 提取数组
        loaded_array = mat_data['a0']

        # 将NumPy数组转换为PyTorch张量
        pytorch_tensor = torch.tensor(loaded_array)
        los = self.loss_fn(res, vel)
        mse=float(los)
        mse_loss = nn.MSELoss()
        loss = mse_loss(pytorch_tensor, vel)
        #los1 = self.loss_fn(loaded_array, vel)
        if return_res==0:
            return mse,vel.shape[1]
        else:
            x_cc=float(torch.corrcoef(torch.stack([res[0],vel[0]],axis=0))[0,1])
            y_cc=float(
                (torch.stack([res[1],vel[1]],axis=0))[0,1])
            return x_cc,y_cc,mse,res.detach().cpu().numpy()
    
    def net_save(self,path):
        torch.save(self.net.state_dict(),path)
        return
        
    def net_load(self,path):
        self.net.load_state_dict(torch.load(path))
        return


    def net_load0(self,path):
        self.net.load_state_dict(torch.load(path))
        weights = torch.load(path)
        params = self.net.fc1.weight

        # 量化
        def q_weight(data_in):
            X_row = np.size(data_in, 0)  # 计算 X 的行数
            X_col = np.size(data_in, 1)  # 计算 X 的列数
            for i in range(X_row):
                for j in range(X_col):
                    data_in[i, j] = round(float(data_in[i, j] * 32768 / 512)) / 64

            return data_in

        def q_weight0(data_in, size):

            for j in range(size):
                data_in[j] = round(float(data_in[j] * 32768)) / 32768

            return data_in

        def q_weightfc(data_in):
            X_row = np.size(data_in, 0)  # 计算 X 的行数
            X_col = np.size(data_in, 1)  # 计算 X 的列数
            for i in range(X_row):
                for j in range(X_col):
                    data_in[i, j] = round(float(data_in[i, j] * 32768 / 512)) / 64
            return data_in

        def q_weightfc0(data_in, size):

            for j in range(size):
                data_in[j] = round(float(data_in[j] * 32768)) / 32768

            return data_in
        weights['lstm.weight_ih_l0'] = q_weight(weights['lstm.weight_ih_l0'])
        weights['lstm.weight_hh_l0'] = q_weight(weights['lstm.weight_hh_l0'])
        weights['lstm.bias_ih_l0'] = q_weight0(weights['lstm.bias_ih_l0'], 512 * 4)
        weights['lstm.bias_hh_l0'] = q_weight0(weights['lstm.bias_hh_l0'], 512 * 4)
        # weights['fc.weight'] =q_weight(weights['fc.weight'])
        # weights['fc.bias'] =q_weight0(weights['fc.bias'],output_size)
        weights['fc1.weight'] = q_weightfc(weights['fc1.weight'])
        weights['fc1.bias'] = q_weightfc0(weights['fc1.bias'], 2)

        self.net.load_state_dict(weights)  # 再加载网络的参数
        return

