% Experiment 1 and 2: Calculating the maximum Lyapunov exponent as parameters vary
% Adaptive Hypergraph Contagion Model

clear; clc; close all;

%% Define basic parameter structure (stable phase parameters)
params.beta1 = 0.05;       % Transmission rate for active nodes
params.beta2 = 0.015;      % Transmission rate for passive nodes
params.betaDelta = 0.474;  % Higher-order reinforcement strength (baseline, will be varied in Experiment 1)
params.gamma = 0.45;       % Rewiring rate (baseline, will be varied in Experiment 2)
params.eta = 0.78;         % Information accuracy
params.alpha = 0.128;      % Random avoidance rate
params.pA = 0.05;          % Proportion of active nodes
params.mu = 0.52;          % Recovery rate
params.avg_k = 4;          % Average pairwise degree
params.avg_kDelta = 4;     % Average hyperdegree
params.avg_n = 5;          % Average hyperedge size
params.k_c = 2;            % Critical mass threshold
params.i_star = 2;         % Optimal risk threshold

%% Initial conditions (small infection density)
I_A0 = 0.001;
I_P0 = 0.001;
S_A0 = params.pA - I_A0;
S_P0 = 1 - params.pA - I_P0;
initial_conditions = [S_A0; S_P0; I_A0; I_P0];

%% Lyapunov exponent calculation parameters
T_transient = 100;     % Transient time (ensures system reaches attractor)
T = 500;               % Total time for ¦Ë_max calculation
dt = 1;                % Time step for perturbation renormalization

fprintf('===== Adaptive Hypergraph Contagion Model - Lyapunov Exponent Analysis =====\n');
fprintf('Transient time: %.0f, Total integration time: %.0f, Step size: %.2f\n', T_transient, T, dt);

%% Experiment 1: Single parameter scan - Effect of ¦Â¦¤ on ¦Ë_max
fprintf('\n===== Experiment 1: Scanning ¦Â¦¤ parameter =====\n');

betaDelta_values = linspace(0.30, 0.6, 50);  % 100 points
lambda_max_exp1 = zeros(size(betaDelta_values));

for idx = 1:length(betaDelta_values)
    % Update parameter
    current_params = params;
    current_params.betaDelta = betaDelta_values(idx);
    
    % Calculate maximum Lyapunov exponent
    lambda_max_exp1(idx) = compute_lyapunov(current_params, initial_conditions, T_transient, T, dt);
    
    fprintf('¦Â¦¤ = %.4f, ¦Ë_max = %.6e\n', betaDelta_values(idx), lambda_max_exp1(idx));
    
    % Display progress every 5 points
    if mod(idx, 5) == 0
        fprintf('Progress: %d/%d\n', idx, length(betaDelta_values));
    end
end

% Plot Experiment 1 results
figure('Position', [100, 100, 1200, 400]);

subplot(1,3,1);
plot(betaDelta_values, lambda_max_exp1, 'b-', 'LineWidth', 2);
hold on;
plot(betaDelta_values, zeros(size(betaDelta_values)), 'r--', 'LineWidth', 1.5);
xlabel('Higher-order reinforcement strength ¦Â_¦¤');
ylabel('Maximum Lyapunov exponent ¦Ë_{max}');
title('(a) ¦Ë_{max} vs. ¦Â_¦¤');
grid on;
legend('¦Ë_{max}', 'Zero line', 'Location', 'best');

