# Adaptive-Hypergraph-Contagion
Reproduction code for the paper "From Rational Inattention to Explosive Bimodality
.
├── README.md
├── figure1/                      # Figure 1 – Conceptual diagram
│   └── OARshiyitu.py             (Python)
├── figure2/                      # Figure 2 – Characteristic Scale Theorem
│   └── chara_scale_theorem123.m  (MATLAB)
├── figure3/                      # Figure 3 – Explosive transition
│   └── Delta_phase.m             (MATLAB)
├── figure4/                      # Figure 4 – Bimodal distribution
│   ├── H0L6bak.m                 main script
│   ├── game_equations.m          ODE system
│   ├── generate_initial_conditions.m
│   ├── get_initial_final.m
│   └── run_single_simulation.m
├── figure5/                      # Figure 5 – Lyapunov analysis
│   ├── main.m                    main script
│   ├── compute_lyapunov.m        Wolf algorithm
│   ├── compute_P_risky.m         risk probability
│   └── ode_social_contagion.m    ODE system
└── figure6/                      # Figure 6 – Twitter hashtag validation
    ├── KStest.m                  KS test & plots
    ├── KStestLog.m                alternative log‑scale plot
    └── Memetrackers.m            (optional) Memetracker data analysis


 Dependencies
Python (Figure 1)
Python 3.7+

matplotlib, numpy

Install with:

bash
pip install matplotlib numpy
MATLAB (Figures 2–6)
MATLAB R2019b or newer

Statistics and Machine Learning Toolbox (for kstest2, skewness, kurtosis, quantile, nchoosek, binocdf)

Parallel Computing Toolbox (optional, for faster parameter scans in Figure 5)

No additional toolboxes are required for the core ODE solvers.

📊 Figure 1 – Optimal Adaptive Rewiring (OAR) Mechanism
File: figure1/OARshiyitu.py

This Python script generates the conceptual diagram illustrating the OAR mechanism, the Characteristic Scale Theorem, network evolution, and the resulting bimodal distribution.

Run:

bash
cd figure1
python OARshiyitu.py
Outputs: OAR_mechanism_final_optimized.png, .pdf, .eps

Parameters:
The colours and layout are hard‑coded to match the paper’s style. No user‑adjustable parameters.

📐 Figure 2 – Characteristic Scale Theorem: Optimal Risk‑Perception Threshold
File: figure2/chara_scale_theorem123.m

This MATLAB script downloads the Stanford SNAP Twitter hashtag dataset, computes the global risk distribution 
P
global
P 
global
​
  from the normalized peak mention frequencies, and calculates the KL‑divergence 
D
KL
(
P
global
∥
P
local
(
i
)
)
D 
KL
​
 (P 
global
​
 ∥P 
local
(i)
​
 ) for candidate thresholds 
i
i. The threshold that minimizes the KL‑divergence is identified as the optimal risk‑perception threshold 
i
∗
=
2
i 
∗
 =2. The script also computes the risk probability function 
P
(
risky
∣
i
∗
)
P(risky∣i 
∗
 ) and provides parameters for subsequent simulations.

Run:

matlab
cd figure2
chara_scale_theorem123
Key adjustable parameters inside the script:

num_hashtags = 1000 – number of hashtags to analyze

avg_hyperedge_size = 5 – average hyperedge size 
⟨
n
⟩
⟨n⟩

max_threshold = 10 – maximum candidate threshold to test

Outputs:

A figure with six subplots showing the global/local distributions, KL‑divergence vs 
i
i, peak frequency histograms, and the risk probability function.

optimal_threshold_results.mat – contains all analysis results, including the optimal threshold 
i
∗
i 
∗
 .

simulation_parameters.mat – parameters (e.g., 
R
0
R 
0
​
 , 
β
Δ
c
β 
Δ
c
​
 ) for use in Figures 3–5.

Console output:
Prints the optimal threshold, KL‑divergence values, bimodality coefficient, and critical infection density.

📈 Figure 3 – Explosive Transition as a First‑Order Phase Transition
File: figure3/Delta_phase.m

This MATLAB script computes the steady‑state infection density 
I
I as a function of the higher‑order reinforcement strength 
β
Δ
β 
Δ
​
  using a self‑consistent equation. It identifies the critical point 
β
Δ
c
β 
Δ
c
​
  and produces a plot with the discontinuous jump.

Run:

matlab
cd figure3
Delta_phase
Parameters (inside script):

mu = 0.5 – recovery rate

beta1 = 0.15 – active node transmission

beta2 = 0.05 – passive node transmission

p_A = 0.6 – active node proportion

