%% ==================== 自适应超图上社交传染的最优阈值计算 ====================
% 基于Twitter hashtag数据的风险分布估计
% 支持论文图1和图2的仿真

clear; clc; close all;
warning('off', 'all');  % 关闭所有警告

%% ==================== 1. 参数设置 ====================
fprintf('===== 自适应超图社交传染最优阈值计算 =====\n\n');

% 数据参数
data_url = 'https://snap.stanford.edu/data/TwtHtag.txt';
data_file = 'TwtHtag.txt';
num_hashtags = 1000;  % 论文中分析的话题数量

% 模型参数（根据论文）
avg_hyperedge_size = 5;  % 平均超边大小?n?=5（表2）
critical_mass_threshold = 2;  % 临界质量阈值k_c=2（表1）

% 分析参数
max_threshold = 10;  % 最大阈值i
num_bins = 50;  % 直方图箱子数量

%% ==================== 2. 数据读取和预处理 ====================
fprintf('正在读取数据...\n');

% 如果文件不存在，尝试下载
if ~exist(data_file, 'file')
    fprintf('正在下载数据...\n');
    try
        websave(data_file, data_url);
        fprintf('数据下载完成。\n');
    catch
        error('无法下载数据文件，请手动下载并放在当前目录。');
    end
end

% 使用textscan读取文件
fid = fopen(data_file, 'r');
if fid == -1
    error('无法打开数据文件。');
end

% 初始化存储数组
peak_mentions = zeros(num_hashtags, 1);

% 逐行读取，假设每行包含128个数值
line_count = 0;
while ~feof(fid) && line_count < num_hashtags
    line = fgetl(fid);
    line_count = line_count + 1;
    
    % 将行分割为数值
    values = str2num(line); %#ok<ST2NM>
    
    if ~isempty(values)
        % 检查是否至少有128个数值
        if length(values) >= 128
            % 找到峰值
            peak_mentions(line_count) = max(values(1:128));
        else
            % 如果不足128个，用现有数据
            peak_mentions(line_count) = max(values);
            fprintf('警告: 第%d行只有%d个数据点\n', line_count, length(values));
        end
    else
        % 如果行是空的，跳过
        line_count = line_count - 1;
    end
end
fclose(fid);

fprintf('成功读取 %d 个话题的数据\n', line_count);

% 调整数组大小
if line_count < num_hashtags
    peak_mentions = peak_mentions(1:line_count);
    num_hashtags = line_count;
    fprintf('实际读取话题数: %d\n', num_hashtags);
end

%% ==================== 3. 数据质量检查和清理 ====================
fprintf('\n数据质量检查...\n');

% 检查并处理零值和负值
zero_indices = find(peak_mentions == 0);
if ~isempty(zero_indices)
    fprintf('发现 %d 个零值，将其替换为小正数\n', length(zero_indices));
    peak_mentions(zero_indices) = 1e-6;
end

% 检查异常值（使用3σ原则）
mean_val = mean(peak_mentions);
std_val = std(peak_mentions);
outlier_indices = find(abs(peak_mentions - mean_val) > 3 * std_val);
if ~isempty(outlier_indices)
    fprintf('发现 %d 个异常值，进行Winsorizing处理\n', length(outlier_indices));
    % 将异常值缩放到3σ范围内
    upper_bound = mean_val + 3 * std_val;
    lower_bound = max(mean_val - 3 * std_val, 0);
    peak_mentions(peak_mentions > upper_bound) = upper_bound;
    peak_mentions(peak_mentions < lower_bound) = lower_bound;
end

% 归一化峰值频率
max_peak = max(peak_mentions);
min_peak = min(peak_mentions);
if max_peak > min_peak
    normalized_peaks = (peak_mentions - min_peak) / (max_peak - min_peak);
else
    % 如果所有值都相同，使用均匀分布
    normalized_peaks = ones(size(peak_mentions)) * 0.5;
end

fprintf('数据范围: [%.2f, %.2f]\n', min_peak, max_peak);
fprintf('归一化范围: [%.4f, %.4f]\n', min(normalized_peaks), max(normalized_peaks));

