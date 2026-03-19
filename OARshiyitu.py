import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Ellipse, Circle
import matplotlib.gridspec as gridspec

# 设置样式
plt.rcParams['font.sans-serif'] = ['Arial', 'Helvetica', 'DejaVu Sans']
plt.rcParams['axes.unicode_minus'] = False

# 创建画布
fig = plt.figure(figsize=(16, 12), dpi=300)

# 使用GridSpec创建布局
gs = gridspec.GridSpec(2, 2, figure=fig, wspace=0.22, hspace=0.25)

ax1 = fig.add_subplot(gs[0, 0])
ax2 = fig.add_subplot(gs[0, 1])
ax3 = fig.add_subplot(gs[1, 0])
ax4 = fig.add_subplot(gs[1, 1])

# 颜色定义
colors = {
    'active': '#1f77b4',      # 蓝色 - 决策者
    'infected': '#e41a1c',    # 红色 - 感染
    'susceptible': '#4daf4a', # 绿色 - 易感
    'hyperedge': '#DDDDDD',   # 浅灰 - 超边
    'text': '#2c3e50',        # 深蓝 - 文本
    'targeted': '#3498db',    # 蓝色 - 靶向
    'random': '#e74c3c',      # 红色 - 随机
    'localized': '#2ca02c',   # 绿色 - 局部
    'explosive': '#d62728',   # 红色 - 爆炸
}

# ==================== Panel A: 风险感知决策 ====================
ax1.set_title('(A) Characteristic Scale Theorem', fontsize=12, fontweight='bold', pad=10)

# 绘制超边
hyperedge = Ellipse((0.5, 0.65), 0.75, 0.3, 
                   facecolor='none', 
                   edgecolor=colors['hyperedge'], 
                   linewidth=2,
                   alpha=0.25)
ax1.add_patch(hyperedge)

# 绘制节点
nodes_a = [
    (0.35, 0.65, 0.035, colors['active'], 'Decision\nMaker'),
    (0.5, 0.8, 0.03, colors['infected'], 'Infected'),
    (0.65, 0.65, 0.03, colors['infected'], 'Infected'),
    (0.5, 0.5, 0.03, colors['susceptible'], 'Susceptible'),
    (0.65, 0.5, 0.03, colors['susceptible'], 'Susceptible')
]

for x, y, r, color, label in nodes_a:
    circle = Circle((x, y), r, facecolor=color, edgecolor='black', 
                   linewidth=2, zorder=10, alpha=0.9)
    ax1.add_patch(circle)
    ax1.text(x, y-r-0.04, label, fontsize=8, ha='center', va='top')

# 观察计数
ax1.text(0.3, 0.72, 'Observes: $k$', fontsize=9, ha='center', fontweight='bold')

# 特征尺度定理
ax1.text(0.5, 0.35, 'Optimal threshold:', fontsize=10, ha='center')
#ax1.text(0.5, 0.31, r'$i^* = 2$', fontsize=10, ha='center', color=colors['infected'], fontweight='bold')
ax1.text(0.5, 0.27, r'$i^*=\arg\min_i D_{KL}$', fontsize=10, ha='center')

# 决策规则
ax1.text(0.3, 0.18, '$k \geq i^*$', fontsize=9, ha='center', fontweight='bold')
ax1.text(0.3, 0.14, 'Risky → Rewire', fontsize=9, ha='center', color=colors['explosive'])

ax1.text(0.7, 0.18, '$k < i^*$', fontsize=9, ha='center', fontweight='bold')
ax1.text(0.7, 0.14, 'Safe → Maintain', fontsize=9, ha='center', color=colors['localized'])

ax1.set_xlim(0, 1)
ax1.set_ylim(0, 1)
ax1.axis('off')

# ==================== Panel B: OAR机制 ====================
ax2.set_title('(B) OAR Mechanism', fontsize=12, fontweight='bold', pad=10)

# OAR公式
ax2.text(0.5, 0.95, r'$\gamma[\eta P(\text{risky}|i^*) + (1-\eta)\alpha]$', 
        fontsize=11, ha='center', fontweight='bold')

