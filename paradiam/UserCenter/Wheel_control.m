classdef Wheel_control < handle
    properties 
        Behave
        odom_buffer
        hh
        classer
        Timer_id
    end

    methods
        function obj = Wheel_control(classerpath)
            obj.classer = load(classerpath);
            obj.odom_buffer = [];  % odom缓存
            obj.hh = 1;     % 控制计数
            obj.Behave = [];
            obj.Timer_id = timer;
            obj.Timer_id.StartDelay = 0.01;  % 开启的延时生效时间
            obj.Timer_id.Period = 0.1;      % 周期
            obj.Timer_id.ExecutionMode = 'fixedSpacing';
            obj.Timer_id.TasksToExecute = inf;
            % obj.Timer_id.TimerFcn = @(~, ~) obj.timer_handler(obj, odomSub);
        end

        function obj = online_task(obj, spectra, pub)
            [x, z, posterior] = obj.velocity_model(spectra);
            obj.control_pub(pub, x, z);
            obj.Behave(obj.hh).odom_buffer = obj.odom_buffer;
            obj.Behave(obj.hh).posterior = posterior;
            obj.Behave(obj.hh).cmd = [x, z];
            obj.hh = obj.hh + 1;
        end

        function [x, z, posterior] = velocity_model(obj, spectra)

            % 速度控制
            X = log10(spectra);
            X = (X(:)' - obj.classer.meanX) ./ obj.classer.stdX;
            [pred, posterior] = predict(obj.classer.classer, X);

            x = 1-posterior(:, 1).^0.25;
            z = 1-posterior(:, 1).^0.25;

            switch pred
                case 100        % stop
                    x = 0; z = 0;
                case 111        % forward
                    x = 0.35 * x; z = 0;
                case 102        % turn left
                    x = 0; z = 1 * z;
                case 104        % turn right
                    x = 0; z = -0.8* z;
                otherwise
            end

        end

        % 发送消息
        function control_pub(obj, pub, x, z)
            msg = rosmessage(pub);  % 创建一个消息

            % 设置线速度 (linear velocity)
            msg.Linear.X = x; % 向前运动0.5米每秒
            msg.Linear.Y = 0.0;
            msg.Linear.Z = 0.0;

            % 设置角速度 (angular velocity)
            msg.Angular.X = 0.0;
            msg.Angular.Y = 0.0;
            msg.Angular.Z = z; % 每秒0.5弧度的速度旋转
            send(pub, msg);
        end

        function obj = timer_handler(obj, odomSub)
            odomMsg = receive(odomSub, 0.2);
            obj.odom_buffer.position = odomMsg.Pose.Pose.Position;
            obj.odom_buffer.orientation = odomMsg.Pose.Pose.Orientation;
            obj.odom_buffer.linearVelocity = odomMsg.Twist.Twist.Linear;
            obj.odom_buffer.angularVelocity = odomMsg.Twist.Twist.Angular;
        end

        function obj = H_(obj)
            obj.hh = obj.hh + 1;
        end

    end
end




%%
% ylab = Ylab;
% X = log10(Spectra);
% X = permute(X, [3 1 2]);
% X = X(:, :);
% 
% condu = [100 101 102 121];
% Tbox = {'rest', 'LE', 'LH', 'RE\&RH'};
% 
% X = X(ismember(ylab, condu), :);
% ylab = ylab(ismember(ylab, condu));
% meanX = mean(X); stdX = std(X);
% 
% FB = reshape(1:200, 25, 8);
% FB = FB(14:25, :);
% FB = FB(:);
% Norms = zeros(126, 2);
% 
% Norms(100,:) = [mean(X(ylab==100, FB), [1 2]) std(X(ylab==100, FB), [], [1 2])];
% Norms(101,:) = [mean(X(ylab==101, FB), [1 2]) std(X(ylab==101, FB), [], [1 2])];
% Norms(102,:) = [mean(X(ylab==102, FB), [1 2]) std(X(ylab==102, FB), [], [1 2])];
% Norms(105,:) = [mean(X(ylab==105, FB), [1 2]) std(X(ylab==105, FB), [], [1 2])];
% 
% X = zscore(X, [], 1);

