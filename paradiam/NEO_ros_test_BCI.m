%% 初始化
clear;
clc;
if count(py.sys.path, 'E:/pycharm/MyCode/Psy_tuto/centerout-valid/device/') == 0
    insert(py.sys.path, int32(0), 'E:/pycharm/MyCode/Psy_tuto/centerout-valid/device/');
end

% 务必添加这几句启动
% set ROS_IP=192.168.1.8
% set ROS_HOSTNAME=192.168.1.8
% roslaunch C:\ros_med\wheel_control\static\src\road_line.launch

% 初始化客户端和同步盒
import py.data_client.NeuracleDataClient
import py.trigger_box.TriggerNeuracle

receiver = py.data_client.NeuracleDataClient();
Trigger = py.trigger_box.TriggerNeuracle("COM3");

pause(3);


if ros.internal.Global.isNodeActive
    rosshutdown
end


% 初始化ROS网络，连接到ROS主节点
rosinit('http://127.0.0.1:11311');

% 创建一个发布者，发布到话题 '/cmd_vel'
pub = rospublisher('/cmd_vel', 'geometry_msgs/Twist',"DataFormat","struct");
odomSub = rossubscriber('/odom', 'nav_msgs/Odometry',"DataFormat","struct");


% 获取小车状态
robot = rossvcclient('/gazebo/get_model_state');
robot_req = rosmessage(robot);
robot_req.ModelName = 'robot';
robot_req.RelativeEntityName = 'ground_plane';

Controller = Wheel_control('./par_model/wheel_model.mat');


%% start routine
pause(3);
tic;

p_time = toc;
Trigger.send_trigger();

for hh = 1:10000
    a = toc;
    rr = call(robot, robot_req);
    % rr.Pose.Position.Y 

    data = cell(receiver.get_trial_data());
    X = double(data{3}.flatten().tolist());
    X = reshape(X, 1000, 8)' / 1e-6;
    X = X - repmat(mean(X), size(X, 1), 1);
    [spectra, ~] = Online_psd(X, 1000, 100, 256);

    Controller.timer_handler(odomSub);
    Controller.online_task(spectra, pub);

    pause(0.2 - (toc - a) - 0.004);
    [~, pred] = max(Controller.Behave(Controller.hh-1).posterior);
    sprintf(['pred:' num2str(pred)  '  dt:' '%.4f'], toc - a)
    
end

receiver.close();