# 参数说明
params = [
    (r'$\gamma$: Max rewiring', 0.12, 0.88),
    (r'$\eta$: Info accuracy', 0.12, 0.84),
    (r'$P$: Risk prob.', 0.52, 0.88),
    (r'$\alpha$: Random avoid', 0.52, 0.84)
]

for text, x, y in params:
    ax2.text(x, y, text, fontsize=8)

# 左侧：靶向避免 (η→1)
ax2.text(0.3, 0.75, 'Targeted ($\eta \\rightarrow 1$)', 
        fontsize=10, ha='center', fontweight='bold', color=colors['targeted'])

# 绘制超边轮廓
hyperedge_left = Ellipse((0.3, 0.55), 0.45, 0.18, 
                        facecolor='none', 
                        edgecolor=colors['hyperedge'], 
                        linewidth=2,
                        alpha=0.2)
ax2.add_patch(hyperedge_left)

# 在超边中添加蓝色节点(决策者) + 2个红色感染 + 1个绿色易感
# 精简文字：将Active节点的标签精简为"Active"一个词
left_nodes = [
    (0.2, 0.55, 0.028, colors['active'], 'Active'),  # 精简标签
    (0.3, 0.63, 0.025, colors['infected'], 'Infected'),
    (0.4, 0.55, 0.025, colors['infected'], 'Infected'),
    (0.3, 0.47, 0.025, colors['susceptible'], 'Susceptible')
]

for x, y, r, color, label in left_nodes:
    circle = Circle((x, y), r, facecolor=color, edgecolor='black', 
                   linewidth=1.8, zorder=10)
    ax2.add_patch(circle)
    # 对Active节点使用更精简的标签位置
    if label == 'Active':
        ax2.text(x, y-r-0.02, label, fontsize=7, ha='center', va='top')  # 调整位置
    else:
        ax2.text(x, y-r-0.035, label, fontsize=7, ha='center', va='top')

# 连接蓝色节点和红色节点，然后在连接线上画叉号
# 蓝色节点到第一个红色节点
ax2.plot([0.2, 0.3], [0.55, 0.63], 'k--', linewidth=1.5, alpha=0.5)
ax2.text(0.25, 0.59, '×', color=colors['random'], fontsize=14, 
        ha='center', va='center', fontweight='bold')

# 蓝色节点到第二个红色节点
ax2.plot([0.2, 0.4], [0.55, 0.55], 'k--', linewidth=1.5, alpha=0.5)
ax2.text(0.3, 0.55, '×', color=colors['random'], fontsize=14,
        ha='center', va='center', fontweight='bold')

# 精简文字：简化连接和离开的文字
ax2.arrow(0.2, 0.55, 0.1, -0.05, head_width=0.02, head_length=0.02, 
          fc=colors['targeted'], ec=colors['targeted'], linewidth=2)
# 精简为单行文字
ax2.text(0.27, 0.43, 'Connect to safe', fontsize=6.5, ha='center', color=colors['targeted'])

# 离开箭头
ax2.arrow(0.2, 0.52, 0.0, -0.12, head_width=0.02, head_length=0.02, 
          fc=colors['targeted'], ec=colors['targeted'], linewidth=2)
# 精简为"Leave group"
ax2.text(0.15, 0.44, 'Leave\nrisky group', fontsize=6.5, ha='center', color=colors['targeted'])

# 安全超边
for i in range(3):
    circle = Circle((0.15 + i*0.2, 0.25), 0.025, 
                   facecolor=colors['susceptible'], edgecolor='black', linewidth=1.5)
    ax2.add_patch(circle)
ax2.text(0.15, 0.18, 'Join safe\ngroup', fontsize=6.5, ha='center', color=colors['targeted'])

# 右侧：随机避免 (η→0)
ax2.text(0.7, 0.75, 'Random ($\eta \\rightarrow 0$)', 
        fontsize=10, ha='center', fontweight='bold', color=colors['random'])

# 决策者中心节点
circle_center = Circle((0.7, 0.55), 0.028, facecolor=colors['active'], edgecolor='black', 
                      linewidth=1.8, zorder=10)
ax2.add_patch(circle_center)
ax2.text(0.7, 0.51, 'Active', fontsize=8, ha='center')

