%% Step 8: Visualization with Modified Figure 3(c)
fprintf('\nGenerating visualization charts...\n');

% 创建累积分布函数图
figure('Position', [100, 100, 1200, 800], 'Name', 'Twitter Hashtags Distribution Analysis');

% 计算CDF
[top_cdf, top_x] = ecdf(top_25_percent);
[bottom_cdf, bottom_x] = ecdf(bottom_25_percent);

% 确保x值是严格单调递增的
[top_x_unique, top_idx] = unique(top_x);
top_cdf_unique = top_cdf(top_idx);

[bottom_x_unique, bottom_idx] = unique(bottom_x);
bottom_cdf_unique = bottom_cdf(bottom_idx);

% ===== 绘制CDF比较 =====
subplot(2, 3, 1:2);
plot(top_x_unique, top_cdf_unique, 'b-', 'LineWidth', 2.5);
hold on;
plot(bottom_x_unique, bottom_cdf_unique, 'r-', 'LineWidth', 2.5);
hold off;

xlabel('Peak Volume (mentions per hour)', 'FontSize', 11);
ylabel('Cumulative Probability', 'FontSize', 11);
title('(a) CDF: Top 25% vs Bottom 25% Hashtags', 'FontSize', 12, 'FontWeight', 'bold');
legend({'Top 25% (High Virality)', 'Bottom 25% (Low Activity)'}, 'Location', 'best');
grid on;

% 标记最大垂直距离（D统计量）
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

% ===== 箱线图比较 =====
subplot(2, 3, 3);

% 创建分组数据
all_data = [bottom_25_percent(:); top_25_percent(:)];
group = [ones(length(bottom_25_percent), 1); 2*ones(length(top_25_percent), 1)];
boxplot(all_data, group, 'Labels', {'Bottom 25%', 'Top 25%'}, 'Widths', 0.6);