%% ==================== 4. 计算全局风险分布 P_global ====================
fprintf('\n计算全局风险分布...\n');

% 使用直方图方法（更稳定）
[global_counts, bin_edges] = histcounts(normalized_peaks, num_bins, 'Normalization', 'probability');
P_global = global_counts';
bin_centers = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;

% 确保概率和为1
P_global = P_global / sum(P_global);

% 计算dx（bin宽度）
if length(bin_centers) > 1
    dx = bin_centers(2) - bin_centers(1);
else
    dx = 1;
end

%% ==================== 5. 计算局部风险分布和KL散度 ====================
fprintf('计算局部风险分布和KL散度...\n');

% 阈值范围
i_values = 1:min(max_threshold, floor(num_hashtags/20));
if isempty(i_values)
    i_values = 1:3;  % 至少3个阈值
end

% 初始化存储
P_local_cell = cell(length(i_values), 1);
KL_divergences = zeros(length(i_values), 1);

% 遍历所有阈值
for i_idx = 1:length(i_values)
    i = i_values(i_idx);
    
    % 计算局部风险概率
    local_risk_probs = zeros(size(normalized_peaks));
    
    % 基于二项分布模型：观测到≥i个感染节点的概率
    for h = 1:length(normalized_peaks)
        p_infect = normalized_peaks(h);  % 单个节点感染概率
        
        % 超边中有avg_hyperedge_size-1个其他节点
        n_others = avg_hyperedge_size - 1;
        
        if i <= n_others + 1
            if i == 1
                % 至少一个感染节点
                local_risk_probs(h) = 1 - (1 - p_infect)^n_others;
            elseif i <= n_others
                % 使用二项分布计算
                local_risk_probs(h) = 1 - binocdf(i-1, n_others, p_infect);
            else  % i = n_others + 1
                % 需要所有其他节点都感染
                local_risk_probs(h) = p_infect^n_others;
            end
        else
            % 阈值超过超边大小
            local_risk_probs(h) = 0;
        end
    end
    
    % 确保没有NaN或Inf
    local_risk_probs(isnan(local_risk_probs) | isinf(local_risk_probs)) = 0;
    
    % 计算局部风险分布（使用相同的bin_edges）
    local_counts = histcounts(local_risk_probs, bin_edges, 'Normalization', 'probability');
    P_local = local_counts';
    
    % 确保概率和为1
    if sum(P_local) > 0
        P_local = P_local / sum(P_local);
    else
        P_local = ones(size(P_local)) / length(P_local);  % 均匀分布
    end
    
    % 存储局部分布
    P_local_cell{i_idx} = P_local;
    
    % 计算KL散度 D_KL(P_global || P_local)
    epsilon = 1e-12;  % 避免log(0)
    P_global_safe = P_global + epsilon;
    P_local_safe = P_local + epsilon;
    
    % 离散概率的KL散度
    KL_divergences(i_idx) = sum(P_global_safe .* log(P_global_safe ./ P_local_safe));
    
    % 显示进度
    if mod(i_idx, 3) == 0
        fprintf('  完成阈值 i = %d/%d (KL=%.4f)\n', i, i_values(end), KL_divergences(i_idx));
    end
end

%% ==================== 6. 找到最优阈值i* ====================
% 找到最小KL散度对应的阈值
[min_KL, min_idx] = min(KL_divergences);
optimal_i = i_values(min_idx);

fprintf('\n===== 最优阈值分析结果 =====\n');
fprintf('最优阈值 i* = %d\n', optimal_i);
fprintf('最小KL散度 = %.6f\n', min_KL);
fprintf('\n');

% 显示所有阈值对应的KL散度
fprintf('阈值与KL散度对应表:\n');
for i = 1:length(i_values)
    fprintf('  i=%2d: KL=%.6f', i_values(i), KL_divergences(i));
    if i == min_idx
        fprintf('  <-- 最优\n');
    else
        fprintf('\n');
    end
end

%% ==================== 7. 双峰性分析 ====================
fprintf('\n===== 双峰性分析 =====\n');

