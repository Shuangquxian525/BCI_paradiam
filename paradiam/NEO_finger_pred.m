%%
% pyversion D:\Anaconda\python.exe;
close all
clear;clc
if count(py.sys.path, 'E:/pycharm/MyCode/Psy_tuto/centerout-valid/device/') == 0
    insert(py.sys.path, int32(0), 'E:/pycharm/MyCode/Psy_tuto/centerout-valid/device/');
end


import py.data_client.NeuracleDataClient
import py.trigger_box.TriggerNeuracle


receiver = py.data_client.NeuracleDataClient(buffer_len=1.);  
Trigger = py.trigger_box.TriggerNeuracle("COM5");

classer = load('E:\MATLAB_softhub\SPMdataset\NEO_BCI\Paradiam\par_model\TT_gesture_1125.mat');

pause(2);
figure("Position", [3055.7,-308.3,1442.6,1023.3], "Color", [1 1 1])
AX1 = axes('Position', [0 0 1 1]);

Num = 100;
cond = {'F1', 'F2', 'F3', 'F4', 'F5'};
% cond = {'power', 'pinch', 'tripod', 'index', 'thumb'};
Ranks = repmat([1:5]', 1, Num/5);
Ranks = Ranks(:);
Ranks = Ranks(randperm(Num));

for h = 1:Num
    % 准备 ********************************************
    cla(AX1);
    axis(AX1, [-5 5 -5 5]);
    text(AX1, 0, 0, ['准备; ' num2str(Ind)], 'HorizontalAlignment', 'center', 'FontSize', 50, 'FontWeight' ,'bold');
    Trigger.send_trigger(int32(0));
    pause(2);

    % 开始 ********************************************
    cla(AX1);
    imshow(['.\Figs_u\' cond{Ranks(h)} '.png'], 'Parent', AX1);
    Trigger.send_trigger(int32(Ranks(h)));
    pause(1.5);
    tic
    [res, pred] = online_pred(receiver, Ranks(h), classer);
    pause(1 - toc + tic);

    % 显示结果 ********************************************
    cla(AX1);
    if res
        imshow('.\Figs_u\right.png', 'Parent', AX1);
    else
        imshow('.\Figs_u\error.png', 'Parent', AX1);
    end
    pause(0.7);

    % 休息 ********************************************
    cla(AX1);
    text(AX1, 0, 0, '休息', 'HorizontalAlignment', 'center', 'FontSize', 50, 'FontWeight' ,'bold');
    pause(1.8);

end


%%
function [res, pred] = online_pred(receiver, ground, classer)

data = cell(receiver.get_trial_data());
X = double(data{3}.flatten().tolist());
X = reshape(X, 1000, 8)' / 1e-6;
X = X - repmat(mean(X), size(X, 1), 1);
[spectra, fb] = Online_psd(X, 1000, 150, 256);
X = log10(spectra);
X = (X(:)' - classer.model.meanX) ./ classer.model.stdX;
[pred, prob] = predict(classer.model, X);

if pred == ground
    res = 1;
else
    res = 0;
end

end
