function lambda_max = compute_lyapunov(params, initial_conditions, T_transient, T, dt)
% 计算最大李雅普诺夫指数 (Wolf算法)
% 输入:
%   params: 参数结构体
%   initial_conditions: 初始条件 [S_A0; S_P0; I_A0; I_P0]
%   T_transient: 瞬态消除时间
%   T: 总积分时间
%   dt: 重新调整扰动的时间步长
% 输出:
%   lambda_max: 最大李雅普诺夫指数

    % 设置ODE求解选项（高精度）
    options = odeset('RelTol', 1e-8, 'AbsTol', 1e-10, 'MaxStep', 0.1);
    
    %% 第一步：消除瞬态，使系统达到吸引子
    [~, x_transient] = ode45(@(t,x) ode_social_contagion(t,x,params), ...
        [0, T_transient], initial_conditions, options);
    
    % 取瞬态后的状态作为吸引子上的初始点
    x0 = x_transient(end, :)';
    
    %% 第二步：Wolf算法计算最大李雅普诺夫指数
    N_steps = round(T / dt);          % 总步数
    delta0 = 1e-8;                    % 初始扰动大小
    
    % 随机初始化单位扰动向量
    rng('shuffle');
    e0 = randn(4, 1);
    e0 = e0 / norm(e0);
    
    lyap_sum = 0;                     % 累积分离增长率
    n_effective = 0;                  % 有效步数计数
    
    % 循环计算
    for step = 1:N_steps
        try
            % 积分基线轨迹
            [~, x_temp] = ode45(@(t,x) ode_social_contagion(t,x,params), ...
                [0, dt], x0, options);
            x1 = x_temp(end, :)';
            
            % 积分扰动轨迹 (从x0 + delta0*e0开始)
            y0 = x0 + delta0 * e0;
            [~, y_temp] = ode45(@(t,x) ode_social_contagion(t,x,params), ...
                [0, dt], y0, options);
            y1 = y_temp(end, :)';
            
            % 计算分离距离
            delta1 = norm(y1 - x1);
            
            % 避免数值问题
            if delta1 > 0 && isfinite(delta1)
                % 计算这一步的增长率
                growth = log(delta1 / delta0);
                lyap_sum = lyap_sum + growth;
                n_effective = n_effective + 1;
                
                % 重新调整扰动方向
                e1 = (y1 - x1) / delta1;
                
                % 更新为下一步
                x0 = x1;
                e0 = e1;
            else
                % 如果分离无效，保持当前状态
                x0 = x1;
                % 重新随机化扰动方向
                e0 = randn(4, 1);
                e0 = e0 / norm(e0);
            end
            
        catch ME
            % 处理积分错误
            warning('ODE积分错误在步 %d: %s', step, ME.message);
            break;
        end
        
        % 每100步显示一次进度
        if mod(step, 100) == 0
            fprintf('  λ计算进度: %d/%d 步\n', step, N_steps);
        end
    end
    
    %% 第三步：计算平均增长率
    if n_effective > 0
        lambda_max = lyap_sum / (n_effective * dt);
    else
        lambda_max = NaN;
        warning('未能计算有效的李雅普诺夫指数');
    end
    
    % 输出调试信息
    fprintf('    计算完成: %d有效步, λ_max = %.6e\n', n_effective, lambda_max);
end