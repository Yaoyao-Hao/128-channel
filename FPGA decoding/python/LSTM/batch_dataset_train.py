# -*- coding: utf-8 -*-
"""
Created on Fri Aug 12 14:09:03 2022

@author: 24233
"""

# -*- coding: utf-8 -*-
"""
Created on Wed Jul 13 10:46:51 2022

@author: 24233
"""

import os
import torch
import scipy.io
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
from model import*


def cut(feature_list,mark_list,lists=0):
    '''
    根据标志分割特征（时序）
    输入为二维矩阵（通道数×时间步）或元素都是二维矩阵（通道数×时间步）的list（要求时间步长相同），
         一维矩阵（时间步）（要求时间步长与二维矩阵相同），
         输入是否为多个矩阵构成的list，
    输出为二维矩阵的分割结果构成的list（或多个二维矩阵的分割结果构成的list构成的list）
    '''
    if lists==0:
        start_mark=0
        end_mark=start_mark
        res=[]
        while True:
            start_mark=end_mark
            while True:
                end_mark=end_mark+1
                if end_mark==len(mark_list) or mark_list[start_mark]!=mark_list[end_mark]:
                    break
            res.append(feature_list[:,start_mark:end_mark])
            if end_mark==len(mark_list):
                break
    else:
        start_mark=0
        end_mark=start_mark
        n=len(mark_list)
        m=len(feature_list)
        res=[[] for i in range(m)]
        while True:
            start_mark=end_mark
            while True:
                end_mark=end_mark+1
                if end_mark==n or mark_list[start_mark]!=mark_list[end_mark]:
                    break
            for i in range(m):
                res[i].append(feature_list[i][:,start_mark:end_mark])
            if end_mark==n:
                break
    return res

#设置字体为楷体
mpl.rcParams['font.sans-serif'] = ['KaiTi']
# 设置正常显示符号
mpl.rcParams["axes.unicode_minus"] = False

