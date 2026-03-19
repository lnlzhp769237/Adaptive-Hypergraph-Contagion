%% 自适应超图社交传染双模态仿真 - 完整修正版
% 基于Elsevier论文模型的双模态扩散模式仿真
clear; close all; clc;

fprintf('=== Adaptive Hypergraph Social Contagion Bimodal Simulation ===\n');

%% 参数设置（固定参数版）
k_avg = 4;          % 平均点度数
k_delta_avg = 4;    % 平均超边度  
n_avg = 5;          % 平均超边大小
k_c = 2;            % 临界群体阈值

mu = 0.5;         % 恢复率
beta1 = 0.051;       % 主动节点传播率
beta2 = 0.015;      % 被动节点传播率
beta_delta = 0.474; % 高阶相互作用强度（接近临界）

gamma = 0.35;       % 重连率
alpha = 0.128;      % 随机避免率
eta_bimodal = 0.75; % 信息准确率
i_star_bimodal = 2; % 最优风险感知阈值

%% 仿真设置
num_simulations = 100;
tspan = [0, 100];
steady_state_infections = zeros(num_simulations, 1);

fprintf('Running %d simulations with parameters:\n', num_simulations);
fprintf('  μ = %.2f, β? = %.2f, β? = %.2f\n', mu, beta1, beta2);
fprintf('  β_Δ = %.3f\n', beta_delta);
fprintf('  η = %.2f, i* = %d\n', eta_bimodal, i_star_bimodal);

%% 修正版初始条件生成函数

%% 修正版获取初始和最终状态的函数

%% 修正版单次模拟函数


%% GAME微分方程组

%% 主仿真循环
fprintf('Progress: ');
for sim = 1:num_simulations
    if mod(sim, 50) == 0
        fprintf('%d ', sim);
    end
    
    % 生成初始条件
    y0 = generate_initial_conditions();
    
    % Solve differential equations
    try
        [~, y] = ode45(@(t,y) game_equations(t, y, mu, beta1, beta2, beta_delta, ...
                                            k_avg, k_delta_avg, n_avg, k_c, ...
                                            gamma, eta_bimodal, i_star_bimodal, alpha), ...
                      tspan, y0);
        
        % Check validity
        if any(y(end,:) < -0.01) || any(y(end,:) > 1.01) || any(isnan(y(end,:)))
            steady_state_infections(sim) = NaN;
        else
            % Use last 20% time points for steady state
            final_idx = max(1, round(0.8 * size(y,1)):size(y,1));
            I_total_final = mean(y(final_idx, 3) + y(final_idx, 4));
            steady_state_infections(sim) = max(0, min(1, I_total_final));  % 确保在[0,1]范围内
        end
    catch
        steady_state_infections(sim) = NaN;
    end
end
fprintf('Done!\n');

% Remove invalid simulations
valid_indices = ~isnan(steady_state_infections);
steady_state_infections = steady_state_infections(valid_indices);
fprintf('Valid simulations: %d/%d\n', sum(valid_indices), num_simulations);

% Check infection density range
if max(steady_state_infections) > 1
    fprintf('Warning: Infection density > 1 detected, truncating...\n');
    steady_state_infections = min(steady_state_infections, 1);
end

%% 可视化双模态分布 - 保留a, c, d, e, f
figure('Position', [100, 100, 1400, 900]);

% ===== Subplot 1: 双模态分布直方图 + KDE =====
subplot(2,3,1);

if isempty(steady_state_infections)
    error('No valid data for plotting');
end

% Create histogram
num_bins = min(40, max(10, round(sqrt(length(steady_state_infections)))));
num_bins = max(5, num_bins);

[counts, edges] = histcounts(steady_state_infections, num_bins);
centers = (edges(1:end-1) + edges(2:end)) / 2;

% Plot histogram
bar(centers, counts, 'FaceColor', [0.3, 0.6, 0.9], 'EdgeColor', 'black', 'FaceAlpha', 0.7);
xlabel('Steady-state Infection Density I_∞');
ylabel('Frequency');
title('(a) Bimodal Distribution', 'FontWeight', 'bold');
grid on;

% Add KDE overlay on same axis
hold on;
try
    [pdf_vals, xi] = ksdensity(steady_state_infections, 'Bandwidth', 0.025);
    % Scale KDE to match histogram
    pdf_vals_scaled = pdf_vals * max(counts) / max(pdf_vals);
    plot(xi, pdf_vals_scaled, 'r-', 'LineWidth', 2.5);
