# -*- coding: utf-8 -*-
"""
Created on Wed Jan  7 12:10:53 2026

@author: 24233
"""
import numpy as np
import scipy
import scipy.io

def cut(feature_list, mark_list, lists=0):
    if lists == 0:
        start_mark = 0
        end_mark = start_mark
        res = []
        while True:
            start_mark = end_mark
            while True:
                end_mark = end_mark + 1
                if end_mark == len(mark_list) or mark_list[start_mark] != mark_list[end_mark]:
                    break
            res.append(feature_list[:, start_mark:end_mark])
            if end_mark == len(mark_list):
                break
    else:
        start_mark = 0
        end_mark = start_mark
        n = len(mark_list)
        m = len(feature_list)
        res = [[] for i in range(m)]
        while True:
            start_mark = end_mark
            while True:
                end_mark = end_mark + 1
                if end_mark == n or mark_list[start_mark] != mark_list[end_mark]:
                    break
            for i in range(m):
                res[i].append(feature_list[i][:, start_mark:end_mark])
            if end_mark == n:
                break
    return res

class kalman_filter():
    def __init__(self,trainX,trainY):
        """
        trainX : (d, N)  观测序列
        trainY : (m, N)  状态序列
        A      : 状态转移矩阵
        H      : 观测矩阵
        W      : 过程噪声协方差
        Q      : 观测噪声协方差
        """
        X1=trainY[:,0:-1]
        X2=trainY[:,1:]
        A=np.dot(((X2)@(X1.T)),np.mat(X1@(X1.T)).I.A)
        H=np.dot((trainX@(trainY.T)),np.mat(trainY@(trainY.T)).I.A)
        n=trainY.shape[1]
        W=((X2-A@X1)@((X2-A@X1).T))/(n-1)
        Q=((trainX-H@trainY)@((trainX-H@trainY).T))/n
        self.A=A
        self.H=H
        self.W=W + 1e-6 * np.eye(2)
        self.Q=Q + 1e-6 * np.eye(96)
    
    def fit(self,testX,testY):
        m=testY.shape[0]
        n=testX.shape[1]
        prediction=np.zeros((m,n))
        prediction[:,0]=np.ones_like(testY[:,0])
        P=np.eye(m)
        
        for i in range(1,n):
            Xn=self.A@prediction[:,i-1]
            P_=self.A@P@(self.A.T)+self.W
            
            K=P@(self.H.T)@np.linalg.pinv(self.H@P_@(self.H.T)+self.Q)
            prediction[:,i]=Xn+K@(testX[:,i]-self.H@Xn)
            P=(np.eye(m)-K@self.H)@P_

        x_cc=np.corrcoef(testY[0,:],prediction[0,:])
        y_cc=np.corrcoef(testY[1,:],prediction[1,:])
        CC = [x_cc[0,1],y_cc[0,1]];
        MSE = np.square(testY-prediction).mean()
        return CC,MSE,prediction

def get_kalman_result(esa_list,fit_type='vel'):
    target_num=30
    trial_num=90
    cc = np.zeros((trial_num*len(esa_list),2))
    r2 = np.zeros((trial_num*len(esa_list),2))
    mse = np.zeros((trial_num*len(esa_list),1))
    mse_word_average = np.zeros((target_num*len(esa_list),1))
    P=[]
    for j,esa in enumerate(esa_list):
        if fit_type=='pos':
            k=cut(esa['trial_velocity'],esa['trial_mask'][0],lists=0)
            for i in range(len(k)):
                k[i]=np.cumsum(k[i],axis=1)
            esa['trial_velocity']=np.concatenate(k,axis=1)
        # esa['bined_spk']=(esa['bined_spk'].T-esa['bined_spk'].mean(1)).T
        CC = np.zeros((trial_num,2))
        R2 = np.zeros((trial_num,2))
        MSE = np.zeros((trial_num,1))
        MSE_word_average = np.zeros((target_num,1))
        prediction = [0 for i in range(trial_num)]

        for i_target in range(target_num):
            target_ind = np.where(esa['trial_target']-1 == i_target)[0]
            bins_remove = np.concatenate([np.where(esa['trial_mask']-1 == target_ind[i])[1] for i in range(len(target_ind))],axis=0)
            trial_velocity_cv=np.delete(esa['trial_velocity'],bins_remove,axis=1)
            bined_spk_cv=np.delete(esa['bined_spk'],bins_remove,axis=1)
            
            # single model
            model = kalman_filter(bined_spk_cv,trial_velocity_cv)
            for i_ind in range(len(target_ind)):
                CC[target_ind[i_ind],:],MSE[target_ind[i_ind],0],prediction[target_ind[i_ind]] = \
                    model.fit(esa['bined_spk'][:,np.where(esa['trial_mask']-1 == target_ind[i_ind])[1]],esa['trial_velocity'][:,np.where(esa['trial_mask']-1 == target_ind[i_ind])[1]])
            MSE_word_average[i_target,0]=MSE[target_ind,0].mean()
        cc[j*trial_num:(j+1)*trial_num,:]=CC
        r2[j*trial_num:(j+1)*trial_num,:]=R2
        mse[j*trial_num:(j+1)*trial_num,:]=MSE
        mse_word_average[j*target_num:(j+1)*target_num,:]=MSE_word_average
        prediction=np.concatenate(prediction, axis=1)
        P.append(prediction)
    P=np.concatenate(P, axis=1)
    return cc,r2,mse,mse_word_average,P

if __name__ == "__main__":
    data=[scipy.io.loadmat('E:/笔迹拟合/dataset/ESA/0623.mat')]
    _,_,_,_,prediction=get_kalman_result(data)