# 邻居节点：2个红色感染 + 2个绿色易感
right_neighbors = [
    (0.6, 0.62, 0.025, colors['infected'], 'Infected'),
    (0.8, 0.62, 0.025, colors['infected'], 'Infected'),
    (0.6, 0.48, 0.025, colors['susceptible'], 'Susceptible'),
    (0.8, 0.48, 0.025, colors['susceptible'], 'Susceptible')
]

for x, y, r, color, label in right_neighbors:
    circle = Circle((x, y), r, facecolor=color, edgecolor='black', linewidth=1.5, zorder=10)
    ax2.add_patch(circle)

# 连接和断开 - 从红色和绿色都断开
connections = [
    ((0.7, 0.55), (0.6, 0.62)),  # 感染邻居1
    ((0.7, 0.55), (0.8, 0.62)),  # 感染邻居2
    ((0.7, 0.55), (0.6, 0.48)),  # 易感邻居1
    ((0.7, 0.55), (0.8, 0.48)),  # 易感邻居2
]

# 随机断开一个感染和一个易感
disconnected = [0, 2]

for i, (start, end) in enumerate(connections):
    ax2.plot([start[0], end[0]], [start[1], end[1]], 'k-', linewidth=1.3, alpha=0.4)
    if i in disconnected:
        mid_x, mid_y = (start[0]+end[0])/2, (start[1]+end[1])/2
        ax2.text(mid_x, mid_y, '×', color=colors['random'], fontsize=14, 
                ha='center', va='center', fontweight='bold')

ax2.text(0.7, 0.35, 'Random\ndisconnect', fontsize=8, ha='center', color=colors['random'])

# 动机简化
ax2.text(0.5, 0.15, 'Motivated by:', fontsize=9, ha='center', fontweight='bold')
motives = ['Cognitive Dissonance', 'Social Identity', 'Information Overload']
for i, text in enumerate(motives):
    ax2.text(0.5, 0.11 - i*0.03, text, fontsize=8, ha='center')

ax2.set_xlim(0, 1)
ax2.set_ylim(0, 1)
ax2.axis('off')

# ==================== Panel C: 网络演化 ====================
ax3.set_title('(C) Network Evolution', fontsize=12, fontweight='bold', pad=10)

# 初始网络标题
ax3.text(0.5, 0.92, 'Initial: Mixed Network', fontsize=10, ha='center', fontweight='bold')

# 绘制初始网络节点
np.random.seed(42)
for i in range(20):
    x = np.random.uniform(0.1, 0.9)
    y = np.random.uniform(0.65, 0.85)
    color = colors['infected'] if np.random.random() < 0.3 else colors['susceptible']
    circle = Circle((x, y), 0.013, facecolor=color, edgecolor='black', alpha=0.9)
    ax3.add_patch(circle)

# 添加一些连接线（保持连线不变）
for i in range(25):
    x1 = np.random.uniform(0.1, 0.9)
    y1 = np.random.uniform(0.65, 0.85)
    x2 = np.random.uniform(0.1, 0.9)
    y2 = np.random.uniform(0.65, 0.85)
    if np.sqrt((x1-x2)**2 + (y1-y2)**2) < 0.25:
        ax3.plot([x1, x2], [y1, y2], 'k-', alpha=0.15, linewidth=0.8)

# 演化箭头 - 从上到下
ax3.arrow(0.493, 0.6, 0.0, -0.08, head_width=0.04, head_length=0.02, 
          fc=colors['text'], ec=colors['text'], linewidth=1)
ax3.text(0.5, 0.56, 'Driven by OAR', fontsize=9, ha='center', fontweight='bold')

# 演化后网络标题
ax3.text(0.5, 0.45, 'Final: Fragmented', fontsize=10, ha='center', fontweight='bold')

# 左集群：低感染率 (绿色为主)
for i in range(15):
    angle = np.random.uniform(0, 2*np.pi)
    radius = np.random.uniform(0, 0.11)
    x = 0.3 + radius * np.cos(angle)
    y = 0.25 + radius * np.sin(angle)
    color = colors['infected'] if np.random.random() < 0.2 else colors['susceptible']
    circle = Circle((x, y), 0.011, facecolor=color, edgecolor='black', alpha=0.9)
    ax3.add_patch(circle)