catch
    % Fallback if KDE fails
    plot(centers, counts, 'r-', 'LineWidth', 2.5);
end

% Simple text annotation instead of complex legend
mean_infection = mean(steady_state_infections);
std_infection = std(steady_state_infections);
text(0.6, max(counts)*0.8, sprintf('Mean: %.3f\nStd: %.3f', mean_infection, std_infection), ...
     'FontSize', 10, 'BackgroundColor', 'white', 'EdgeColor', 'black');

% Simple peak detection without legend
try
    [peaks, peak_locs] = findpeaks(pdf_vals_scaled, xi, 'MinPeakHeight', max(pdf_vals_scaled)*0.15, ...
                                  'MinPeakDistance', 0.1);
    if length(peaks) >= 2
        [sorted_locs, idx] = sort(peak_locs);
        low_peak = sorted_locs(1);
        high_peak = sorted_locs(end);
        
        % Mark peaks with vertical lines
        plot([low_peak, low_peak], [0, max(counts)*1.05], 'r--', 'LineWidth', 2);
        plot([high_peak, high_peak], [0, max(counts)*1.05], 'g--', 'LineWidth', 2);
        
        % Add peak labels as text
        text(low_peak, max(counts)*0.9, sprintf('Low: %.3f', low_peak), ...
             'HorizontalAlignment', 'center', 'BackgroundColor', 'white');
        text(high_peak, max(counts)*0.9, sprintf('High: %.3f', high_peak), ...
             'HorizontalAlignment', 'center', 'BackgroundColor', 'white');
        
        fprintf('Bimodal detected: Low = %.3f, High = %.3f\n', low_peak, high_peak);
    end
catch
    % Continue without peak detection
end

% ===== Subplot 2: Effect of η and kΔ on Bimodality (Heatmap) =====
subplot(2,3,2);

fprintf('Computing η-kΔ heatmap...\n');

% Parameter ranges
eta_range = 0:0.1:1;
k_delta_range = 2:0.5:8;
bimodal_coef_matrix_eta_k = zeros(length(eta_range), length(k_delta_range));

total_iterations = length(eta_range) * length(k_delta_range);
current_iteration = 0;

fprintf('η-kΔ Heatmap Progress: ');
for i = 1:length(eta_range)
    for j = 1:length(k_delta_range)
        current_iteration = current_iteration + 1;
        if mod(current_iteration, 10) == 0
            fprintf('%d%% ', round(current_iteration/total_iterations*100));
        end
        
        eta_current = eta_range(i);
        k_delta_current = k_delta_range(j);
        
        % Fast simulation
        fast_infections = zeros(30, 1);
        for sim_fast = 1:30
            % 生成初始条件
            y0_fast = generate_initial_conditions();
            
            try
                [~, y] = ode45(@(t,y) game_equations(t, y, mu, beta1, beta2, beta_delta, ...
                                                    k_avg, k_delta_current, n_avg, k_c, ...
                                                    gamma, eta_current, i_star_bimodal, alpha), ...
                              [0, 50], y0_fast);
                
                if size(y,1) > 5
                    fast_infections(sim_fast) = mean(y(end-4:end, 3) + y(end-4:end, 4));
                else
                    fast_infections(sim_fast) = y(end,3) + y(end,4);
                end
            catch
                fast_infections(sim_fast) = NaN;
            end
        end
        
        % Calculate bimodal coefficient
        valid_fast = ~isnan(fast_infections);
        if sum(valid_fast) >= 10
            valid_infections = fast_infections(valid_fast);
            skew_val = skewness(valid_infections);
            kurt_val = kurtosis(valid_infections);
            bimodal_coef_matrix_eta_k(i,j) = (skew_val^2 + 1) / (kurt_val + 3);
        else
            bimodal_coef_matrix_eta_k(i,j) = 0;
        end
    end
end
fprintf('Done!\n');

% Create heatmap
imagesc(k_delta_range, eta_range, bimodal_coef_matrix_eta_k);
colorbar;
xlabel('Average Hyperdegree k_{\Delta}');
ylabel('Information Accuracy η');
title('(b) Effect of η and k_{\Delta} on Bimodality', 'FontWeight', 'bold');