% Mark known parameter points
known_betaDelta = [0.45, 0.474];
for i = 1:2
    idx = find(abs(betaDelta_values - known_betaDelta(i)) < 0.001);
    if ~isempty(idx)
        plot(betaDelta_values(idx), lambda_max_exp1(idx), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
        text(betaDelta_values(idx)+0.002, lambda_max_exp1(idx), ...
            sprintf('(%.3f, %.2e)', betaDelta_values(idx), lambda_max_exp1(idx)), ...
            'FontSize', 9);
    end
end

%% Experiment 2: Two-parameter scan - ¦Ë_max in (¦Â¦¤, ¦Ã) plane
fprintf('\n===== Experiment 2: Scanning (¦Â¦¤, ¦Ã) parameter plane =====\n');

betaDelta_grid = linspace(0.40, 0.55, 20);
gamma_grid = linspace(0.30, 0.70, 20);
lambda_max_exp2 = zeros(length(betaDelta_grid), length(gamma_grid));

total_points = length(betaDelta_grid) * length(gamma_grid);
current_point = 0;

% Use parallel computing if available
try
    parfor i = 1:length(betaDelta_grid)
        lambda_row = zeros(1, length(gamma_grid));
        
        for j = 1:length(gamma_grid)
            % Create local parameter copy
            local_params = params;
            local_params.betaDelta = betaDelta_grid(i);
            local_params.gamma = gamma_grid(j);
            
            % Calculate maximum Lyapunov exponent
            lambda_row(j) = compute_lyapunov(local_params, initial_conditions, T_transient, T, dt);
            
            % Update progress (approximate)
            current_point = current_point + 1;
        end
        
        lambda_max_exp2(i, :) = lambda_row;
        fprintf('Completed row for ¦Â¦¤ = %.3f (%d/%d)\n', betaDelta_grid(i), i, length(betaDelta_grid));
    end
catch ME
    % If parallel computing fails, use serial
    fprintf('Parallel computing failed, using serial: %s\n', ME.message);
    
    for i = 1:length(betaDelta_grid)
        for j = 1:length(gamma_grid)
            % Update parameters
            local_params = params;
            local_params.betaDelta = betaDelta_grid(i);
            local_params.gamma = gamma_grid(j);
            
            % Calculate maximum Lyapunov exponent
            lambda_max_exp2(i, j) = compute_lyapunov(local_params, initial_conditions, T_transient, T, dt);
            
            current_point = current_point + 1;
            if mod(current_point, 50) == 0
                fprintf('Progress: %d/%d\n', current_point, total_points);
            end
        end
    end
end

% Plot Experiment 2 results
subplot(1,3,2);
imagesc(betaDelta_grid, gamma_grid, lambda_max_exp2');
set(gca, 'YDir', 'normal');
colorbar;
xlabel('Higher-order reinforcement strength ¦Â_¦¤');
ylabel('Rewiring rate ¦Ã');
title('(b) ¦Ë_{max} heatmap on (¦Â_¦¤, ¦Ã) plane');
hold on;

% Draw zero contour line (stability-chaos boundary)
contour(betaDelta_grid, gamma_grid, lambda_max_exp2', [0,0], 'w', 'LineWidth', 2);
contour(betaDelta_grid, gamma_grid, lambda_max_exp2', [-1e-5, -1e-5], 'c--', 'LineWidth', 1);
contour(betaDelta_grid, gamma_grid, lambda_max_exp2', [1e-5, 1e-5], 'm--', 'LineWidth', 1);

% Mark known parameter points
plot(0.45, 0.45, 'wx', 'MarkerSize', 10, 'LineWidth', 2);  % Stable phase point
plot(0.474, 0.55, 'wo', 'MarkerSize', 10, 'LineWidth', 2); % Chaotic phase point
legend('Zero line (¦Ë=0)', '¦Ë=-1e-5', '¦Ë=1e-5', 'Stable phase', 'Chaotic phase', 'Location', 'best');

%% Experiment 3: Effect of ¦Ç parameter (supplementary)
fprintf('\n===== Experiment 3: Scanning ¦Ç parameter =====\n');

eta_values = linspace(0.1, 0.9, 21);
lambda_max_exp3 = zeros(size(eta_values));

% Use chaotic phase parameters
chaos_params = params;
chaos_params.betaDelta = 0.474;
chaos_params.gamma = 0.55;

for idx = 1:length(eta_values)
    chaos_params.eta = eta_values(idx);
    lambda_max_exp3(idx) = compute_lyapunov(chaos_params, initial_conditions, T_transient, T, dt);
    fprintf('¦Ç = %.3f, ¦Ë_max = %.6e\n', eta_values(idx), lambda_max_exp3(idx));
end

% Plot Experiment 3 results
subplot(1,3,3);
plot(eta_values, lambda_max_exp3, 'g-', 'LineWidth', 2);
hold on;
plot(eta_values, zeros(size(eta_values)), 'r--', 'LineWidth', 1.5);
xlabel('Information accuracy ¦Ç');
ylabel('¦Ë_{max}');
title('(c) ¦Ë_{max} vs. ¦Ç (¦Â_¦¤=0.474, ¦Ã=0.55)');
grid on;

% Mark maximum point
[max_val, max_idx] = max(lambda_max_exp3);
plot(eta_values(max_idx), max_val, 'go', 'MarkerSize', 10, 'LineWidth', 2);
text(eta_values(max_idx)+0.02, max_val, ...
    sprintf('Maximum: ¦Ç=%.2f\n¦Ë=%.2e', eta_values(max_idx), max_val), ...
    'FontSize', 9);

%% Comprehensive analysis: Parameter sensitivity (commented out)
% subplot(2,2,4);
% 
% % Calculate gradient for each parameter (approximation)
% betaDelta_grad = gradient(lambda_max_exp1, betaDelta_values);
% [~, max_grad_idx] = max(abs(betaDelta_grad));
% critical_betaDelta = betaDelta_values(max_grad_idx);
% 
% % Display key findings
% text(0.05, 0.9, sprintf('Key Findings:'), 'FontSize', 10, 'FontWeight', 'bold');
% text(0.05, 0.8, sprintf('1. Critical ¦Â_¦¤ ¡Ö %.4f', critical_betaDelta), 'FontSize', 9);
% text(0.05, 0.7, sprintf('2. Stable phase: ¦Â_¦¤=0.450, ¦Ë=%.2e', lambda_max_exp1(11)), 'FontSize', 9);
% text(0.05, 0.6, sprintf('3. Chaotic phase: ¦Â_¦¤=0.474, ¦Ë=%.2e', lambda_max_exp1(15)), 'FontSize', 9);
% text(0.05, 0.5, sprintf('4. Optimal ¦Ç ¡Ö %.2f', eta_values(max_idx)), 'FontSize', 9);
% text(0.05, 0.4, sprintf('5. Phase boundary: when ¦Ã=0.55'), 'FontSize', 9);
% text(0.05, 0.3, sprintf('   critical ¦Â_¦¤ ¡Ö 0.465'), 'FontSize', 9);
% axis off;
% 
% title('Dynamical Phase Analysis of Adaptive Hypergraph Contagion Model', 'FontSize', 14, 'FontWeight', 'bold');

%% Save results
save('lyapunov_analysis_results.mat', ...
    'betaDelta_values', 'lambda_max_exp1', ...
    'betaDelta_grid', 'gamma_grid', 'lambda_max_exp2', ...
    'eta_values', 'lambda_max_exp3', ...
    'params', 'initial_conditions');

fprintf('\n===== Analysis completed, results saved =====\n');

%% Generate report file
generate_report(betaDelta_values, lambda_max_exp1, betaDelta_grid, gamma_grid, lambda_max_exp2);

fprintf('Report generated: lyapunov_analysis_report.txt\n');