% 计算双峰系数(BC)
if length(peak_mentions) > 10
    skewness_val = skewness(peak_mentions);
    kurtosis_val = kurtosis(peak_mentions);
    bimodality_coeff = (skewness_val^2 + 1) / (kurtosis_val + 3);
    
    fprintf('偏度: %.4f\n', skewness_val);
    fprintf('峰度: %.4f\n', kurtosis_val);
    fprintf('双峰系数(BC): %.4f\n', bimodality_coeff);
    fprintf('BC临界值: 0.555\n');
    
    if bimodality_coeff > 0.555
        fprintf('结论: 分布呈现显著双峰性 (符合论文预测)\n');
    else
        fprintf('结论: 分布未呈现显著双峰性\n');
    end
else
    fprintf('数据量不足进行双峰性分析\n');
end

%% ==================== 8. 计算风险概率函数 P(risky|i*) ====================
fprintf('\n===== 风险概率函数计算 =====\n');
fprintf('对于 i* = %d, ?n? = %d:\n', optimal_i, avg_hyperedge_size);

% 定义感染密度I的范围
I_range = linspace(0, 1, 101);
risk_probs = zeros(size(I_range));

% 计算P(risky|i*) = Σ_{k=i*}^{n} C(n,k) I^k (1-I)^{n-k}
for idx = 1:length(I_range)
    I = I_range(idx);
    risk_prob = 0;
    for k = optimal_i:avg_hyperedge_size
        if k <= avg_hyperedge_size
            comb = nchoosek(avg_hyperedge_size, k);
            risk_prob = risk_prob + comb * I^k * (1-I)^(avg_hyperedge_size-k);
        end
    end
    risk_probs(idx) = risk_prob;
end

% 找到拐点（临界感染密度）
[~, inflection_idx] = max(diff(risk_probs));
critical_I = I_range(inflection_idx);
critical_prob = risk_probs(inflection_idx);

fprintf('临界感染密度 I_c ≈ %.3f\n', critical_I);
fprintf('临界风险概率 P_c ≈ %.3f\n', critical_prob);

%% ==================== 9. 保存结果用于后续仿真 ====================
save('optimal_threshold_results.mat', 'optimal_i', 'KL_divergences', ...
    'P_global', 'P_local_cell', 'peak_mentions', 'normalized_peaks', ...
    'i_values', 'bin_centers', 'bimodality_coeff', 'I_range', 'risk_probs', ...
    'critical_I', 'critical_prob', 'avg_hyperedge_size', '-v7.3');

fprintf('\n结果已保存到 optimal_threshold_results.mat\n');

%% ==================== 10. 可视化结果 ====================
fprintf('\n生成可视化图表...\n');

% 图1：主要分析结果
figure('Position', [50, 50, 1400, 900], 'Name', '最优阈值分析');

