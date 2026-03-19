%% Twitter Hashtags Distribution Analysis: Top 25% vs Bottom 25% KS Test
% Using Stanford SNAP Dataset: https://snap.stanford.edu/data/TwtHtag.txt
% Author: Anonymous
% Description: This script analyzes Twitter hashtag data, extracts peak volumes,
%              and performs Kolmogorov-Smirnov test comparing top 25% vs bottom 25%

clear; clc; close all;
fprintf('=== Twitter Hashtags Distribution Analysis: Top 25%% vs Bottom 25%% KS Test ===\n\n');

%% Step 1: Download and Parse Twitter Data
fprintf('Downloading and parsing Twitter Hashtags data...\n');

% Twitter Hashtags data file URL
twitter_url = 'https://snap.stanford.edu/data/TwtHtag.txt';
twitter_filename = 'TwtHtag.txt';

% Download Twitter data if not exists
if ~exist(twitter_filename, 'file')
    try
        options = weboptions('Timeout', 120);
        websave(twitter_filename, twitter_url, options);
        fprintf('Twitter Hashtags file downloaded successfully!\n');
    catch ME
        fprintf('Failed to download Twitter data: %s\n', ME.message);
        fprintf('Trying alternative URL...\n');
        
        % Try alternative URL
        try
            twitter_url2 = 'https://snap.stanford.edu/data/memetracker/twitter_hashtags.txt';
            websave(twitter_filename, twitter_url2, options);
            fprintf('Twitter Hashtags file downloaded successfully!\n');
        catch ME2
            error('Cannot download Twitter data. Error: %s', ME2.message);
        end
    end
else
    fprintf('Twitter Hashtags file already exists, skipping download.\n');
end

%% Step 2: Read and Parse Twitter Hashtags Data (Correct Format)
fprintf('Reading and parsing Twitter Hashtags data...\n');

% Open Twitter data file
fileID = fopen(twitter_filename, 'r', 'n', 'UTF-8');
if fileID == -1
    error('Cannot open Twitter data file: %s', twitter_filename);
end

twitter_max_values = [];  % Store peak volumes
twitter_metadata = struct();  % Store metadata
twitter_count = 0;
max_to_read = 1000;  % Read maximum 1000 hashtags (as per paper)

% Read data line by line (alternating format: metadata line + time series line)
while ~feof(fileID) && twitter_count < max_to_read
    % Read metadata line
    meta_line = fgetl(fileID);
    
    if ~ischar(meta_line) || isempty(meta_line)
        continue;
    end
    
    % Read time series line
    ts_line = fgetl(fileID);
    
    if ~ischar(ts_line) || isempty(ts_line)
        continue;
    end
    
    % Parse metadata line (tab-separated)
    meta_parts = strsplit(meta_line, '\t');
    
    if length(meta_parts) < 5
        continue;
    end
    
    twitter_count = twitter_count + 1;
    
    % Store metadata
    twitter_metadata(twitter_count).id = meta_parts{1};
    twitter_metadata(twitter_count).content = meta_parts{2};
    twitter_metadata(twitter_count).begin_time = meta_parts{3};
    twitter_metadata(twitter_count).num_qt = str2double(meta_parts{4});
    twitter_metadata(twitter_count).peak_time = meta_parts{5};
    twitter_metadata(twitter_count).source = 'Twitter';
    
    % Parse time series data (128 values, tab-separated)
    ts_parts = strsplit(ts_line, '\t');
    ts_values = zeros(1, 128);
    
    for i = 1:min(length(ts_parts), 128)
        ts_values(i) = str2double(ts_parts{i});
        if isnan(ts_values(i))
            ts_values(i) = 0;
        end
    end
    
    % Calculate and store maximum value (peak volume)
    twitter_max_values(twitter_count) = max(ts_values);
    
    % Display progress
    if mod(twitter_count, 100) == 0
        fprintf('Processed %d Twitter Hashtags...\n', twitter_count);
    end
end

fclose(fileID);

fprintf('Successfully read %d Twitter Hashtags\n', twitter_count);

%% Step 3: Basic Statistical Analysis
fprintf('\n========== Basic Statistics ==========\n');
fprintf('Sample size: n = %d\n', twitter_count);

% Basic statistics
min_val = min(twitter_max_values);
max_val = max(twitter_max_values);
mean_val = mean(twitter_max_values);
median_val = median(twitter_max_values);
std_val = std(twitter_max_values);
cv = std_val / mean_val;

fprintf('Overall statistics:\n');
fprintf('  Minimum: %.4f\n', min_val);
fprintf('  Maximum: %.4f\n', max_val);
fprintf('  Mean: %.4f\n', mean_val);
fprintf('  Median: %.4f\n', median_val);
fprintf('  Standard deviation: %.4f\n', std_val);
fprintf('  Coefficient of variation: %.4f\n', cv);