% Customize colormap and add contours
colormap(jet);
caxis([0, 1]);

% Add contours
hold on;
[C, h] = contour(k_delta_range, eta_range, bimodal_coef_matrix_eta_k, ...
                 [0.555, 0.6, 0.7], 'LineColor', 'white', 'LineWidth', 1.5);
clabel(C, h, 'FontSize', 9, 'Color', 'white');

% Mark current parameter position
current_eta_idx = find(abs(eta_range - eta_bimodal) < 0.05, 1);
current_k_delta_idx = find(abs(k_delta_range - k_delta_avg) < 0.1, 1);
if ~isempty(current_eta_idx) && ~isempty(current_k_delta_idx)
    plot(k_delta_avg, eta_bimodal, 'wo', 'MarkerSize', 10, 'LineWidth', 2);
    plot(k_delta_avg, eta_bimodal, 'w+', 'MarkerSize', 8, 'LineWidth', 2);
end

% Add colorbar label
cb = colorbar;
ylabel(cb, 'Bimodal Coefficient');

set(gca, 'YDir', 'normal');
grid on;

% ===== Subplot 3: Temporal Evolution of All Simulations =====
subplot(2,3,3);

% Calculate threshold for grouping
infection_threshold = median(steady_state_infections);

% Group by threshold
low_idx = find(steady_state_infections < infection_threshold);
high_idx = find(steady_state_infections >= infection_threshold);

hold on;

% Plot ALL trajectories with transparency
fprintf('Plotting all temporal evolution trajectories...\n');

% Plot low infection trajectories
for i = 1:min(10, length(low_idx))  % 限制数量以避免过度绘图
    idx = low_idx(i);
    [t, I_total] = run_single_simulation(idx, mu, beta1, beta2, beta_delta, ...
                                        k_avg, k_delta_avg, n_avg, k_c, ...
                                        gamma, eta_bimodal, i_star_bimodal, alpha, tspan);
    plot(t, I_total, 'b-', 'LineWidth', 0.3, 'Color', [0, 0, 1, 0.2]);
end

% Plot high infection trajectories
for i = 1:min(10, length(high_idx))  % 限制数量以避免过度绘图
    idx = high_idx(i);
    [t, I_total] = run_single_simulation(idx, mu, beta1, beta2, beta_delta, ...
                                        k_avg, k_delta_avg, n_avg, k_c, ...
                                        gamma, eta_bimodal, i_star_bimodal, alpha, tspan);
    plot(t, I_total, 'r-', 'LineWidth', 0.3, 'Color', [1, 0, 0, 0.2]);
end

% Calculate and plot average trajectories for each group
fprintf('Calculating average trajectories...\n');

% For low infection group
if ~isempty(low_idx)
    avg_t_low = [];
    avg_I_low = [];
    for i = 1:min(10, length(low_idx))
        idx = low_idx(i);
        [t, I_total] = run_single_simulation(idx, mu, beta1, beta2, beta_delta, ...
                                            k_avg, k_delta_avg, n_avg, k_c, ...
                                            gamma, eta_bimodal, i_star_bimodal, alpha, tspan);
        if i == 1
            avg_t_low = t;
            avg_I_low = I_total;
        else
            % Interpolate to common time points
            I_interp = interp1(t, I_total, avg_t_low, 'linear', 'extrap');
            avg_I_low = avg_I_low + I_interp;
        end
    end
    avg_I_low = avg_I_low / min(10, length(low_idx));
    plot(avg_t_low, avg_I_low, 'b-', 'LineWidth', 3);
end

% For high infection group
if ~isempty(high_idx)
    avg_t_high = [];
    avg_I_high = [];
    for i = 1:min(10, length(high_idx))
        idx = high_idx(i);
        [t, I_total] = run_single_simulation(idx, mu, beta1, beta2, beta_delta, ...
                                            k_avg, k_delta_avg, n_avg, k_c, ...
                                            gamma, eta_bimodal, i_star_bimodal, alpha, tspan);
        if i == 1
            avg_t_high = t;
            avg_I_high = I_total;
        else
            % Interpolate to common time points
            I_interp = interp1(t, I_total, avg_t_high, 'linear', 'extrap');
            avg_I_high = avg_I_high + I_interp;
        end
    end
    avg_I_high = avg_I_high / min(10, length(high_idx));
    plot(avg_t_high, avg_I_high, 'r-', 'LineWidth', 3);
