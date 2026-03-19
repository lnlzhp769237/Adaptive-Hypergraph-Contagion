function [I_initial, I_final, valid] = get_initial_final(sim_idx, mu, beta1, beta2, beta_delta, ...
                                                        k_avg, k_delta_avg, n_avg, k_c, ...
                                                        gamma, eta, i_star, alpha, tspan)
    % 设置可重复随机种子
    rng(sim_idx);
    
    % 生成初始条件
    y0 = generate_initial_conditions();
    I_initial = y0(3) + y0(4);
    valid = true;
    
    % 运行模拟
    try
        [~, y] = ode45(@(t,y) game_equations(t, y, mu, beta1, beta2, beta_delta, ...
                                            k_avg, k_delta_avg, n_avg, k_c, ...
                                            gamma, eta, i_star, alpha), ...
                      tspan, y0);
        
        % 检查模拟结果有效性
        final_state = y(end, :);
        if any(final_state < -0.01) || any(final_state > 1.01) || any(isnan(final_state))
            I_final = NaN;
        else
            % 使用最后10%时间点的平均值
            final_idx = max(1, round(0.9 * size(y,1))):size(y,1);
            I_final = mean(y(final_idx, 3) + y(final_idx, 4));
            % 确保在[0,1]范围内
            I_final = max(0, min(1, I_final));
        end
    catch
        I_final = NaN;
    end
end