% Calculate quantiles
quantiles = quantile(twitter_max_values, [0.25, 0.5, 0.75, 0.95, 0.99]);
fprintf('Quantiles:\n');
fprintf('  Q1 (25%%): %.4f\n', quantiles(1));
fprintf('  Median (50%%): %.4f\n', quantiles(2));
fprintf('  Q3 (75%%): %.4f\n', quantiles(3));
fprintf('  95th percentile: %.4f\n', quantiles(4));
fprintf('  99th percentile: %.4f\n', quantiles(5));
fprintf('  IQR: %.4f\n', quantiles(3) - quantiles(1));

%% Step 4: Bimodality Analysis
fprintf('\n========== Bimodality Analysis ==========\n');

% Calculate skewness and kurtosis
skew = skewness(twitter_max_values);
kurt = kurtosis(twitter_max_values);
excess_kurt = kurt - 3;

% Calculate Bimodality Coefficient (BC)
BC = (skew^2 + 1) / (excess_kurt + 3);

fprintf('Bimodality analysis:\n');
fprintf('  Skewness: %.4f\n', skew);
fprintf('  Kurtosis: %.4f\n', kurt);
fprintf('  Excess kurtosis: %.4f\n', excess_kurt);
fprintf('  Bimodality Coefficient (BC): %.4f\n', BC);

% Judgment criteria: BC > 0.555 indicates significant bimodality
if BC > 0.555
    fprintf('Conclusion: BC > 0.555, distribution shows significant bimodality!\n');
    fprintf('This supports the bimodal spreading phenomenon proposed in the paper.\n');
else
    fprintf('Conclusion: BC ≤ 0.555, distribution does not show significant bimodality.\n');
    fprintf('This does not support the bimodal spreading phenomenon proposed in the paper.\n');
end

%% Step 5: Extract Top 25% and Bottom 25% Data
fprintf('\n========== Extracting Top 25%% and Bottom 25%% Groups ==========\n');

% Sort data in ascending order (small to large)
sorted_volumes_asc = sort(twitter_max_values, 'ascend');
n_total = length(sorted_volumes_asc);
n_25_percent = round(0.25 * n_total);

% Extract groups (ascending order means first n_25_percent are bottom 25%)
bottom_25_percent = sorted_volumes_asc(1:n_25_percent);          % Bottom 25% (smallest values)
top_25_percent = sorted_volumes_asc(end-n_25_percent+1:end);     % Top 25% (largest values)

% Also sort in descending order for display purposes
sorted_volumes_desc = sort(twitter_max_values, 'descend');

fprintf('Group information:\n');
fprintf('  Top 25%% sample size: %d\n', length(top_25_percent));
fprintf('  Bottom 25%% sample size: %d\n', length(bottom_25_percent));
fprintf('  Top 25%% volume range: [%.2f, %.2f]\n', min(top_25_percent), max(top_25_percent));
fprintf('  Bottom 25%% volume range: [%.2f, %.2f]\n', min(bottom_25_percent), max(bottom_25_percent));
fprintf('  Volume ratio (max/min): %.2f:1\n', max(top_25_percent)/min(bottom_25_percent));
fprintf('  Volume ratio (top25_mean/bottom25_mean): %.2f:1\n', mean(top_25_percent)/mean(bottom_25_percent));

%% Step 6: Perform Two-Sample Kolmogorov-Smirnov Test
fprintf('\nPerforming two-sample Kolmogorov-Smirnov test...\n');
[h, p, ks2stat] = kstest2(top_25_percent, bottom_25_percent);

%% Step 7: Output Results
fprintf('\n========== Kolmogorov-Smirnov Test Results ==========\n');
fprintf('Test hypotheses:\n');
fprintf('  H0: Top 25%% and bottom 25%% hashtags come from the same distribution\n');
fprintf('  H1: Top 25%% and bottom 25%% hashtags come from different distributions\n\n');

fprintf('Key statistics:\n');
fprintf('  D statistic (KS statistic): %.4f\n', ks2stat);
fprintf('  P-value: %.4e\n', p);

% Draw conclusion based on p-value
alpha = 0.001; % Significance level
if p < alpha
    fprintf('\nConclusion:\n');
    fprintf('  At α=%.3f significance level, reject null hypothesis (P < α)\n', alpha);
    fprintf('  Top 25%% and bottom 25%% hashtags have significantly different distributions\n');
    
    % Generate formatted output directly usable in paper
    fprintf('\n>>>> Formatted statement for paper:\n');
    fprintf('A two-sample Kolmogorov-Smirnov test comparing the distribution\n');
    fprintf('of the top 25%% and bottom 25%% of hashtags rejects the null hypothesis\n');
    
    % Choose appropriate display based on p-value size
    if p < 2.2e-16  % MATLAB's minimum positive double value
        fprintf('of identical distributions (D = %.4f, p < 2.2e-16).\n', ks2stat);
    else
        fprintf('of identical distributions (D = %.4f, p = %.2e).\n', ks2stat, p);
    end