# 右集群：高感染率 (红色为主)
for i in range(15):
    angle = np.random.uniform(0, 2*np.pi)
    radius = np.random.uniform(0, 0.11)
    x = 0.7 + radius * np.cos(angle)
    y = 0.25 + radius * np.sin(angle)
    color = colors['infected'] if np.random.random() < 0.8 else colors['susceptible']
    circle = Circle((x, y), 0.011, facecolor=color, edgecolor='black', alpha=0.9)
    ax3.add_patch(circle)

# 集群内部连接线（保持连线不变）
for i in range(10):
    # 左集群内部连接
    x1 = 0.3 + np.random.uniform(-0.1, 0.1)
    y1 = 0.25 + np.random.uniform(-0.1, 0.1)
    x2 = 0.3 + np.random.uniform(-0.1, 0.1)
    y2 = 0.25 + np.random.uniform(-0.1, 0.1)
    ax3.plot([x1, x2], [y1, y2], 'k-', alpha=0.15, linewidth=0.8)
    
    # 右集群内部连接
    x1 = 0.7 + np.random.uniform(-0.1, 0.1)
    y1 = 0.25 + np.random.uniform(-0.1, 0.1)
    x2 = 0.7 + np.random.uniform(-0.1, 0.1)
    y2 = 0.25 + np.random.uniform(-0.1, 0.1)
    ax3.plot([x1, x2], [y1, y2], 'k-', alpha=0.15, linewidth=0.8)

# 标注
ax3.text(0.3, 0.05, 'Localized', fontsize=10, ha='center', color=colors['localized'], fontweight='bold')
ax3.text(0.3, 0.01, '', fontsize=8, ha='center')

ax3.text(0.7, 0.05, 'Explosive', fontsize=10, ha='center', color=colors['explosive'], fontweight='bold')
ax3.text(0.7, 0.01, '', fontsize=8, ha='center')

ax3.set_xlim(0, 1)
ax3.set_ylim(0, 1)
ax3.axis('off')

# ==================== Panel D: 双峰分布 ====================
ax4.set_title('(D) Bimodal Distribution', fontsize=12, fontweight='bold', pad=10)

# 生成数据
x = np.linspace(0, 1, 1000)
pdf1 = 0.7 * np.exp(-(x-0.25)**2 / (2*0.08**2))
pdf2 = 0.3 * np.exp(-(x-0.75)**2 / (2*0.05**2))
pdf = pdf1 + pdf2
pdf = pdf / np.max(pdf) * 0.9

# 绘制
ax4.plot(x, pdf, 'k-', linewidth=2.8, label='Theory', zorder=5)
ax4.fill_between(x, 0, pdf, where=(x<0.5), color=colors['localized'], alpha=0.4, 
                label='Localized', zorder=1)
ax4.fill_between(x, 0, pdf, where=(x>=0.5), color=colors['explosive'], alpha=0.4, 
                label='Explosive', zorder=2)

# 临界线

# 标注 - 根据上传图片内容调整
ax4.text(0.23, 0.85, 'Localized', fontsize=9, ha='center', 
        color=colors['localized'], fontweight='bold')


ax4.text(0.77, 0.85, 'Explosive', fontsize=9, ha='center', 
        color=colors['explosive'], fontweight='bold')


# 统计信息 - 根据上传图片内容调整


ax4.set_xlabel('Infection Density (I)', fontsize=11)
ax4.set_ylabel('Probability', fontsize=11)
ax4.legend(loc='upper right', fontsize=8, framealpha=0.9)
ax4.grid(True, alpha=0.2, linestyle='--', linewidth=0.7)
ax4.set_xlim(0, 1)
ax4.set_ylim(0, 1.05)

# 调整布局
plt.tight_layout()

# 保存图像
plt.savefig('OAR_mechanism_final_optimized.png', dpi=300, bbox_inches='tight', 
           facecolor='white', edgecolor='none')
plt.savefig('OAR_mechanism_final_optimized.pdf', bbox_inches='tight', facecolor='white')
plt.savefig('OAR_mechanism_final_optimized.eps', bbox_inches='tight', facecolor='white')
print("最终优化版图像已保存:")
print("1. OAR_mechanism_final_optimized.png")
print("2. OAR_mechanism_final_optimized.pdf")
print("3. OAR_mechanism_final_optimized.eps")
plt.show()