if __name__ == "__main__":
    day='0623'
    daylist=['0614','0616','0623','0624','0630','0701']
    dataset_list=['D:/YCB/YCB/PROJECT/LSTM/lstmmodel/'+day+'.mat']
    
    single_start_path='./single_start_net.pth'
    single_best_path='./single_best_net.pth'

    net_model=LSTM_Net
    loss_fn=nn.MSELoss

    hidden_size=512
    optimizer=torch.optim.Adam
    optimizer_kw={'lr':0.001}#,'weight_decay':1e-5}

    best_end_interval=100

    fit_type=''
    picshow=True


    for dataset in dataset_list:
        a=scipy.io.loadmat(dataset)
        a['bined_spk']=((a['bined_spk'].T-a['bined_spk'].mean(1))).T

        target_num=a['target_hanzi'].shape[1]
        trial_num=a['trial_target'].shape[0]
        net_args=[a['bined_spk'].shape[0],hidden_size,a['trial_velocity'].shape[0],False]
        net_kw={}
        classify_net_args=[a['bined_spk'].shape[0],hidden_size,a['trial_velocity'].shape[0],False]
        classify_net_kw={}
        
        CC = np.zeros((trial_num,2))
        MSE = np.zeros((trial_num,1))
        prediction = [0 for i in range(trial_num)]
        
        single_loss_fn=loss_fn()
        single_net=net_model(*net_args,**net_kw)
        single_optimizer=optimizer(single_net.parameters(),**optimizer_kw)
        single_trainer=trainer(single_net,single_optimizer,single_loss_fn)
        single_trainer.net_save(single_start_path)
        
        for i_target in range(1):#range(a['target_hanzi'].shape[1]):
            target_ind = np.where(a['trial_target']-1 == i_target)[0]
            bins_remove = np.concatenate([np.where(a['trial_mask']-1 == target_ind[i])[1] for i in range(len(target_ind))],axis=0)
            trial_velocity_train=np.delete(a['trial_velocity'],bins_remove,axis=1)
            bined_spk_train=np.delete(a['bined_spk'],bins_remove,axis=1)
            break_ind_train=np.delete(a['break_ind'],bins_remove,axis=1)
            trial_mask_train=np.delete(a['trial_mask'],bins_remove,axis=1)
            trial_velocity_train,bined_spk_train,break_ind_train=cut([trial_velocity_train,bined_spk_train,break_ind_train],trial_mask_train[0],lists=1)
            for i in range(len(trial_velocity_train)):
                if fit_type == 'pos':
                    trial_velocity_train[i]=np.cumsum(trial_velocity_train[i],axis=1)/100
                trial_velocity_train[i]=torch.tensor(trial_velocity_train[i],dtype=torch.float32)
                bined_spk_train[i]=torch.tensor(bined_spk_train[i],dtype=torch.float32)
                break_ind_train[i]=torch.tensor((break_ind_train[i])>0,dtype=torch.int64)
                
            trial_velocity_test=a['trial_velocity'][:,bins_remove]
            bined_spk_test=a['bined_spk'][:,bins_remove]

            # 创建一个字典，将变量存入
            data_to_save = {
                'trial_velocity_test': trial_velocity_train,
                'bined_spk_test': bined_spk_train,
            }

            # 使用 savemat 函数保存为 mat 文件
            scipy.io.savemat('output_data.mat', data_to_save)

            print("数据已保存到 output_data.mat 文件中")

            break_ind_test=a['break_ind'][:,bins_remove]
            trial_mask_test=a['trial_mask'][:,bins_remove]
            trial_velocity_test,bined_spk_test,break_ind_test=cut([trial_velocity_test,bined_spk_test,break_ind_test],trial_mask_test[0],lists=1)
            for i in range(len(trial_velocity_test)):
                if fit_type == 'pos':
                    trial_velocity_test[i]=np.cumsum(trial_velocity_test[i],axis=1)/100
                trial_velocity_test[i]=torch.tensor(trial_velocity_test[i],dtype=torch.float32)
                bined_spk_test[i]=torch.tensor(bined_spk_test[i],dtype=torch.float32)
                break_ind_test[i]=torch.tensor((break_ind_test[i])>0,dtype=torch.int64)

            # single model
            single_trainer.net_load(single_start_path)
            mse_best=1e10
            iteration_best=0
            iteration=0
            
            while True:
                mse=[]
                length=[]
                single_trainer.train_one_turn(bined_spk_train, trial_velocity_train)
                for i in range(len(trial_velocity_test)):
                    mse1,len1=single_trainer.test(bined_spk_test[i], trial_velocity_test[i])
                    mse.append(mse1)
                    length.append(len1)
                mse_sum=0
                len_sum=0
                for i in range(len(mse)):
                    mse_sum=mse_sum+length[i]*mse[i]
                    len_sum=len_sum+length[i]
                mse_sum=mse_sum/len_sum
                if mse_sum<mse_best:
                    mse_best=mse_sum
                    iteration_best=iteration
                    single_trainer.net_save(single_best_path)
                print('{0}-{1}-single MSE:{2}'.format(i_target,iteration,mse_sum))
                        
                if iteration-iteration_best>best_end_interval:
                    break
                iteration=iteration+1
            
            single_trainer.net_load(single_best_path)
            for i in range(len(target_ind)):
                CC[target_ind[i],0],CC[target_ind[i],1],MSE[target_ind[i],0],prediction[target_ind[i]] = single_trainer.test(bined_spk_test[i], trial_velocity_test[i],return_res=1)
            
            if picshow==False:
                None
            else:
                fig,ax=plt.subplots(1,3,figsize=(15, 5))
                fig.suptitle('word:{0},best loss:{1}'.format(str(a['target_hanzi'][0][i_target][0]),mse_best))
                for y in range(3):
                    if fit_type=='pos':
                        ax[y].plot(prediction[target_ind[y]][0],prediction[target_ind[y]][1])
                    else:
                        ax[y].plot(np.cumsum(prediction[target_ind[y]][0]),np.cumsum(prediction[target_ind[y]][1]))
                plt.show()
                plt.close('all')
            
            #qwe=MSE[np.where(MSE>0)[0]]-msasdfa[np.where(MSE>0)[0]]
            #qwem=qwe.mean()
            
    #    pt='D:/YCB/PROJECT/LSTM/lstmmodel/'
    #    create_path=dataset.split('/')[-1].split('.')[0]
    #    os.makedirs(pt+'/{0}'.format(create_path))
    #    np.save(pt+'/{0}/CC.npy'.format(create_path),CC)
    #    np.save(pt+'/{0}/MSE.npy'.format(create_path),MSE)
    #    np.save(pt+'/{0}/prediction.npy'.format(create_path),np.concatenate(prediction,axis=1))