else
    fprintf('\nConclusion:\n');
    fprintf('  At α=%.3f significance level, cannot reject null hypothesis (P ≥ α)\n', alpha);
    fprintf('  Top 25%% and bottom 25%% hashtags do not have significantly different distributions\n');
end

%% Step 8: Visualization
%% 步骤7：可视化（修复版）
fprintf('\nGenerating visualization charts...\n');

% 创建累积分布函数图
figure('Position', [100, 100, 1000, 800]);

% 计算CDF
[top_cdf, top_x] = ecdf(top_25_percent);
[bottom_cdf, bottom_x] = ecdf(bottom_25_percent);

% 确保x值是严格单调递增的
[top_x_unique, top_idx] = unique(top_x);
top_cdf_unique = top_cdf(top_idx);

[bottom_x_unique, bottom_idx] = unique(bottom_x);
bottom_cdf_unique = bottom_cdf(bottom_idx);

% 绘制CDF比较
subplot(2, 2, [1, 2]);
plot(top_x_unique, top_cdf_unique, 'b-', 'LineWidth', 2);
hold on;
plot(bottom_x_unique, bottom_cdf_unique, 'r-', 'LineWidth', 2);
hold off;

xlabel('Peak Volume (mentions per hour)', 'FontSize', 12);
ylabel('Cumulative Probability', 'FontSize', 12);
title('CDF: Top 25% vs Bottom 25% Hashtags', 'FontSize', 14);
legend({'Top 25% (High Virality)', 'Bottom 25% (Low Activity)'}, 'Location', 'best');
grid on;

% 标记最大垂直距离（D统计量）
% 创建共同的x轴网格
min_x = min(min(top_x_unique), min(bottom_x_unique));
max_x = max(max(top_x_unique), max(bottom_x_unique));
grid_x = linspace(min_x, max_x, 1000);

% 在共同网格上插值CDF
top_cdf_interp = interp1(top_x_unique, top_cdf_unique, grid_x, 'linear', 'extrap');
bottom_cdf_interp = interp1(bottom_x_unique, bottom_cdf_unique, grid_x, 'linear', 'extrap');

% 寻找最大差异
diff_cdf = abs(top_cdf_interp - bottom_cdf_interp);
[max_diff, max_idx] = max(diff_cdf);
max_diff_point = grid_x(max_idx);

% 在最大差异点绘制垂直线
hold on;
y_limits = ylim;
plot([max_diff_point, max_diff_point], y_limits, 'k--', 'LineWidth', 1.5);
text(max_diff_point, 0.5, sprintf('D = %.4f', ks2stat), ...
    'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', ...
    'FontSize', 10, 'BackgroundColor', 'white');
hold off;

% 箱线图比较 - 修复版本
subplot(2, 2, 3);

% 方法1：创建数据矩阵，每列是一个组
if length(top_25_percent) == length(bottom_25_percent)
    % 如果两组样本大小相同
    data_matrix = [bottom_25_percent(:), top_25_percent(:)];
    boxplot(data_matrix, 'Labels', {'Bottom 25%', 'Top 25%'});
else
    % 如果样本大小不同，使用分组变量
    % 确保所有数据都是列向量
    all_data = [bottom_25_percent(:); top_25_percent(:)];
    group = [ones(length(bottom_25_percent), 1); 2*ones(length(top_25_percent), 1)];
    boxplot(all_data, group, 'Labels', {'Bottom 25%', 'Top 25%'});
end

ylabel('Peak Volume (mentions per hour)', 'FontSize', 12);
title('Distribution Comparison: Boxplot', 'FontSize', 14);
grid on;

% 所有数据的直方图（对数尺度）
subplot(2, 2, 4);
histogram(twitter_max_values, 50, 'FaceColor', [0.5, 0.5, 0.5], 'EdgeColor', 'none');

% 添加显示25th和75th百分位的垂直线
hold on;
y_hist_limits = ylim;
plot([quantiles(1), quantiles(1)], y_hist_limits, 'r--', 'LineWidth', 1.5);
plot([quantiles(3), quantiles(3)], y_hist_limits, 'b--', 'LineWidth', 1.5);
hold off;

% 尝试设置对数刻度，如果失败则使用普通刻度
try
    set(gca, 'XScale', 'log');
    xlabel('Peak Volume (mentions per hour, log scale)', 'FontSize', 12);
    title('Distribution with 25th/75th Percentiles (Log Scale)', 'FontSize', 14);
catch
    xlabel('Peak Volume (mentions per hour)', 'FontSize', 12);
    title('Distribution with 25th/75th Percentiles', 'FontSize', 14);
end

