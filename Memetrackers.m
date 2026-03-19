%% 清理工作空间
clear; clc; close all;

%% 1. 下载数据文件
fprintf('正在下载数据文件...\n');

% Memetracker数据文件的URL
url = 'http://memetracker.org/data/MemePhr.txt';
%url ='https://snap.stanford.edu/data/TwtHtag.txt';
local_filename = 'MemePhr.txt';

% 检查文件是否已经存在
if ~exist(local_filename, 'file')
    try
        % 使用websave下载文件（需要MATLAB R2014b或更高版本）
        options = weboptions('Timeout', 120); % 设置较长的超时时间
        websave(local_filename, url, options);
        fprintf('文件下载完成！\n');
    catch
        % 如果websave失败，尝试使用urlwrite（旧版本MATLAB）
        try
            urlwrite(url, local_filename);
            fprintf('文件下载完成！\n');
        catch ME
            error('无法下载文件。请检查网络连接或手动下载文件。\n错误信息: %s', ME.message);
        end
    end
else
    fprintf('文件已存在，跳过下载。\n');
end

%% 2. 逐行读取和处理数据
fprintf('正在处理数据...\n');

% 打开文件
fileID = fopen(local_filename, 'r', 'n', 'UTF-8');
if fileID == -1
    error('无法打开文件: %s', local_filename);
end

% 初始化变量
time_series_data = [];  % 存储时间序列数据
metadata = struct();    % 存储元数据
count = 0;
max_phrases = 1000;     % 只读取前1000个短语

% 逐行读取文件
line_num = 0;
while ~feof(fileID) && count < max_phrases
    % 读取元数据行
    meta_line = fgetl(fileID);
    line_num = line_num + 1;
    
    if ~ischar(meta_line) || isempty(meta_line)
        continue; % 跳过空行
    end
    
    % 读取时间序列行
    ts_line = fgetl(fileID);
    line_num = line_num + 1;
    
    if ~ischar(ts_line) || isempty(ts_line)
        continue; % 跳过空行
    end
    
    % 解析元数据行
    meta_parts = strsplit(meta_line, '\t');
    
    if length(meta_parts) < 5
        fprintf('警告: 第%d行元数据格式不正确，跳过\n', line_num-1);
        continue;
    end
    
    % 提取元数据
    id = meta_parts{1};
    content = meta_parts{2};
    begin_time_str = meta_parts{3};
    num_qt = str2double(meta_parts{4});
    peak_time_str = meta_parts{5};
    
    count = count + 1;
    
    % 存储元数据
    metadata(count).id = id;
    metadata(count).content = content;
    metadata(count).begin_time_str = begin_time_str;
    metadata(count).num_qt = num_qt;
    metadata(count).peak_time_str = peak_time_str;
    
    % 解析时间序列数据
    ts_parts = strsplit(ts_line, '\t');
    ts_values = zeros(1, length(ts_parts));
    
    for i = 1:length(ts_parts)
        ts_values(i) = str2double(ts_parts{i});
    end
    
    % 去除NaN值，确保有128个值
    ts_values = ts_values(~isnan(ts_values));
    
    % 如果长度不是128，可能需要调整
    if length(ts_values) > 128
        ts_values = ts_values(1:128);
    elseif length(ts_values) < 128
        % 用0填充不足的部分
        ts_values = [ts_values, zeros(1, 128 - length(ts_values))];
    end
    
    % 存储时间序列数据
    time_series_data(count, :) = ts_values;
    
    % 显示进度
    if mod(count, 100) == 0
        fprintf('已处理 %d 个短语...\n', count);
    end
end

% 关闭文件
fclose(fileID);

fprintf('成功提取 %d 个Memetracker phrases\n', count);

%% 3. 计算每个时间序列的最大值点
fprintf('正在计算最大值点...\n');

max_values = zeros(count, 1);
max_positions = zeros(count, 1);

for i = 1:count
    [max_val, max_pos] = max(time_series_data(i, :));
    max_values(i) = max_val;
    max_positions(i) = max_pos;
    
    % 存储到元数据中
    metadata(i).max_value = max_val;
    metadata(i).max_position = max_pos;
end

%% 4. 绘制部分时间序列图（示例）
fprintf('绘制示例时间序列图...\n');

