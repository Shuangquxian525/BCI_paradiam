%%
% pyversion D:\Anaconda\python.exe;
close all
clear;clc
if count(py.sys.path, 'E:/pycharm/MyCode/Psy_tuto/centerout-valid/device/') == 0
    insert(py.sys.path, int32(0), 'E:/pycharm/MyCode/Psy_tuto/centerout-valid/device/');
end


import py.data_client.NeuracleDataClient
import py.trigger_box.TriggerNeuracle


receiver = py.data_client.NeuracleDataClient();
Trigger = py.trigger_box.TriggerNeuracle("COM5");

pause(2);


figure("Position", [3055.7,-308.3,1442.6,1023.3], "Color", [1 1 1])
AX1 = axes('Position', [0 0 1 1]);


% AX2 = axes('Position', [0 0 1 1]);
T = 5;

Ind = 2;
for h = 1:10
    cla(AX1);
    axis(AX1, [-5 5 -5 5]);
    % 准备
    text(AX1, 0, 0, ['准备; ' num2str(Ind)], 'HorizontalAlignment', 'center', 'FontSize', 50, 'FontWeight' ,'bold');
    Trigger.send_trigger();
    pause(1.5);
    data = cell(receiver.get_trial_data());
    X = double(data{3}.flatten().tolist());
    X = reshape(X, 1000, 8)' / 1e-6;
    X = X - repmat(mean(X), size(X, 1), 1);
    [spectra1{h}, fb] = Online_psd(X, 1000, 200);
    pause(0.5);

    % 开始
    cla(AX1);
    text(AX1, 0, 0, ['开始; ' num2str(Ind)], 'HorizontalAlignment', 'center', 'FontSize', 50, 'FontWeight' ,'bold');
    Trigger.send_trigger2();
    pause(1.5);

    data = cell(receiver.get_trial_data());
    X = double(data{3}.flatten().tolist());
    X = reshape(X, 1000, 8)' / 1e-6;
    X = X - repmat(mean(X), size(X, 1), 1);
    [spectra2{h}, fb] = Online_psd(X, 1000, 200);
    pause(1);

    % 休息
    cla(AX1);
    text(AX1, 0, 0, '休息', 'HorizontalAlignment', 'center', 'FontSize', 50, 'FontWeight' ,'bold');
    pause(2.5);
end


%%
figure("Position", [255,135.6,1166,644], "Color", [1 1 1])
for i = 1:8
    AX2{i} = subplot(2, 4, i);
end

REST = 0 * spectra1{1};
TASK = 0 * spectra2{1};

for i = 1:10
    REST = REST + spectra1{i};
    TASK = TASK + spectra2{i};
end


for i = 1:8
    cla(AX2{i});
    plot(AX2{i}, fb, log10(TASK(:, i)./REST(:, i)), 'color', [0 0.4470 0.7410], 'LineWidth', 1.5);
    yline(AX2{i}, 0);
    axis(AX2{i}, [0 200 -1 1]);
end