ylabel('Frequency', 'FontSize', 12);
legend({'All Hashtags', '25th Percentile', '75th Percentile'}, 'Location', 'best');
grid on;

% 添加总标题
title('Twitter Hashtags: Top 25% vs Bottom 25% Distribution Analysis', 'FontSize', 16, 'FontWeight', 'bold');

%% Step 9: Extreme Value Analysis
fprintf('\n========== Extreme Value Analysis ==========\n');

% Sort in descending order for top values
[sorted_desc, sort_idx_desc] = sort(twitter_max_values, 'descend');

% Display top 10 hashtags
fprintf('Top 10 hashtags by peak volume:\n');
for i = 1:min(10, twitter_count)
    fprintf('  %2d. %s (ID: %s, Peak: %.2f)\n', ...
        i, twitter_metadata(sort_idx_desc(i)).content, ...
        twitter_metadata(sort_idx_desc(i)).id, sorted_desc(i));
end

% Sort in ascending order for bottom values
[sorted_asc, sort_idx_asc] = sort(twitter_max_values, 'ascend');

fprintf('\nBottom 10 hashtags by peak volume:\n');
for i = 1:min(10, twitter_count)
    fprintf('  %2d. %s (ID: %s, Peak: %.2f)\n', ...
        i, twitter_metadata(sort_idx_asc(i)).content, ...
        twitter_metadata(sort_idx_asc(i)).id, sorted_asc(i));
end

%% Step 10: Save Results
fprintf('\nSaving analysis results...\n');

% Save MAT file with all results
save('twitter_analysis_top25_bottom25.mat', 'ks2stat', 'p', 'h', ...
    'top_25_percent', 'bottom_25_percent', 'twitter_max_values', ...
    'BC', 'skew', 'kurt', 'mean_val', 'median_val', 'std_val', ...
    'quantiles', 'twitter_metadata');

% Save CSV file with group data
if exist('writetable', 'file') == 2
    group_data = table(top_25_percent', bottom_25_percent', ...
        'VariableNames', {'Top25Percent', 'Bottom25Percent'});
    writetable(group_data, 'twitter_top25_bottom25_groups.csv');
    fprintf('Group data saved to twitter_top25_bottom25_groups.csv\n');
else
    dlmwrite('twitter_top25_group.csv', top_25_percent, 'delimiter', ',');
    dlmwrite('twitter_bottom25_group.csv', bottom_25_percent, 'delimiter', ',');
    fprintf('Group data saved to CSV files\n');
end

%% Step 11: Generate Complete Summary Report
fprintf('\n========== Complete Analysis Summary ==========\n');
fprintf(['Dataset: Stanford SNAP Twitter Hashtag Dataset (June-December 2009)\n' ...
         'Number of hashtags analyzed: %d\n' ...
         'Analysis metric: Peak hourly mention rate\n' ...
         'Statistical test: Two-sample Kolmogorov-Smirnov test\n' ...
         'Comparison groups: Top 25%% hashtags vs Bottom 25%% hashtags\n' ...
         'Sample sizes: Top group n = %d, Bottom group n = %d\n' ...
         'Test statistic: D = %.4f\n' ...
         'P-value: p = %.2e\n' ...
         'Significance level: α = 0.001\n' ...
         'Test result: %s null hypothesis (identical distributions)\n' ...
         'Bimodality Coefficient (BC): %.4f %s\n' ...
         'Volume range ratio (max/min): %.2f:1\n' ...
         'Mean ratio (top25/bottom25): %.2f:1\n'], ...
         twitter_count, ...
         length(top_25_percent), length(bottom_25_percent), ...
         ks2stat, p, ...
         ifelse(p < 0.001, 'Reject', 'Do not reject'), ...
         BC, ifelse(BC > 0.555, '(Significant bimodality)', '(Not significant bimodality)'), ...
         max(top_25_percent)/min(bottom_25_percent), ...
         mean(top_25_percent)/mean(bottom_25_percent));

fprintf('\nKey findings:\n');
fprintf('1. BC value (%.4f) indicates %s bimodality\n', BC, ifelse(BC > 0.555, 'significant', 'no significant'));
fprintf('2. KS test %s that top 25%% and bottom 25%% come from different distributions\n', ifelse(p < 0.001, 'confirms', 'does not confirm'));
fprintf('3. The ratio between top and bottom groups is %.2f:1 in terms of maximum values\n', max(top_25_percent)/min(bottom_25_percent));
fprintf('4. The mean of top 25%% is %.2f times larger than bottom 25%%\n', mean(top_25_percent)/mean(bottom_25_percent));

fprintf('\nAnalysis complete!\n');
fprintf('Results saved to:\n');
fprintf('  - twitter_analysis_top25_bottom25.mat\n');
fprintf('  - twitter_top25_bottom25_groups.csv\n');

%% Helper Function
