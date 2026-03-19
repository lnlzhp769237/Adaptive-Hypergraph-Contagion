function P = compute_P_risky(I, i_star, avg_n)
% 计算风险概率 P(risky|i*)
% 输入:
%   I: 总感染密度 (I_A + I_P)
%   i_star: 最优风险阈值
%   avg_n: 平均超边大小
% 输出:
%   P: 风险概率

    % 使用二项分布：P(risky|i*) = Σ_{k=i*}^{avg_n} C(avg_n, k) * I^k * (1-I)^(avg_n-k)
    P = 0;
    
    % 处理边界情况
    if I <= 0
        P = 0;
        return;
    elseif I >= 1
        P = 1;
        return;
    end
    
    % 计算二项概率和
    for k = i_star:avg_n
        P = P + nchoosek(avg_n, k) * I^k * (1-I)^(avg_n-k);
    end
    
    % 确保概率在[0,1]范围内
    P = max(0, min(1, P));
end