end

xlabel('Time t');
ylabel('Total Infection Density I(t)');
title('(c) Temporal Evolution of All Simulations', 'FontWeight', 'bold');
grid on;

% Create legend entries for the average trajectories
legend_handles = [];
legend_labels = {};

if ~isempty(low_idx)
    h_low = plot(NaN, NaN, 'b-', 'LineWidth', 3);
    legend_handles = [legend_handles, h_low];
    legend_labels{end+1} = sprintf('Low Infection Avg (%d)', min(10, length(low_idx)));
end

if ~isempty(high_idx)
    h_high = plot(NaN, NaN, 'r-', 'LineWidth', 3);
    legend_handles = [legend_handles, h_high];
    legend_labels{end+1} = sprintf('High Infection Avg (%d)', min(10, length(high_idx)));
end

if ~isempty(legend_handles)
    legend(legend_handles, legend_labels, 'Location', 'best');
end

% Add text annotation for total number of simulations
text(30, 0.9, sprintf('Total: %d simulations', length(steady_state_infections)), ...
     'FontSize', 10, 'BackgroundColor', 'white', 'EdgeColor', 'black');

xlim([0, 100]);
ylim([0, 1]);

% ===== Subplot 4: Effect of k_delta and k_avg on Bimodality (2D Heatmap) =====
subplot(2,3,4);

fprintf('Computing k_delta-k_avg heatmap...\n');

% Parameter ranges
k_delta_range_2d = 2:0.5:8;
k_avg_range_2d = 3:0.5:10;
bimodal_coef_matrix_kd_ka = zeros(length(k_delta_range_2d), length(k_avg_range_2d));

total_iterations = length(k_delta_range_2d) * length(k_avg_range_2d);
current_iteration = 0;

fprintf('k_delta-k_avg Heatmap Progress: ');
for i = 1:length(k_delta_range_2d)
    for j = 1:length(k_avg_range_2d)
        current_iteration = current_iteration + 1;
        if mod(current_iteration, 10) == 0
            fprintf('%d%% ', round(current_iteration/total_iterations*100));
        end
        
        k_delta_current = k_delta_range_2d(i);
        k_avg_current = k_avg_range_2d(j);
        
        % Fast simulation
        fast_infections = zeros(30, 1);
        for sim_fast = 1:30
            % 生成初始条件
            y0_fast = generate_initial_conditions();
            
            try
                [~, y] = ode45(@(t,y) game_equations(t, y, mu, beta1, beta2, beta_delta, ...
                                                    k_avg_current, k_delta_current, n_avg, k_c, ...
                                                    gamma, eta_bimodal, i_star_bimodal, alpha), ...
                              [0, 50], y0_fast);
                
                if size(y,1) > 5
                    fast_infections(sim_fast) = mean(y(end-4:end, 3) + y(end-4:end, 4));
                else
                    fast_infections(sim_fast) = y(end,3) + y(end,4);
                end
            catch
                fast_infections(sim_fast) = NaN;
            end
        end
        
        % Calculate bimodal coefficient
        valid_fast = ~isnan(fast_infections);
        if sum(valid_fast) >= 10
            valid_infections = fast_infections(valid_fast);
            skew_val = skewness(valid_infections);
            kurt_val = kurtosis(valid_infections);
            bimodal_coef_matrix_kd_ka(i,j) = (skew_val^2 + 1) / (kurt_val + 3);
        else
            bimodal_coef_matrix_kd_ka(i,j) = 0;
        end
    end
end
fprintf('Done!\n');

% Create heatmap
imagesc(k_avg_range_2d, k_delta_range_2d, bimodal_coef_matrix_kd_ka);
colorbar;
xlabel('Average Pairwise Degree k_{avg}');
ylabel('Average Hyperdegree k_{\Delta}');
title('(d) Effect of k_{\Delta} and k_{avg} on Bimodality', 'FontWeight', 'bold');

% Customize colormap and add contours
colormap(jet);
caxis([0, 1]);

% Add contours
hold on;
[C, h] = contour(k_avg_range_2d, k_delta_range_2d, bimodal_coef_matrix_kd_ka, ...
                 [0.555, 0.6, 0.7], 'LineColor', 'white', 'LineWidth', 1.5);
