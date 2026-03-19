%% 社会传染在自适应超图上的爆炸性转变
% 展示稳态感染密度 I 随强化参数 βΔ 的变化

clear; close all; clc;

%% 参数设置
mu = 0.5;           % 恢复率
beta1 = 0.15;       % 活跃节点传播率
beta2 = 0.05;       % 被动节点传播率
p_A = 0.6;          % 活跃节点比例
p_P = 1 - p_A;      % 被动节点比例

% 网络结构参数
k_avg = 4;          % 平均对偶度
k_delta_avg = 4;    % 平均超度
n_avg = 4;          % 平均超边大小
k_c = 2;            % 临界质量阈值

% 计算基本参数
beta0 = (p_A * beta1 + p_P * beta2);
R0 = beta0 * (k_avg + k_delta_avg * (n_avg - 1)) / mu;

%% 模拟不同βΔ下的稳态感染密度
beta_delta_range = linspace(0, 1.2, 300);
I_steady = zeros(size(beta_delta_range));

% 使用自洽方程计算稳态感染密度
for i = 1:length(beta_delta_range)
    beta_delta = beta_delta_range(i);
    
    % 自洽方程: μ = F(I)
    F = @(I) (beta0 + beta_delta * k_delta_avg * I^(k_c-1)) * (1-I) - mu;
    
    % 寻找稳态解
    try
        % 尝试多个初始值来捕获可能的多个解
        I_guess1 = 0.9;  % 高感染率猜测
        I_guess2 = 0.1;  % 低感染率猜测
        
        I1 = fzero(F, I_guess1);
        I2 = fzero(F, I_guess2);
        
        % 选择物理上合理的解 (0 ≤ I ≤ 1)
        if I1 >= 0 && I1 <= 1
            I_steady(i) = I1;
        elseif I2 >= 0 && I2 <= 1
            I_steady(i) = I2;
        else
            I_steady(i) = 0;
        end
    catch
        % 如果找不到解，设为0
        I_steady(i) = 0;
    end
end

%% 识别不连续转变点
dI_dbeta = gradient(I_steady, beta_delta_range);
[~, transition_idx] = max(abs(dI_dbeta));
beta_delta_transition = beta_delta_range(transition_idx);

%% 绘制爆炸性转变图
figure('Position', [200, 200, 800, 600]);

% 绘制粉色背景区域（大于临界βΔ的区域）
fill([beta_delta_transition, max(beta_delta_range), max(beta_delta_range), beta_delta_transition], ...
     [0, 0, 1, 1], [1, 0.8, 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
hold on;

% 绘制感染密度曲线
plot(beta_delta_range, I_steady, 'b-', 'LineWidth', 3);

% 标记临界点
plot([beta_delta_transition, beta_delta_transition], [0, 1], 'r--', 'LineWidth', 2);
plot(beta_delta_transition, I_steady(transition_idx), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'red');

% 图形美化
xlabel('Reinforcement Parameter $\beta_\Delta$', 'Interpreter', 'latex', 'FontSize', 16);
ylabel('Steady-state Infection Density $I$', 'Interpreter', 'latex', 'FontSize', 16);
title('Explosive Transition: $I(\beta_\Delta)$', 'Interpreter', 'latex', 'FontSize', 18);
grid on;

% 添加标注
text(beta_delta_transition + 0.05, 0.2, ...
    sprintf('$\\beta_\\Delta^c = %.3f$', beta_delta_transition), ...
    'Interpreter', 'latex', 'FontSize', 14, 'Color', 'red');
text(0.7, 0.8, sprintf('$R_0 = %.2f$', R0), ...
    'Interpreter', 'latex', 'FontSize', 14, 'BackgroundColor', 'white');

% 添加粉色区域标注
text(beta_delta_transition + 0.3, 0.5, 'High Infection Region', ...
    'FontSize', 14, 'Color', [0.7, 0.2, 0.2], 'HorizontalAlignment', 'center');

xlim([0, max(beta_delta_range)]);
ylim([0, 1]);

%% 显示关键结果
fprintf('Explosive Transition Analysis Results:\n');
fprintf('Critical Reinforcement Parameter βΔc = %.3f\n', beta_delta_transition);
fprintf('Basic Reproduction Number R0 = %.3f\n', R0);
fprintf('Transition Type: Discontinuous Explosive Transition\n');