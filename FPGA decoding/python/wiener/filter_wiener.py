import numpy as np
import scipy.io
import matplotlib.pyplot as plt
from sklearn.linear_model import RidgeCV
from sklearn.preprocessing import StandardScaler
import torch
import scipy.io as sio
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


def quantize(data, bits=8, signed=True):
    """
    定点量化函数
    返回: 量化后整数, scale
    """
    if signed:
        qmin = - (2 ** (bits - 1))
        qmax = (2 ** (bits - 1)) - 1
    else:
        qmin = 0
        qmax = (2 ** bits) - 1

    max_abs = np.max(np.abs(data))
    scale = qmax / max_abs if max_abs != 0 else 1

    quantized = np.round(data * scale)
    quantized = np.clip(quantized, qmin, qmax).astype(np.int32)

    return quantized, scale


class kalman_filter():
    def __init__(self, trainX, trainY):
        """
        trainX : (d, N)  观测序列
        trainY : (m, N)  状态序列
        A      : 状态转移矩阵
        H      : 观测矩阵
        W      : 过程噪声协方差
        Q      : 观测噪声协方差
        """
        X1 = trainY[:, 0:-1]
        X2 = trainY[:, 1:]
        A = np.dot(((X2) @ (X1.T)), np.mat(X1 @ (X1.T)).I.A)
        H = np.dot((trainX @ (trainY.T)), np.mat(trainY @ (trainY.T)).I.A)
        n = trainY.shape[1]
        W = ((X2 - A @ X1) @ ((X2 - A @ X1).T)) / (n - 1)
        Q = ((trainX - H @ trainY) @ ((trainX - H @ trainY).T)) / n
        self.A = A
        self.H = H
        self.W = W + 1e-6 * np.eye(2)
        self.Q = Q + 1e-6 * np.eye(96)

    def fit(self, testX, testY,plot=False):
        m = testY.shape[0]
        n = testX.shape[1]
        prediction = np.zeros((m, n))
        prediction[:, 0] = np.ones_like(testY[:, 0])
        P = np.eye(m)

        for i in range(1, n):
            Xn = self.A @ prediction[:, i - 1]
            P_ = self.A @ P @ (self.A.T) + self.W

            K = P @ (self.H.T) @ np.linalg.pinv(self.H @ P_ @ (self.H.T) + self.Q)
            prediction[:, i] = Xn + K @ (testX[:, i] - self.H @ Xn)
            P = (np.eye(m) - K @ self.H) @ P_

        x_cc = np.corrcoef(testY[0, :], prediction[0, :])
        y_cc = np.corrcoef(testY[1, :], prediction[1, :])
        if plot:
            # time = np.arange(Y_true.shape[1])
            # plt.plot(np.cumsum(Y_true[0]), np.cumsum(Y_true[1]))
            #for i in range(self.m):
                plt.figure(figsize=(12, 4))
                # plt.plot(time, Y_true[i], label='True', color='k')
                # plt.plot(time, prediction_float[i], label='Float Pred', color='b', alpha=0.6)
                # plt.plot(time, prediction_quant[i], label='Quant Pred', color='r', alpha=0.6)
                # plt.title(f'Output {i} Trajectory')
                # plt.xlabel('Time step')
                # plt.ylabel('Value')
                # plt.legend()
                # plt.grid(True)
                # plt.tight_layout()

                plt.plot(np.cumsum(prediction[0]), np.cumsum(prediction[1]))
               # plt.plot(np.cumsum(prediction_quant[0]), np.cumsum(prediction_quant[1]))
                plt.show()
        CC = [x_cc[0, 1], y_cc[0, 1]];

        MSE = np.square(testY - prediction).mean()
        return CC, MSE, prediction