network parameters: k_avg = 4, k_delta_avg = 4, n_avg = 4, k_c = 2

Output:
A figure showing 
I
I vs 
β
Δ
β 
Δ
​
  with the critical point marked. The console prints the critical 
β
Δ
c
β 
Δ
c
​
  and 
R
0
R 
0
​
 .

📉 Figure 4 – Bimodal Distribution of Contagion Outcomes
Files: figure4/ (multiple .m files)

The main script H0L6bak.m runs 100 stochastic realisations of the GAME (Generalized Approximate Master Equation) system for a fixed parameter set near the critical point. It produces six subplots (a–f) exactly as in the paper.

Run:

matlab
cd figure4
H0L6bak
Key adjustable parameters inside H0L6bak.m:

beta_delta = 0.474 – near‑critical reinforcement

eta_bimodal = 0.75 – information accuracy

i_star_bimodal = 2 – optimal risk threshold

gamma = 0.35 – rewiring rate

num_simulations = 100 – number of stochastic runs

Helper functions:

game_equations.m – defines the ODE system (Eqs. 2.10–2.13 in the paper)

generate_initial_conditions.m – creates a random initial state (
S
A
,
S
P
,
I
A
,
I
P
S 
A
​
 ,S 
P
​
 ,I 
A
​
 ,I 
P
​
 )

run_single_simulation.m – integrates the ODE for one realisation

get_initial_final.m – extracts initial and final infection densities (used for subplot f)

Output:
A figure with six panels (a–f) saved as a MATLAB figure window. Statistical summaries are printed in the console (bimodality coefficient, KS test results).

🔁 Figure 5 – Chaos Dynamics and Lyapunov Analysis
Files: figure5/ (multiple .m files)

The main script main.m performs three experiments:

Scan of 
β
Δ
β 
Δ
​
  vs 
λ
max
⁡
λ 
max
​
  (Fig. 5a)

Two‑parameter scan 
(
β
Δ
,
γ
)
(β 
Δ
​
 ,γ) (Fig. 5b)

Scan of 
η
η vs 
λ
max
⁡
λ 
max
​
  (Fig. 5c)

Run:

matlab
cd figure5
main
Core functions:

compute_lyapunov.m – implements the Wolf algorithm to estimate the maximum Lyapunov exponent from the ODE system.

ode_social_contagion.m – ODE right‑hand side (same as game_equations.m but with a parameter structure).

compute_P_risky.m – calculates 
P
(
risky
∣
i
∗
)
P(risky∣i 
∗
 ) using the binomial formula.

Parameters:
All parameters are defined inside main.m. Default values reproduce the paper’s critical regime (Table 4). The script uses parallel computing if the Parallel Computing Toolbox is available; otherwise it falls back to serial execution.

Output:
A figure with three subplots (a–c) and a text report (lyapunov_analysis_report.txt). All results are saved in lyapunov_analysis_results.mat.

📊 Figure 6 – Twitter Hashtag Validation
Files: figure6/ (three MATLAB scripts)

KStest.m
Downloads the Stanford SNAP Twitter hashtag dataset, extracts peak hourly mention volumes, computes bimodality statistics, and performs a Kolmogorov‑Smirnov test between the top 25% and bottom 25% of hashtags. Produces three subplots (CDF, boxplot, histogram).

Run:

matlab
cd figure6
KStest
KStestLog.m
An alternative version that plots the same data with logarithmic axes and includes a more detailed panel (c) matching the paper’s Figure 6(c).

Memetrackers.m (optional)
Downloads the Memetracker dataset and analyses peak volumes. This script is not required for the paper’s main results but is included for completeness.

Outputs:

Figures with the three panels (a–c) as in the paper.

Statistical summary in the console and saved in twitter_analysis_top25_bottom25.mat.

CSV files with the grouped data.

📌 How to Cite
If you use this code, please cite the original paper:

text
LI Zhenpeng, YAN Zhihua, TANG Xijin. From Rational Inattention to Explosive Bimodality:
Co-evolutionary Contagion on Adaptive Hypergraphs. Royal Society Open Science, 2025.
For the Twitter dataset, acknowledge:

text
J. Leskovec, L. Backstrom, J. Kleinberg. Meme-tracking and the Dynamics of the News Cycle.
ACM SIGKDD International Conference on Knowledge Discovery and Data Mining (KDD), 2009.
🧪 Reproducibility
All random number generators are seeded appropriately (see generate_initial_conditions.m and the simulation loops). The MATLAB scripts use rng(sim_idx) to make every realisation reproducible. Data download scripts include error handling and fallback options.
