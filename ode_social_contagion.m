function dxdt = ode_social_contagion(t, x, params)
% 自适应超图传染模型的ODE系统
% 状态变量: x = [S_A; S_P; I_A; I_P]
% 参数: params 结构体包含所有模型参数

    % 提取状态变量
    S_A = x(1);
    S_P = x(2);
    I_A = x(3);
    I_P = x(4);
    
    % 提取参数
    beta1 = params.beta1;
    beta2 = params.beta2;
    betaDelta = params.betaDelta;
    gamma = params.gamma;
    eta = params.eta;
    alpha = params.alpha;
    pA = params.pA;
    mu = params.mu;
    avg_k = params.avg_k;
    avg_kDelta = params.avg_kDelta;
    avg_n = params.avg_n;
    k_c = params.k_c;
    i_star = params.i_star;
    
    % 总感染密度
    I_total = I_A + I_P;
    
    % 计算风险概率 P(risky|i*)
    P_risky = compute_P_risky(I_total, i_star, avg_n);
    
    % 计算有效接触率 Λ_eff(A,t) (公式8)
    Lambda_eff_A = 1 - gamma * (eta * P_risky + (1-eta) * alpha);
    
    % 确保有效接触率在合理范围内 [0, 1]
    Lambda_eff_A = max(0, min(1, Lambda_eff_A));
    
    % 计算共同项
    term_pair = I_total * avg_k;              % I?k?
    term_group = I_total^k_c * avg_kDelta;    % I^{k_c}?kΔ?
    
    % 方程(10): dS_A/dt = μI_A - Λ_eff(A,t)[β1 S_A term_pair + βΔ S_A term_group]
    dS_A = mu * I_A - Lambda_eff_A * (beta1 * S_A * term_pair + betaDelta * S_A * term_group);
    
    % 方程(11): dS_P/dt = μI_P - [β2 S_P term_pair + βΔ S_P term_group]
    dS_P = mu * I_P - (beta2 * S_P * term_pair + betaDelta * S_P * term_group);
    
    % 方程(12): dI_A/dt = Λ_eff(A,t)[β1 S_A term_pair + βΔ S_A term_group] - μI_A
    dI_A = Lambda_eff_A * (beta1 * S_A * term_pair + betaDelta * S_A * term_group) - mu * I_A;
    
    % 方程(13): dI_P/dt = [β2 S_P term_pair + βΔ S_P term_group] - μI_P
    dI_P = (beta2 * S_P * term_pair + betaDelta * S_P * term_group) - mu * I_P;
    
    % 返回导数向量
    dxdt = [dS_A; dS_P; dI_A; dI_P];
end