class wiener_filter:
    def __init__(self, trainX, trainY, L=1):
        self.d, self.m, self.L = trainX.shape[0], trainY.shape[0], L
        self.scaler = StandardScaler()

        # 构建联合滞后特征
        X_big, Y_big = self._build_big(trainX, trainY)

        # RidgeCV 自动选 λ
        alphas = np.logspace(-4, 2, 20)
        self.model = RidgeCV(alphas=alphas, fit_intercept=False)
        self.model.fit(self.scaler.fit_transform(X_big), Y_big)

        # 权重量化
        self.W_q, self.scale_W = quantize(self.model.coef_, bits=8, signed=True)

    def _build_big(self, X, Y):
        N = X.shape[1]
        from numpy.lib.stride_tricks import sliding_window_view
        X_win = sliding_window_view(X, self.L, axis=1)  # (d, N-L+1, L)
        X_big = X_win.transpose(1, 0, 2).reshape(-1, self.d * self.L)
        Y_big = Y[:, self.L - 1:].T
        return X_big, Y_big

    def fit(self, testX, testY, plot=False):
        X_test, Y_true = self._build_big(testX, testY)
        X_test_scaled = self.scaler.transform(X_test)

        # 浮点预测
        prediction_float = self.model.predict(X_test_scaled).T  # (m, n-L+1)

        # 量化预测
        X_q, scale_X = quantize(X_test_scaled, bits=8, signed=True)
        Y_hat_q = np.dot(self.W_q, X_q.T)
        prediction_quant = Y_hat_q / (self.scale_W * scale_X)

        # 对齐真实值
        Y_true = testY[:, self.L - 1:]

        # 计算浮点版CC和MSE
        cc_float = [np.corrcoef(Y_true[i], prediction_float[i])[0, 1] for i in range(self.m)]
        mse_float = np.square(Y_true - prediction_float).mean()

        # 计算量化版CC和MSE
        cc_quant = [np.corrcoef(Y_true[i], prediction_quant[i])[0, 1] for i in range(self.m)]
        mse_quant = np.square(Y_true - prediction_quant).mean()

        # 绘图
        if plot:
            time = np.arange(Y_true.shape[1])
            plt.plot(np.cumsum(Y_true[0]), np.cumsum(Y_true[1]))
            for i in range(self.m):
                plt.figure(figsize=(12, 4))
                # plt.plot(time, Y_true[i], label='True', color='k')
                # plt.plot(time, prediction_float[i], label='Float Pred', color='b', alpha=0.6)
                # plt.plot(time, prediction_quant[i], label='Quant Pred', color='r', alpha=0.6)
                # plt.title(f'Output {i} Trajectory')
                # plt.xlabel('Time step')
                # plt.ylabel('Value')
                # plt.legend()
                # plt.grid(True)
                # plt.tight_layout()

                plt.plot(np.cumsum(prediction_float[0]), np.cumsum(prediction_float[1]))
                plt.plot(np.cumsum(prediction_quant[0]), np.cumsum(prediction_quant[1]))
                plt.show()

        return cc_float, mse_float, cc_quant, mse_quant, prediction_float, prediction_quant

    def predict(self, X, quant=False):
        X_big, _ = self._build_big(X, np.zeros((self.m, X.shape[1])))
        X_scaled = self.scaler.transform(X_big)
        if not quant:
            return self.model.predict(X_scaled).T
        else:
            X_q, scale_X = quantize(X_scaled, bits=8, signed=True)
            Y_hat_q = np.dot(self.W_q, X_q.T)
            return Y_hat_q / (self.scale_W * scale_X)


def compute_overall_metrics(pred_list, true_list):
    pred_all = np.concatenate(pred_list, axis=1)
    true_all = np.concatenate(true_list, axis=1)
    mse = np.mean((pred_all - true_all)**2)
    cc = np.array([np.corrcoef(pred_all[i], true_all[i])[0, 1] for i in range(pred_all.shape[0])])
    return cc, mse


if __name__ == "__main__":
    dataset = scipy.io.loadmat(r'D:\YCB\YCB\PROJECT\LSTM\lstmmodel\0623.mat')
    a = dataset
    bined_spk, trial_velocity = cut([dataset['bined_spk'], dataset['trial_velocity']], dataset['trial_mask'][0],
                                    lists=1)
    # ===================== Step 2：基础一致性检查 =====================
    assert a['bined_spk'].shape[1] == a['trial_velocity'].shape[1]
    assert a['trial_mask'].shape[1] == a['bined_spk'].shape[1]

    # ===================== Step 3：神经数据预处理 =====================
    # channel-wise 去均值
    #a['bined_spk'] = ((a['bined_spk'].T - a['bined_spk'].mean(1))).T

    # ===================== Step 4：选择 test target（leave-one-target-out） =====================
    fit_type = 'vel'  # 或 'pos'
    i_target = 0  # 当前作为 test 的 target 编号（Python 从 0 开始）

    trial_target = a['trial_target'].reshape(-1)
    trial_mask = a['trial_mask'][0]

    # 找出 test trial 编号
    target_ind = np.where(trial_target - 1 == i_target)[0]

    # ===================== Step 5：找 test bins（核心） =====================
    bins_test = np.concatenate(
        [np.where(trial_mask - 1 == t)[0] for t in target_ind],
        axis=0
    )

    # ===================== Step 6：构造连续时间的 train / test =====================
    trial_velocity_test = a['trial_velocity'][:, bins_test]
    bined_spk_test = a['bined_spk'][:, bins_test]
    break_ind_test = a['break_ind'][:, bins_test]

    trial_velocity_train = np.delete(a['trial_velocity'], bins_test, axis=1)
    bined_spk_train = np.delete(a['bined_spk'], bins_test, axis=1)
    break_ind_train = np.delete(a['break_ind'], bins_test, axis=1)
    trial_mask_train = np.delete(a['trial_mask'], bins_test, axis=1)
    bined_spk_t = np.asarray(bined_spk_test)
    trial_velocity_t = np.asarray(trial_velocity_test)


    save_dict = {
        'bined_spk_t': bined_spk_t,
        'trial_velocity_t': trial_velocity_t,

    }

    sio.savemat('test_target_1_c.mat', save_dict)
    # ===================== Step 7：按 trial_mask 切成 trial（重点） =====================
    trial_velocity_train, bined_spk_train, break_ind_train = cut(
        [trial_velocity_train, bined_spk_train, break_ind_train],
        trial_mask_train[0],
        lists=1
    )

    trial_velocity_test, bined_spk_test, break_ind_test = cut(
        [trial_velocity_test, bined_spk_test, break_ind_test],
        trial_mask[bins_test],
        lists=1
    )

    # ===================== Step 8：trial 级别后处理（LSTM 可直接用） =====================
    for i in range(len(trial_velocity_train)):
        if fit_type == 'pos':
            trial_velocity_train[i] = np.cumsum(trial_velocity_train[i], axis=1) / 100

        trial_velocity_train[i] = torch.tensor(trial_velocity_train[i], dtype=torch.float32)
        bined_spk_train[i] = torch.tensor(bined_spk_train[i], dtype=torch.float32)
        break_ind_train[i] = torch.tensor(break_ind_train[i] > 0, dtype=torch.int64)

    for i in range(len(trial_velocity_test)):
        if fit_type == 'pos':
            trial_velocity_test[i] = np.cumsum(trial_velocity_test[i], axis=1) / 100

        trial_velocity_test[i] = torch.tensor(trial_velocity_test[i], dtype=torch.float32)
        bined_spk_test[i] = torch.tensor(bined_spk_test[i], dtype=torch.float32)
        break_ind_test[i] = torch.tensor(break_ind_test[i] > 0, dtype=torch.int64)
