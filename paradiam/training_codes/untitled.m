%% 全数据分析 时频图
clear; clc;

% 添加 python 代码路径，这里要改成自己的tfr_for_mat.py文件的路径
if count(py.sys.path, 'E:/pycharm/MyCode/NEO-BCI/neuracle-offline/dataloaders/') == 0
    insert(py.sys.path, int32(0), 'E:/pycharm/MyCode/NEO-BCI/neuracle-offline/dataloaders/');
end


% 将 python NEO_data 类导入matlab
import py.tfr_for_mat.NEO_data
NEO_loader = py.tfr_for_mat.NEO_data();

% 定义根目录和要查找的字符串
rootDir = 'E:\pycharm\NEOdata\hs01';
dMA = Return_filelist(rootDir, 'dual');
sMA = Return_filelist(rootDir, 'single');
matchingDirs = [dMA(1) sMA(1)];

option.fs = 1000;
option.tmin = 0;
option.tmax = 1;
option.fpoint = 201;  % 201;
option.fmax = 100;  % 100;
option.maxnff = 256;  % 256;

%%
Spectra = [];
Ylab = [];

for ii = 1:2
    NEO_loader.neo_loadinto(matchingDirs{ii});    % 导入数据
    events = int64(NEO_loader.events);
    data = double(NEO_loader.raw.get_data());
    data = NEO_reref(data/1e-6, 'average');
    events = cat_noise_eve(data, events);

    % 计算功率谱
    [spectra, fb] = neo_calc_spectra(data, events, option);
    Spectra = cat(3, Spectra, spectra);

    Ylab = [Ylab; events(:, 3)];
end




%%
function A = cat_noise_eve(data, events)
for i = 1:8
    U = log(neo_wavelet(data(i,:), 1000, 100:5:200));
    tf(i,:) = mean(U,2);
end
winlength = 400;
pc1s = conv(mean(tf), gausswin(winlength));
pc1s(1:floor(winlength/2-1)) = [];
pc1s((length(pc1s)-floor(winlength/2-1)):length(pc1s))  = [];

A = [];
for i = events(1,1):1000:events(end,1)
    if mean(pc1s(i:i+999)) > 800
        A = [A; [i 0 111]];
    end
end
end