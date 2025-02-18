%% 迭代计算最优的编码
function Bv = Pv_optim(classerpath)
model = load(classerpath);
Conf_Mat = model.Conf_Mat;
% Pv 初值
Pv = [-sqrt(2)  sqrt(2);
      -sqrt(2) -sqrt(2);
       sqrt(2)  sqrt(2);
       sqrt(2) -sqrt(2);
      -2        0;
       0        2;
       0       -2;
       2        0];
% Pv = [-0.5176  1.9319;
%       -0.5176 -1.9319;
%        0.5176  1.9319;
%        0.5176 -1.9319;
%       -2        0;
%        0        2;
%        0       -2;
%        2        0];

dx = pi/36;
P_tar = [cos(dx:dx:2*pi); sin(dx:dx:2*pi)]';
P_tar = [P_tar; [cos(pi*3/2:dx:2*pi); sin(pi*3/2:dx:2*pi)]'];


for epoch = 1
    Prob = P_tar * Pv' ./ (sqrt(sum(P_tar.^2, 2)) * sqrt(sum(Pv.^2, 2))');
    Prob = pi - abs(acos(Prob));
    Prob = Prob.^3;
    human_move = zeros(size(Prob));

    % 循环遍历每一行
    for i = 1:size(Prob, 1)
        [sorted_row, idx] = sort(Prob(i, :), 'descend');
        human_move(i, idx(1:3)) = sorted_row(1:3);
        human_move(i, :) = human_move(i, :) ./ sum(human_move(i, :));
    end

    % loss = norm(human_move*Conf_Mat*Pv - P_tar);   % 误差
    % Pv = Pv + 0.001 * (human_move*Conf_Mat*Pv - P_tar);
    % Pv = 0.3*pinv(human_move*Conf_Mat) * P_tar + 0.7*Pv;  % Pv更新
    % fprintf('epoch %d, loss %.3f \n', epoch, loss);
end

B = Conf_Mat' * human_move' * P_tar;
for i = 1:8
    Bv(i, :) = B(i, :) / norm(B(i, :));
end


Cmp = [0 0.4470 0.7410;
    0.8500 0.3250 0.0980;
    0.9290 0.6940 0.1250;
    0.4940 0.1840 0.5560;
    0.4660 0.6740 0.1880;
    0.2118 0.8392 1.00;
    0.6350 0.0780 0.1840;
    0.8353 0.2196 1.00];

for i = 1:8
    Bv(i, :) = B(i, :) / norm(B(i, :));
    quiver(0, 0, Bv(i, 1), Bv(i, 2), 'Color', Cmp(i, :), 'LineWidth', 1.2);
    hold on
end

xline(0, '--');
yline(0, '--');
axis equal 
axis([-1 1 -1 1]);
box off


% scatter(H(:, 1), H(:, 2), [], 'b', 'filled');



%% 类平均的间距分析
% ylab = Preprocess_funy(Ylab);
% X = permute(Preprocess_funx(Spectra), [3 1 2]);
% X = X(:, :);
% 
% condu = [101 102 103 104 121 122 125 126];
% Tbox = {'LE', 'LH', 'RE', 'RH', 'LE&LH', 'LE&RE', 'LH&RH', 'RE&RH'};
% 
% X = X(ismember(Ylab, condu), :);
% ylab = ylab(ismember(Ylab, condu));
% 
% Xs = zeros(length(condu), size(X, 2));
% for i = 1:1:length(condu)
%     Xs(i, :) = mean(X(ylab==condu(i), :));
% end
% 
% Xem = [Xs; X];
% 
% 
% D = pdist(Xem, 'mahalanobis');
% D = squareform(D);
% 
% % 进行层次聚类
% Z = linkage(D(1:8, 1:8), 'complete'); % 使用完全连接聚类算法
% Z = dendrogram(Z,'ColorThreshold', 14);
% set(Z, 'LineWidth', 1.2);
% ylabel('Cluster Distance', "Interpreter", "latex");
% xticks(1:8);
% xticklabels(Tbox(str2num(xticklabels)'));
% title('Hierarchical Clustering', "Interpreter", "latex");



%% 有监督 SOM 生成控制平面
% Cmp = [0 0.4470 0.7410;
%     0.8500 0.3250 0.0980;
%     0.9290 0.6940 0.1250;
%     0.4940 0.1840 0.5560;
%     0.4660 0.6740 0.1880;
%     0.2118 0.8392 1.00;
%     0.6350 0.0780 0.1840;
%     0.8353 0.2196 1.00];
% 
% [~, Pv] = control_plane_som(D(1:8, 1:8), [4 6 2 8 5 3 7 1]);
% for i = 1:8
%     polarscatter(Pv(end,i), abs(exp(1j*Pv(end,i))), 14, Cmp(i, :), 'filled')
%     hold on
% end
% set(gca,'rTicklabel',[])
% thetaticks(gca,[0 45 90 135 180 225 270 315])
% legend(Tbox);