#    dataset_train = scipy.io.loadmat(r'D:\YCB\YCB\PROJECT\LSTM\1_2LSTM_latticeproject\lstmmodel\output_data.mat')
#     bined_spk_train, trial_velocity_train = cut(
#     [dataset_train['bined_spk_test'],
#      dataset_train['trial_velocity_test']],
#     dataset['trial_mask'][0],   # 注意：mask 必须一致
#     lists=1
# )
    # 使用 savemat 函数保存为 mat 文件
 #   scipy.io.savemat('output_data_all.mat', data_to_save)

    print("数据已保存到 output_data.mat 文件中")
    trainX = np.concatenate(bined_spk_train, axis=1)
    trainY = np.concatenate(trial_velocity_train, axis=1)

    filter_ = wiener_filter(trainX, trainY)
    dataset_test = scipy.io.loadmat(r'D:\YCB\YCB\PROJECT\LSTM\lstmmodel\0623.mat')
    float_preds = []
    quant_preds = []
    true_vals = []
    a = 47
    for i in range(1):
        if i == 0:
          #  _, _, _, _, pred_f, pred_q = filter_.fit(bined_spk_test[1], trial_velocity_test[1], plot=True)
            _, _, _, _, pred_f, pred_q = filter_.fit(bined_spk_test[1].numpy(), trial_velocity_test[1].numpy(), plot=True)
        else:
            _, _, _, _, pred_f, pred_q = filter_.fit(bined_spk_test[1].numpy(), trial_velocity_test[1].numpy(), plot=True)

        Y_true = trial_velocity[i][:, filter_.L - 1:]
        float_preds.append(pred_f)
        quant_preds.append(pred_q)
        true_vals.append(Y_true)
    # 写入 float_preds.txt
    with open('float_preds.txt', 'w', encoding='utf-8') as f:
        for i, pred in enumerate(float_preds):
           # f.write(f'--- float_pred[{i}] ---\n')
            np.savetxt(f, np.array(pred), fmt='%.6f')
            f.write('\n')

    # 写入 quant_preds.txt
    with open('quant_preds.txt', 'w', encoding='utf-8') as f:
        for i, pred in enumerate(quant_preds):
           # f.write(f'--- quant_pred[{i}] ---\n')
            np.savetxt(f, np.array(pred), fmt='%.6f')
            f.write('\n')
    # 保存 W_q 到 txt 文件
    np.savetxt("W_q.txt", filter_.W_q, fmt='%d')
    scipy.io.savemat('output.mat', {
        'bined_spk': dataset['bined_spk'],
        'trial_velocity': dataset['trial_velocity'],
        'W_qa': filter_.W_q,
        'scale_W': filter_.scale_W,
    })

    # 计算整体浮点和量化指标
    cc_float_total, mse_float_total = compute_overall_metrics(float_preds, true_vals)
    cc_quant_total, mse_quant_total = compute_overall_metrics(quant_preds, true_vals)
    cc_a_total, mse_a_total = compute_overall_metrics(quant_preds, float_preds)


    print("W_q 已保存为 W_q.txt")
    print("=== 浮点预测 ===")
    print("Overall CC:", cc_float_total)
    print("Overall MSE:", mse_float_total)
    print("\n=== 量化预测 ===")
    print("Overall CC:", cc_quant_total)
    print("Overall MSE:", mse_quant_total)
    print("\n=== 量化预测a ===")
    print("Overall CC:", cc_a_total)
    print("Overall MSE:", mse_a_total)