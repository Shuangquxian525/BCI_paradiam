%% view confusion matrix
clear;clc
if count(py.sys.path, 'E:/pycharm/MyCode/NEO-BCI/neuracle-offline/dataloaders/') == 0
    insert(py.sys.path, int32(0), 'E:/pycharm/MyCode/NEO-BCI/neuracle-offline/dataloaders/');
end

% 将 python NEO_data 类导入matlab
import py.tfr_for_mat.NEO_data
NEO_loader = py.tfr_for_mat.NEO_data();
rootDir = 'E:\pycharm\NEOdata\hs01';

Dirs = Return_filelist(rootDir, 'single-MA');
load("par_model\noise_data.mat");


%% 新建数据集
option.fs = 1000;
option.tmin = 0;
option.tmax = 1;
option.fpoint = 201;  % 201;
option.fmax = 100;  % 100;
option.maxnff = 256;  % 256;
option.tps = [-1000, 100, 1100];

[Spectra1, Ylab1, ~] = PSD_dataSet(Dirs, NEO_loader, option);
Spectra = cat(3, Spectra1, Spectra);
Ylab = [Ylab1; Ylab];

clear Spectra1 Ylab1

% save('data_pickle\data.mat', 'Spectra' ,'Ylab', "fb");

%% 查看混淆矩阵
ylab = Ylab;
X = log10(Spectra);
X = permute(X, [3 1 2]);
X = X(:, :);

condu = [100 102 104 111];
Tbox = {'Rest', 'LH', 'RH', 'teeth'};

X = X(ismember(ylab, condu), :);
ylab = ylab(ismember(ylab, condu));

[macroF1, macroACC, Conf_Mat] = cross_vaild(X, ylab, 100);

figure('Position', [573,191,608,566.5]); % 573,433,391.3333333333333,324.5
heatmap(Tbox, Tbox, Conf_Mat);
title(['macroF1 ' num2str(mean(macroF1)), '  macroACC ', num2str(mean(macroACC))]);
annotation('textbox', [.92 .6 .1 .05], 'String', 'Confusion', 'EdgeColor', 'none', 'Rotation', 270, 'FontSize', 11);


%%
ylab = Ylab;
X = log10(Spectra);
X = permute(X, [3 1 2]);
X = X(:, :);
condu = [100 102 104 111];
Tbox = {'Rest', 'LH', 'RH', 'teeth'};

X = X(ismember(ylab, condu), :);
ylab = ylab(ismember(ylab, condu));

meanX = mean(X);
stdX = std(X);
X = zscore(X, [], 1);

classer = fitcdiscr(X, ylab, 'DiscrimType', 'linear', 'Prior', 'uniform', 'Gamma', 0.5);

save("par_model\wheel_model.mat", "meanX", "stdX", "classer", "Conf_Mat");