% 子图1：全局风险分布
subplot(2, 3, 1);
bar(bin_centers, P_global, 'FaceColor', 'b', 'EdgeColor', 'none');
xlabel('归一化风险值', 'FontSize', 11);
ylabel('概率', 'FontSize', 11);
title('全局风险分布 P_{global}', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
xlim([0, 1]);

% 子图2：最优阈值对应的局部分布
subplot(2, 3, 2);
bar(bin_centers, P_local_cell{min_idx}, 'FaceColor', 'r', 'EdgeColor', 'none');
xlabel('归一化风险值', 'FontSize', 11);
ylabel('概率', 'FontSize', 11);
title(sprintf('局部风险分布 P_{local}^{(i*=%d)}', optimal_i), 'FontSize', 12, 'FontWeight', 'bold');
grid on;
xlim([0, 1]);

% 子图3：KL散度随阈值变化
subplot(2, 3, 3);
bar(i_values, KL_divergences, 'FaceColor', [0.2, 0.6, 0.8], 'EdgeColor', 'none');
hold on;
plot(optimal_i, min_KL, 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r', 'LineWidth', 2);
xlabel('阈值 i', 'FontSize', 11);
ylabel('KL散度', 'FontSize', 11);
title('KL散度随阈值变化', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
legend('KL散度', sprintf('最优阈值 i*=%d', optimal_i), 'Location', 'best');

% 子图4：峰值频率分布（线性尺度）
subplot(2, 3, 4);
histogram(peak_mentions, 30, 'FaceColor', [0.3, 0.7, 0.3], 'EdgeColor', 'none');
xlabel('峰值提及频率', 'FontSize', 11);
ylabel('频数', 'FontSize', 11);
title('Hashtag峰值频率分布', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% 子图5：峰值频率分布（对数尺度）
subplot(2, 3, 5);
histogram(peak_mentions, 30, 'FaceColor', [0.9, 0.5, 0.1], 'EdgeColor', 'none');
set(gca, 'YScale', 'log');
xlabel('峰值提及频率', 'FontSize', 11);
ylabel('频数 (对数尺度)', 'FontSize', 11);
title('Hashtag峰值频率分布 (对数尺度)', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% 子图6：风险概率函数
subplot(2, 3, 6);
plot(I_range, risk_probs, 'm-', 'LineWidth', 2);
hold on;
plot(critical_I, critical_prob, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'k');
xlabel('感染密度 I', 'FontSize', 11);
ylabel('风险概率 P(risky|i*)', 'FontSize', 11);
title(sprintf('风险概率函数 (i*=%d, n=%d)', optimal_i, avg_hyperedge_size), ...
    'FontSize', 12, 'FontWeight', 'bold');
grid on;
legend('P(risky|i*)', sprintf('临界点 (I=%.2f)', critical_I), 'Location', 'best');

% 添加整体标题
title(sprintf('自适应超图社交传染最优阈值分析 (i* = %d)', optimal_i), ...
    'FontSize', 14, 'FontWeight', 'bold');

%% ==================== 11. 生成论文仿真支持数据 ====================
fprintf('\n===== 生成论文仿真支持数据 =====\n');

% 用于图1（爆炸性社会传染）的数据
% 临界参数计算（基于Theorem 3）
beta1 = 0.15;  % 活跃节点传播率（表1）
beta2 = 0.05;  % 被动节点传播率（表1）
pA = 0.6;      % 活跃节点比例（表1）
pP = 0.4;      % 被动节点比例（表1）
mu = 0.5;      % 恢复率（表1）
avg_degree = 4; % 平均度（表1）
avg_hyperdegree = 4; % 平均超度（表1）

% 计算基本再生数R0（Theorem 2）
beta0 = (pA * beta1 + pP * beta2) * (avg_degree + avg_hyperdegree * (avg_hyperedge_size - 1));
R0 = beta0 / mu;

% 计算临界强化参数βΔ^c（Theorem 3）
% 简化计算，使用临界感染密度I_c
beta_delta_critical = (mu - beta0) / (avg_hyperdegree * (nchoosek(avg_hyperedge_size, critical_mass_threshold) - 1) * critical_I^(critical_mass_threshold-1));

fprintf('\n用于图1（爆炸性社会传染）的参数:\n');
fprintf('基本再生数 R0 = %.3f\n', R0);
fprintf('临界强化参数 βΔ^c ≈ %.3f\n', beta_delta_critical);
fprintf('最优风险感知阈值 i* = %d\n', optimal_i);
fprintf('临界感染密度 I_c ≈ %.3f\n', critical_I);

% 用于图2（双峰性分析）的数据
if exist('bimodality_coeff', 'var')
    fprintf('\n用于图2（双峰性分析）的参数:\n');
    fprintf('双峰系数 BC = %.4f\n', bimodality_coeff);
    fprintf('偏度 = %.4f\n', skewness_val);
    fprintf('峰度 = %.4f\n', kurtosis_val);
    fprintf('风险概率函数 P(risky|i*) 已计算\n');
end

% 创建参数表格
sim_params = struct();
sim_params.optimal_i = optimal_i;
if exist('bimodality_coeff', 'var')
    sim_params.bimodality_coeff = bimodality_coeff;
end
sim_params.critical_I = critical_I;
sim_params.R0 = R0;
sim_params.beta_delta_critical = beta_delta_critical;
sim_params.risk_probs = risk_probs;
sim_params.I_range = I_range;

save('simulation_parameters.mat', 'sim_params');

%% ==================== 12. 创建详细报告 ====================
fprintf('\n===== 分析报告 =====\n');
fprintf('\n1. 数据概览:\n');
fprintf('   - 分析话题数: %d\n', num_hashtags);
fprintf('   - 峰值频率范围: [%.2f, %.2f]\n', min_peak, max_peak);
fprintf('   - 平均峰值: %.2f\n', mean(peak_mentions));

fprintf('\n2. 最优阈值分析:\n');
fprintf('   - 最优阈值 i* = %d\n', optimal_i);
fprintf('   - 最小KL散度 = %.6f\n', min_KL);
fprintf('   - 表示个体在信息约束下的最优风险感知粒度\n');

fprintf('\n3. 双峰性验证:\n');
if exist('bimodality_coeff', 'var') && bimodality_coeff > 0.555
    fprintf('   - 分布呈现显著双峰性 (BC=%.4f > 0.555)\n', bimodality_coeff);
    fprintf('   - 符合论文预测的双模传播模式\n');
    fprintf('   - 支持爆炸性转变和局部抑制共存的理论\n');
elseif exist('bimodality_coeff', 'var')
    fprintf('   - 分布未呈现显著双峰性 (BC=%.4f ≤ 0.555)\n', bimodality_coeff);
else
    fprintf('   - 双峰性分析不可用\n');
end

fprintf('\n4. 对论文仿真的支持:\n');
fprintf('   - 图1 (爆炸性社会传染): i*=%d 用于风险分类\n', optimal_i);
fprintf('   - 图2 (双峰性分析): i*=%d 作为决策阈值\n', optimal_i);
fprintf('   - OAR机制: P(risky|i*) 函数已计算\n');
fprintf('   - 临界参数: R0=%.3f, βΔ^c≈%.3f\n', R0, beta_delta_critical);

fprintf('\n5. 文件输出:\n');
fprintf('   - optimal_threshold_results.mat: 所有分析结果\n');
fprintf('   - simulation_parameters.mat: 仿真参数\n');
fprintf('   - 图表已显示，可保存为图片\n');

%% ==================== 13. 额外分析：验证KL散度最小化的有效性 ====================
figure('Position', [100, 100, 1000, 400], 'Name', 'KL散度分析验证');

% 显示全局与局部分布对比
subplot(1, 2, 1);
bar(bin_centers, P_global, 'FaceColor', 'b', 'EdgeColor', 'none');
hold on;
for i_idx = [1, min_idx, length(i_values)]
    i = i_values(i_idx);
    if i == optimal_i
        bar(bin_centers, P_local_cell{i_idx}, 'FaceColor', 'r', 'FaceAlpha', 0.7, 'EdgeColor', 'none');
    elseif i == 1
        bar(bin_centers, P_local_cell{i_idx}, 'FaceColor', 'g', 'FaceAlpha', 0.5, 'EdgeColor', 'none');
    else
        bar(bin_centers, P_local_cell{i_idx}, 'FaceColor', [0.5, 0.5, 0.5], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    end
end
xlabel('风险值', 'FontSize', 11);
ylabel('概率', 'FontSize', 11);
title('全局与局部分布对比', 'FontSize', 12, 'FontWeight', 'bold');
legend('P_{global}', sprintf('P_{local}^{(i=%d)}', optimal_i), ...
    'P_{local}^{(i=1)}', '其他阈值', 'Location', 'best');
grid on;
xlim([0, 1]);

% 显示KL散度与阈值关系（更详细）
subplot(1, 2, 2);
plot(i_values, KL_divergences, 'b-o', 'LineWidth', 2, 'MarkerSize', 8);
hold on;
plot(optimal_i, min_KL, 'ro', 'MarkerSize', 15, 'MarkerFaceColor', 'r', 'LineWidth', 2);
xlabel('阈值 i', 'FontSize', 11);
ylabel('KL散度 D_{KL}(P_{global} || P_{local}^{(i)})', 'FontSize', 11);
title('KL散度最小化验证', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
text(optimal_i, min_KL*1.1, sprintf('i*=%d\nKL=%.4f', optimal_i, min_KL), ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 10);

fprintf('\n分析完成！\n');
fprintf('========================================\n');