clabel(C, h, 'FontSize', 9, 'Color', 'white');

% Mark current parameter position
current_k_delta_idx = find(abs(k_delta_range_2d - k_delta_avg) < 0.1, 1);
current_k_avg_idx = find(abs(k_avg_range_2d - k_avg) < 0.1, 1);
if ~isempty(current_k_delta_idx) && ~isempty(current_k_avg_idx)
    plot(k_avg, k_delta_avg, 'wo', 'MarkerSize', 10, 'LineWidth', 2);
    plot(k_avg, k_delta_avg, 'w+', 'MarkerSize', 8, 'LineWidth', 2);
end

% Add colorbar label
cb = colorbar;
ylabel(cb, 'Bimodal Coefficient');

set(gca, 'YDir', 'normal');
grid on;

% ===== Subplot 5: Effect of η and i* on Bimodality (Heatmap) =====
subplot(2,3,5);

fprintf('Computing η-i* heatmap...\n');

% Parameter ranges
eta_range_i = 0:0.1:1;
i_star_range = 1:3;  % Since n_avg = 3
bimodal_coef_matrix_eta_i = zeros(length(eta_range_i), length(i_star_range));

total_iterations = length(eta_range_i) * length(i_star_range);
current_iteration = 0;

fprintf('η-i* Heatmap Progress: ');
for i = 1:length(eta_range_i)
    for j = 1:length(i_star_range)
        current_iteration = current_iteration + 1;
        if mod(current_iteration, 10) == 0
            fprintf('%d%% ', round(current_iteration/total_iterations*100));
        end
        
        eta_current = eta_range_i(i);
        i_star_current = i_star_range(j);
        
        % Fast simulation
        fast_infections = zeros(30, 1);
        for sim_fast = 1:30
            % 生成初始条件
            y0_fast = generate_initial_conditions();
            
            try
                [~, y] = ode45(@(t,y) game_equations(t, y, mu, beta1, beta2, beta_delta, ...
                                                    k_avg, k_delta_avg, n_avg, k_c, ...
                                                    gamma, eta_current, i_star_current, alpha), ...
                              [0, 50], y0_fast);
                
                if size(y,1) > 5
                    fast_infections(sim_fast) = mean(y(end-4:end, 3) + y(end-4:end, 4));
                else
                    fast_infections(sim_fast) = y(end,3) + y(end,4);
                end
            catch
                fast_infections(sim_fast) = NaN;
            end
        end
        
        % Calculate bimodal coefficient
        valid_fast = ~isnan(fast_infections);
        if sum(valid_fast) >= 10
            valid_infections = fast_infections(valid_fast);
            skew_val = skewness(valid_infections);
            kurt_val = kurtosis(valid_infections);
            bimodal_coef_matrix_eta_i(i,j) = (skew_val^2 + 1) / (kurt_val + 3);
        else
            bimodal_coef_matrix_eta_i(i,j) = 0;
        end
    end
end
fprintf('Done!\n');

% Create heatmap
imagesc(i_star_range, eta_range_i, bimodal_coef_matrix_eta_i);
colorbar;
xlabel('Optimal Threshold i*');
ylabel('Information Accuracy η');
title('(e) Effect of η and i* on Bimodality', 'FontWeight', 'bold');

% Customize colormap and add contours
colormap(jet);
caxis([0, 1]);

% Add contours
hold on;
[C, h] = contour(i_star_range, eta_range_i, bimodal_coef_matrix_eta_i, ...
                 [0.555, 0.6, 0.7], 'LineColor', 'white', 'LineWidth', 1.5);
clabel(C, h, 'FontSize', 9, 'Color', 'white');

% Mark current parameter position
current_eta_idx = find(abs(eta_range_i - eta_bimodal) < 0.05, 1);
current_i_star_idx = find(i_star_range == i_star_bimodal, 1);
if ~isempty(current_eta_idx) && ~isempty(current_i_star_idx)
    plot(i_star_bimodal, eta_bimodal, 'wo', 'MarkerSize', 10, 'LineWidth', 2);
    plot(i_star_bimodal, eta_bimodal, 'w+', 'MarkerSize', 8, 'LineWidth', 2);
end

% Add colorbar label
cb = colorbar;
ylabel(cb, 'Bimodal Coefficient');

set(gca, 'YDir', 'normal');
grid on;

