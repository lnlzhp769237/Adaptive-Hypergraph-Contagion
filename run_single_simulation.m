function [t, I_total] = run_single_simulation(sim_idx, mu, beta1, beta2, beta_delta, ...
                                             k_avg, k_delta_avg, n_avg, k_c, ...
                                             gamma, eta, i_star, alpha, tspan)
    % 设置可重复随机种子
    rng(sim_idx);
    
    % 生成初始条件
    y0 = generate_initial_conditions();
    
    % 运行模拟
    [t, y] = ode45(@(t,y) game_equations(t, y, mu, beta1, beta2, beta_delta, ...
                                        k_avg, k_delta_avg, n_avg, k_c, ...
                                        gamma, eta, i_star, alpha), ...
                  tspan, y0);
    
    % 计算总感染密度
    I_total = y(:, 3) + y(:, 4);
end