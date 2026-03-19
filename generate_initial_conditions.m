function y0 = generate_initial_conditions()
    % 生成并验证初始条件
    max_attempts = 10;
    
    for attempt = 1:max_attempts
        % 生成初始感染密度
        if rand() < 0.5
            % 低感染初始条件
            I_A0 = rand() * 0.45;  % 最大0.45
            I_P0 = rand() * 0.15;  % 最大0.15
        else
            % 高感染初始条件  
            I_A0 = 0.25 + rand() * 0.5;   % 范围[0.25, 0.75]
            I_P0 = 0.15 + rand() * 0.35;  % 范围[0.15, 0.50]
        end
        
        % 确保感染密度总和不超过0.95（留空间给易感者）
        total_inf = I_A0 + I_P0;
        if total_inf > 0.95
            scaling = 0.95 / total_inf;
            I_A0 = I_A0 * scaling;
            I_P0 = I_P0 * scaling;
            total_inf = 0.95;
        end
        
        % 生成易感者密度
        remaining = 1 - total_inf;
        S_A0 = remaining * rand();
        S_P0 = remaining - S_A0;
        
        % 构造状态向量并归一化
        y0 = [max(0, S_A0); max(0, S_P0); max(0, I_A0); max(0, I_P0)];
        y0 = y0 / sum(y0);
        
        % 严格验证初始条件
        if all(y0 >= 0) && abs(sum(y0) - 1) < 1e-10
            I_initial = y0(3) + y0(4);
            
            % 检查初始感染密度是否在合理范围内
            if I_initial >= 0 && I_initial <= 1
                return;
            end
        end
    end
    
    % 如果多次尝试失败，使用保守值
    warning('Failed to generate valid initial condition after %d attempts', max_attempts);
    y0 = [0.6; 0.2; 0.15; 0.05];  % 保守初始条件
end