% ===== Subplot 6: Initial-Final State Mapping =====
subplot(2,3,6);

sample_size = min(100, length(steady_state_infections));
sample_idx = randperm(length(steady_state_infections), sample_size);

initial_infections = zeros(sample_size, 1);
final_infections = zeros(sample_size, 1);
valid_flags = false(sample_size, 1);

for i = 1:sample_size
    idx = sample_idx(i);
    [I_initial, I_final_val, valid] = get_initial_final(idx, mu, beta1, beta2, beta_delta, ...
                                                        k_avg, k_delta_avg, n_avg, k_c, ...
                                                        gamma, eta_bimodal, i_star_bimodal, alpha, tspan);
    
    if valid && ~isnan(I_final_val)
        initial_infections(i) = I_initial;
        final_infections(i) = I_final_val;
        valid_flags(i) = true;
    end
end

% 只保留有效数据
initial_infections = initial_infections(valid_flags);
final_infections = final_infections(valid_flags);

% 绘制散点图
scatter(initial_infections, final_infections, 40, 'filled', 'MarkerFaceAlpha', 0.6, ...
        'MarkerFaceColor', [0.1, 0.6, 0.3]);
xlabel('Initial Infection Density I(0)');
ylabel('Final Infection Density I_{\infty}');
title('(f) Initial-Final State Mapping', 'FontWeight', 'bold');
grid on;

% 添加对角线
hold on;
plot([0, 1], [0, 1], 'k--', 'LineWidth', 1);
legend('Simulation Results', 'Identity Line', 'Location', 'southeast');

% 设置坐标轴范围
xlim([0, 1]);
ylim([0, 1]);

% 添加统计信息
mean_initial = mean(initial_infections);
std_initial = std(initial_infections);
text(0.7, 0.2, sprintf('Mean I(0): %.3f\nStd: %.3f', mean_initial, std_initial), ...
     'FontSize', 10, 'BackgroundColor', 'white', 'EdgeColor', 'black');

%% Statistical Analysis
fprintf('\n=== Bimodal Statistical Analysis ===\n');
fprintf('Infection Statistics: Mean = %.4f, Std = %.4f\n', mean(steady_state_infections), std(steady_state_infections));
fprintf('Range: [%.4f, %.4f]\n', min(steady_state_infections), max(steady_state_infections));

% Bimodality metrics
skew_val = skewness(steady_state_infections);
kurt_val = kurtosis(steady_state_infections);
bimodal_coef = (skew_val^2 + 1) / (kurt_val + 3);

fprintf('Skewness: %.3f, Kurtosis: %.3f\n', skew_val, kurt_val);
fprintf('Bimodal Coefficient: %.3f ', bimodal_coef);
if bimodal_coef > 0.555
    fprintf('(>0.555, Strong Bimodality)\n');
else
    fprintf('(≤0.555, Weak/Unimodal)\n');
end

% Group proportions
prop_low = length(low_idx) / length(steady_state_infections);
prop_high = 1 - prop_low;
fprintf('Group Proportions: Low %.1f%%, High %.1f%%\n', prop_low*100, prop_high*100);

% Additional analysis
if bimodal_coef > 0.555 && prop_low > 0.2 && prop_high > 0.2
    fprintf('? System exhibits strong bistable behavior\n');
elseif bimodal_coef > 0.555
    fprintf('? Statistically bimodal but modes not well separated\n');
else
    fprintf('? System primarily unimodal\n');
end

fprintf('\n=== Simulation Complete ===\n');

%% KS检验（可选）
% 提取前25%（低感染组）和后25%（高感染组）
if length(steady_state_infections) >= 40
    n_total = length(steady_state_infections);
    n_25 = round(0.25 * n_total);
    sorted_infections = sort(steady_state_infections);
    low_group_25 = sorted_infections(1:n_25);
    high_group_25 = sorted_infections(end-n_25+1:end);
    
    % 执行两样本KS检验
    [h_ks, p_ks, ks_stat] = kstest2(low_group_25, high_group_25);
    
    fprintf('\n=== KS Test Results ===\n');
    fprintf('KS statistic: %.4f\n', ks_stat);
    fprintf('p-value: %.4e\n', p_ks);
    if p_ks < 0.05
        fprintf('? The two groups are significantly different (p < 0.05)\n');
    else
        fprintf('? The two groups are not significantly different\n');
    end
end