ylabel('Peak Volume (mentions per hour)', 'FontSize', 11);
title('(b) Distribution Comparison: Boxplot', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% 设置y轴为对数尺度以便更好显示
set(gca, 'YScale', 'log');

% ===== 修改的图3(c): 所有数据的直方图（对数纵坐标） =====
subplot(2, 3, 4:6);

% 使用合适的bin数量
num_bins = min(50, round(sqrt(length(twitter_max_values))));
[num_counts, bin_edges] = histcounts(twitter_max_values, num_bins);
bin_centers = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;

% 绘制直方图（纵坐标对数尺度）
bar(bin_centers, num_counts, 'FaceColor', [0.5, 0.5, 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.7);

% 添加显示25th和75th百分位的垂直线
hold on;
y_hist_limits = ylim;

% 计算合适的y位置标注文本
text_y_pos = max(num_counts) * 0.9;

% 绘制25%分位线（Q1）
q1_line = plot([quantiles(1), quantiles(1)], [1, max(num_counts)], 'r--', 'LineWidth', 2.5);
text(quantiles(1), text_y_pos, sprintf('Q1 (25%%)\n%.2f', quantiles(1)), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
    'FontSize', 10, 'BackgroundColor', 'white', 'Color', 'red');

% 绘制中位线（Median）
median_line = plot([median_val, median_val], [1, max(num_counts)], 'g--', 'LineWidth', 2.5);
text(median_val, text_y_pos*0.85, sprintf('Median\n%.2f', median_val), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
    'FontSize', 10, 'BackgroundColor', 'white', 'Color', 'green');

% 绘制75%分位线（Q3）
q3_line = plot([quantiles(3), quantiles(3)], [1, max(num_counts)], 'b--', 'LineWidth', 2.5);
text(quantiles(3), text_y_pos*0.95, sprintf('Q3 (75%%)\n%.2f', quantiles(3)), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
    'FontSize', 10, 'BackgroundColor', 'white', 'Color', 'blue');

hold off;

% 设置纵坐标为对数尺度
set(gca, 'YScale', 'log');

% 设置横坐标为对数尺度
set(gca, 'XScale', 'log');

xlabel('Peak Volume (mentions per hour, log scale)', 'FontSize', 11);
ylabel('Frequency (log scale)', 'FontSize', 11);
title('(c) Distribution with Percentile Markers (Log-Log Scale)', 'FontSize', 12, 'FontWeight', 'bold');

% 添加图例
legend([q1_line, median_line, q3_line], {'25th Percentile (Q1)', 'Median (Q2)', '75th Percentile (Q3)'}, ...
    'Location', 'best', 'FontSize', 9);

grid on;

% 调整子图间距
set(gcf, 'Color', 'white');

% 添加总标题
title({'Twitter Hashtags Distribution Analysis: Top 25% vs Bottom 25%', ...
    sprintf('Bimodality Coefficient (BC) = %.4f, KS Statistic D = %.4f (p = %.2e)', BC, ks2stat, p)}, ...
    'FontSize', 14, 'FontWeight', 'bold');

%% 添加单独的图3(c)版本（更接近论文格式）
figure('Position', [200, 200, 800, 600], 'Name', 'Figure 3(c): Bimodal Distribution of Twitter Hashtags');

% 创建更精细的直方图
num_bins_fine = min(60, round(sqrt(length(twitter_max_values)) * 1.5));
[num_counts_fine, bin_edges_fine] = histcounts(twitter_max_values, num_bins_fine);
bin_centers_fine = (bin_edges_fine(1:end-1) + bin_edges_fine(2:end)) / 2;

% 绘制直方图
bar(bin_centers_fine, num_counts_fine, 'FaceColor', [0.3, 0.5, 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.8);

% 标记关键百分位
hold on;
y_max = max(num_counts_fine);

% 25%分位线
q1_x = quantiles(1);
plot([q1_x, q1_x], [1, y_max], 'r--', 'LineWidth', 2);
text(q1_x, y_max*0.8, 'Q1', 'HorizontalAlignment', 'center', ...
    'FontSize', 11, 'FontWeight', 'bold', 'Color', 'red', 'BackgroundColor', 'white');

% 75%分位线
q3_x = quantiles(3);
plot([q3_x, q3_x], [1, y_max], 'b--', 'LineWidth', 2);
text(q3_x, y_max*0.8, 'Q3', 'HorizontalAlignment', 'center', ...
    'FontSize', 11, 'FontWeight', 'bold', 'Color', 'blue', 'BackgroundColor', 'white');

% 添加区域标注
text(q1_x/2, y_max*0.6, '75% of hashtags', 'HorizontalAlignment', 'center', ...
    'FontSize', 10, 'BackgroundColor', [1, 1, 1, 0.8], 'EdgeColor', 'black');
text((q3_x + max(twitter_max_values))/2, y_max*0.3, '25% of hashtags', 'HorizontalAlignment', 'center', ...
    'FontSize', 10, 'BackgroundColor', [1, 1, 1, 0.8], 'EdgeColor', 'black');

hold off;

% 设置双对数坐标轴
set(gca, 'XScale', 'log', 'YScale', 'log');

% 标签和标题
xlabel('Peak Hourly Mention Volume (log scale)', 'FontSize', 12);
ylabel('Frequency (log scale)', 'FontSize', 12);
title('Bimodal Distribution of Twitter Hashtags', 'FontSize', 14, 'FontWeight', 'bold');

% 添加网格
grid on;

% 添加统计信息标注框
annotation_text = {sprintf('Bimodality Coefficient: %.4f', BC), ...
    sprintf('25th Percentile (Q1): %.2f', quantiles(1)), ...
    sprintf('75th Percentile (Q3): %.2f', quantiles(3)), ...
    sprintf('Volume Range: %.2f to %.2f', min_val, max_val), ...
    sprintf('Volume Ratio: %.0f:1', max_val/min_val)};

annotation('textbox', [0.15, 0.7, 0.25, 0.15], ...
    'String', annotation_text, ...
    'FontSize', 9, ...
    'BackgroundColor', 'white', ...
    'EdgeColor', 'black', ...
    'FitBoxToText', 'on');

fprintf('Visualization completed with modified Figure 3(c).\n');