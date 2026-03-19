.
├── README.md
├── figure1/                      # Figure 1 – Conceptual diagram
│   └── OARshiyitu.py             (Python)
├── figure2/                      # Figure 2 – Characteristic Scale Theorem
│   └── chara_scale_theorem123.m  (MATLAB)
├── figure3/                      # Figure 3 – Explosive transition
│   └── Delta_phase.m             (MATLAB)
├── figure4/                      # Figure 4 – Bimodal distribution
│   ├── H0L6bak.m                 # main script
│   ├── game_equations.m          # ODE system
│   ├── generate_initial_conditions.m
│   ├── get_initial_final.m
│   └── run_single_simulation.m
├── figure5/                      # Figure 5 – Lyapunov analysis
│   ├── main.m                    # main script
│   ├── compute_lyapunov.m        # Wolf algorithm
│   ├── compute_P_risky.m         # risk probability
│   └── ode_social_contagion.m    # ODE system
└── figure6/                      # Figure 6 – Twitter hashtag validation
    ├── KStest.m                  # KS test & plots
    ├── KStestLog.m               # log‑scale version
    └── Memetrackers.m            # optional Memetracker analysis



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Dependencies
Python 3.7+ (Figure 1)
pip install matplotlib numpy

MATLAB R2019b or newer (Figures 2–6)
Required toolboxes:

Statistics and Machine Learning Toolbox

Parallel Computing Toolbox (optional, for faster parameter scans in Figure 5)

Running the Code
Figure 1 – OAR Mechanism
bash
cd figure1
python OARshiyitu.py
Outputs: OAR_mechanism_final_optimized.png, .pdf, .eps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Figure 2 – Characteristic Scale Theorem
matlab
cd figure2
chara_scale_theorem123
Outputs: figure window, optimal_threshold_results.mat, simulation_parameters.mat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Figure 3 – Explosive Transition
matlab
cd figure3
Delta_phase
Outputs: figure, console prints critical βΔ^c and R₀.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Figure 4 – Bimodal Distribution
matlab
cd figure4
H0L6bak
Outputs: six‑panel figure, console prints bimodality coefficient and KS test results.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Figure 5 – Lyapunov Analysis
matlab
cd figure5
main
Outputs: three‑panel figure, lyapunov_analysis_report.txt, lyapunov_analysis_results.mat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Figure 6 – Twitter Hashtag Validation
matlab
cd figure6
KStest           # or KStestLog for log‑scale plots
Outputs: figure, twitter_analysis_top25_bottom25.mat, CSV files with group data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

If you use this code, please cite the original paper:


LI Zhenpeng, YAN Zhihua, TANG Xijin. From Rational Inattention to Explosive Bimodality:
Co-evolutionary Contagion on Adaptive Hypergraphs. Royal Society Open Science, 2025.
For the Twitter dataset, acknowledge:


J. Leskovec, L. Backstrom, J. Kleinberg. Meme-tracking and the Dynamics of the News Cycle.
ACM SIGKDD International Conference on Knowledge Discovery and Data Mining (KDD), 2009.
Reproducibility
All random seeds are set within the scripts to ensure reproducible results. Data download scripts include error handling and fallback options.

