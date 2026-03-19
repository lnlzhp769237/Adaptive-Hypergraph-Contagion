function dydt = game_equations(t, y, mu, beta1, beta2, beta_delta, ...
                              k_avg, k_delta_avg, n_avg, k_c, ...
                              gamma, eta, i_star, alpha)
    
    % 解包状态变量
    S_A = y(1);  % 主动易感者
    S_P = y(2);  % 被动易感者
    I_A = y(3);  % 主动感染者
    I_P = y(4);  % 被动感染者
    
    % 总感染密度
    I = I_A + I_P;
    
    % 避免除以零
    if I < 1e-10
        I = 1e-10;
    end
    
    % 计算危险概率P(risky|i*)
    P_risky = 0;
    for k = i_star:n_avg
        binomial_coeff = nchoosek(n_avg, k);
        P_risky = P_risky + binomial_coeff * (I^k) * ((1-I)^(n_avg-k));
    end
    
    % 有效接触率调制函数
    Lambda_eff_A = 1 - gamma * (eta * P_risky + (1-eta) * alpha);
    Lambda_eff_A = max(0, min(1, Lambda_eff_A));  % 确保在[0,1]范围内
    
    % 定义非线性强化项
    if I >= k_c/n_avg
        group_term = beta_delta * I^(k_c-1);
    else
        group_term = 0;
    end
    
    % 微分方程
    dS_A_dt = mu * I_A - Lambda_eff_A * (beta1 * S_A * I * k_avg + beta_delta * S_A * group_term * k_delta_avg);
    dS_P_dt = mu * I_P - (beta2 * S_P * I * k_avg + beta_delta * S_P * group_term * k_delta_avg);
    dI_A_dt = Lambda_eff_A * (beta1 * S_A * I * k_avg + beta_delta * S_A * group_term * k_delta_avg) - mu * I_A;
    dI_P_dt = (beta2 * S_P * I * k_avg + beta_delta * S_P * group_term * k_delta_avg) - mu * I_P;
    
    % 输出
    dydt = [dS_A_dt; dS_P_dt; dI_A_dt; dI_P_dt];
end