% 绘制前9个时间序列
figure('Position', [50, 50, 1400, 900]);
for i = 1:min(9, count)
    subplot(3, 3, i);
    plot(time_series_data(i, :), 'b-', 'LineWidth', 1.5);
    hold on;
    
    % 标记最大值点
    plot(max_positions(i), max_values(i), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    
    title_str = metadata(i).content;
    if length(title_str) > 30
        title_str = [title_str(1:27) '...'];
    end
    
    title({sprintf('Phrase: %s', title_str), ...
           sprintf('Max: %.2f at hour %d', max_values(i), max_positions(i))}, ...
           'Interpreter', 'none', 'FontSize', 10);
    xlabel('Hour Index');
    ylabel('Mention Volume');
    grid on;
    legend('Time Series', 'Max Point', 'Location', 'best');
end
title('Memetracker Phrases时间序列及最大值点（示例）', 'FontSize', 14, 'FontWeight', 'bold');

%% 5. 绘制所有时间序列的叠加图
figure('Position', [50, 50, 1200, 600]);
hold on;

% 绘制所有时间序列（使用半透明线条）
for i = 1:count
    plot(time_series_data(i, :), 'Color', [0, 0.447, 0.741, 0.05], 'LineWidth', 0.5);
end

% 绘制平均时间序列
mean_ts = mean(time_series_data, 1);
plot(mean_ts, 'k-', 'LineWidth', 3);

xlabel('Hour Index (0-127 hours)');
ylabel('Mention Volume');
title(sprintf('%d个Memetracker Phrases时间序列叠加图\n(蓝色: 单个时间序列, 黑色: 平均值)', count), 'FontSize', 12);
grid on;
legend('单个时间序列', '平均时间序列', 'Location', 'best');

%% 6. 计算并绘制每个时间点的1/4和3/4分位数
fprintf('正在计算分位数...\n');

q1_per_hour = zeros(1, 128);  % 每个时间点的1/4分位数
q3_per_hour = zeros(1, 128);  % 每个时间点的3/4分位数

for hour = 1:128
    hourly_data = time_series_data(:, hour);
    q1_per_hour(hour) = quantile(hourly_data, 0.25);
    q3_per_hour(hour) = quantile(hourly_data, 0.75);
end

% 绘制分位数图
figure('Position', [50, 50, 1400, 500]);

subplot(1, 3, 1);
plot(1:128, q1_per_hour, 'b-', 'LineWidth', 2);
hold on;
plot(1:128, q3_per_hour, 'r-', 'LineWidth', 2);
fill([1:128, fliplr(1:128)], [q1_per_hour, fliplr(q3_per_hour)], ...
    [0.8, 0.8, 1], 'FaceAlpha', 0.3, 'EdgeColor', 'none');

xlabel('Hour Index');
ylabel('Mention Volume');
title('每个时间点的1/4和3/4分位数', 'FontSize', 12);
legend('Q1 (25th percentile)', 'Q3 (75th percentile)', 'Interquartile Range', 'Location', 'best');
grid on;

% 分位数的统计摘要
subplot(1, 3, 2);
summary_data = [q1_per_hour', q3_per_hour'];
boxplot(summary_data, 'Labels', {'Q1', 'Q3'});
ylabel('Mention Volume');
title('分位数统计摘要', 'FontSize', 12);
grid on;

% 分位数的随时间变化
subplot(1, 3, 3);
plot(1:128, q1_per_hour, 'b-', 'LineWidth', 2);
hold on;
plot(1:128, mean_ts, 'k-', 'LineWidth', 2);
plot(1:128, q3_per_hour, 'r-', 'LineWidth', 2);
xlabel('Hour Index');
ylabel('Mention Volume');
title('Q1、平均值和Q3随时间变化', 'FontSize', 12);
legend('Q1 (25th percentile)', 'Mean', 'Q3 (75th percentile)', 'Location', 'best');
grid on;

%% 7. 统计最大值点的分布
figure('Position', [50, 50, 1400, 400]);

% 最大值分布
subplot(1, 4, 1);
histogram(max_values, 50, 'FaceColor', [0.2, 0.6, 0.8]);
xlabel('Maximum Value');
ylabel('Frequency');
title('最大值分布', 'FontSize', 12);
grid on;

% 最大值出现时间分布
subplot(1, 4, 2);
histogram(max_positions, 50, 'FaceColor', [0.8, 0.4, 0.2]);
xlabel('Hour Position of Maximum');
ylabel('Frequency');
title('最大值出现时间分布', 'FontSize', 12);
grid on;

% 最大值 vs. 出现时间散点图
subplot(1, 4, 3);
scatter(max_positions, max_values, 30, 'filled', 'MarkerFaceAlpha', 0.5, ...
    'MarkerFaceColor', [0.3, 0.7, 0.3]);
xlabel('Hour Position');
ylabel('Maximum Value');
title('最大值 vs. 出现时间', 'FontSize', 12);
grid on;

% 累积分布函数
subplot(1, 4, 4);
cdf_values = 1:count;
cdf_values = cdf_values / count;
[sorted_max, idx] = sort(max_values);
plot(sorted_max, cdf_values, 'b-', 'LineWidth', 2);
xlabel('Maximum Value');
ylabel('CDF');
title('最大值累积分布函数', 'FontSize', 12);
grid on;

%% 8. 输出统计摘要
fprintf('\n========== 统计分析摘要 ==========\n');
fprintf('分析的时间序列数量: %d\n', count);
fprintf('时间序列长度: 128 hours\n\n');

fprintf('最大值统计:\n');
fprintf('  平均值: %.4f\n', mean(max_values));
fprintf('  中位数: %.4f\n', median(max_values));
fprintf('  最小值: %.4f\n', min(max_values));
fprintf('  最大值: %.4f\n', max(max_values));
fprintf('  标准差: %.4f\n', std(max_values));
fprintf('  变异系数: %.4f\n', std(max_values)/mean(max_values));

fprintf('\n最大值出现时间统计:\n');
fprintf('  平均值: %.2f hours\n', mean(max_positions));
fprintf('  中位数: %.0f hours\n', median(max_positions));
fprintf('  范围: %d to %d hours\n', min(max_positions), max(max_positions));
fprintf('  标准差: %.2f hours\n', std(max_positions));

fprintf('\n分位数统计（整个数据集）:\n');
fprintf('  Q1 (25th percentile): %.6f\n', quantile(time_series_data(:), 0.25));
fprintf('  Q3 (75th percentile): %.6f\n', quantile(time_series_data(:), 0.75));
fprintf('  IQR (Q3-Q1): %.6f\n', quantile(time_series_data(:), 0.75) - quantile(time_series_data(:), 0.25));
fprintf('  中位数: %.6f\n', median(time_series_data(:)));
fprintf('  平均值: %.6f\n', mean(time_series_data(:)));

% 计算数据集中非零值的比例
non_zero_ratio = sum(time_series_data(:) > 0) / numel(time_series_data);
fprintf('\n数据特性:\n');
fprintf('  非零值比例: %.2f%%\n', non_zero_ratio * 100);
fprintf('  总提及量: %.0f\n', sum(time_series_data(:)));

%% 9. 保存结果到文件
fprintf('\n正在保存结果...\n');

% 保存时间序列数据
save('memetracker_analysis_results.mat', 'time_series_data', 'metadata', ...
    'max_values', 'max_positions', 'q1_per_hour', 'q3_per_hour', 'mean_ts');

% 保存统计摘要到文本文件
summary_file = fopen('memetracker_statistical_summary.txt', 'w', 'n', 'UTF-8');
fprintf(summary_file, 'Memetracker Phrases Statistical Analysis Summary\n');
fprintf(summary_file, '===============================================\n\n');
fprintf(summary_file, 'Data Source: %s\n', url);
fprintf(summary_file, 'Analysis Date: %s\n\n', datestr(now));

fprintf(summary_file, 'Number of time series analyzed: %d\n', count);
fprintf(summary_file, 'Time series length: 128 hours\n\n');

fprintf(summary_file, 'Maximum Value Statistics:\n');
fprintf(summary_file, '  Mean: %.4f\n', mean(max_values));
fprintf(summary_file, '  Median: %.4f\n', median(max_values));
fprintf(summary_file, '  Min: %.4f\n', min(max_values));
fprintf(summary_file, '  Max: %.4f\n', max(max_values));
fprintf(summary_file, '  Std Dev: %.4f\n', std(max_values));
fprintf(summary_file, '  Coefficient of Variation: %.4f\n\n', std(max_values)/mean(max_values));

fprintf(summary_file, 'Maximum Position Statistics:\n');
fprintf(summary_file, '  Mean: %.2f hours\n', mean(max_positions));
fprintf(summary_file, '  Median: %.0f hours\n', median(max_positions));
fprintf(summary_file, '  Range: %d to %d hours\n', min(max_positions), max(max_positions));
fprintf(summary_file, '  Std Dev: %.2f hours\n\n', std(max_positions));

fprintf(summary_file, 'Quantile Statistics (entire dataset):\n');
fprintf(summary_file, '  Q1 (25th percentile): %.6f\n', quantile(time_series_data(:), 0.25));
fprintf(summary_file, '  Q3 (75th percentile): %.6f\n', quantile(time_series_data(:), 0.75));
fprintf(summary_file, '  IQR (Q3-Q1): %.6f\n', quantile(time_series_data(:), 0.75) - quantile(time_series_data(:), 0.25));
fprintf(summary_file, '  Median: %.6f\n', median(time_series_data(:)));
fprintf(summary_file, '  Mean: %.6f\n\n', mean(time_series_data(:)));

fprintf(summary_file, 'Data Characteristics:\n');
fprintf(summary_file, '  Non-zero ratio: %.2f%%\n', non_zero_ratio * 100);
fprintf(summary_file, '  Total mentions: %.0f\n', sum(time_series_data(:)));

% 列出前10个最大值短语
fprintf(summary_file, '\nTop 10 Phrases by Maximum Value:\n');
[~, sorted_idx] = sort(max_values, 'descend');
for i = 1:min(10, count)
    fprintf(summary_file, '  %d. %s (Max: %.2f, Position: %d)\n', ...
        i, metadata(sorted_idx(i)).content, ...
        max_values(sorted_idx(i)), max_positions(sorted_idx(i)));
end

fclose(summary_file);

fprintf('分析完成！结果已保存。\n');
fprintf('保存的文件:\n');
fprintf('  - memetracker_analysis_results.mat (MATLAB数据文件)\n');
fprintf('  - memetracker_statistical_summary.txt (统计摘要)\n');