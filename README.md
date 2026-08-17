# Fluxion: Power Transformer Digital Twin 

[![MATLAB](https://img.shields.io/badge/MATLAB-R2021a%2B-blue.svg)](https://www.mathworks.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Fluxion** is a comprehensive, open-source MATLAB-based Digital Twin for power transformers. It bridges the gap between nonlinear electromagnetic physics, thermal dynamics, protective relaying algorithms, and artificial intelligence.

##  Table of Contents
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Getting Started](#-getting-started)
- [Parameter Configuration](#-parameter-configuration)
- [Scenarios & Simulations](#-scenarios--simulations)
- [Project Structure](#-project-structure)
- [License](#-license)

##  Features
*   **Nonlinear Core Physics & Inrush**: Simulates realistic B-H hysteresis loops and inrush currents using a Monte Carlo approach to find the worst-case switching angles and residual fluxes.
*   **Thermal Digital Twin**: IEC 60076-7 compliant dynamic Top-Oil and Hot-Spot temperature modeling.
*   **Differential Protection (ANSI 87T)**: Dual-slope restraint characteristic mapping with 2nd-harmonic blocking considerations.
*   **AI/ML Condition Diagnosis**: Extracts signal features (RMS, THD, Sequence components) and classifies the transformer's state (Normal, Inrush, Internal Fault, Overexcitation) with confidence scores.
*   **Parameter Estimation (Reverse Engineering)**: Solves an inverse mathematical problem using `fminsearch` to estimate true copper (Pcu) and core (P0) losses from synthetic field sensor data.
*   **Power Quality & Fault Analysis**: Simulates external through-faults, highly unbalanced loads, and 6-pulse rectifier harmonic loads (25% THD).

##  Prerequisites
- MATLAB R2021a or newer.
- Required Toolboxes:
    - Optimization Toolbox (for `fminsearch`)
    - Statistics and Machine Learning Toolbox (optional but recommended)

##  Getting Started
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/Fluxion.git
   cd Fluxion
   ```
2. Open MATLAB and run the application:
   ```matlab
   % Add subfolders to the path and launch the GUI
   addpath(genpath(pwd));
   app = FluxionApp;
   ```

##  Parameter Configuration
The GUI features a **Nameplate Table** where you can dynamically edit the transformer's physical properties.
*   **Nominal Power (MVA)**: Base apparent power.
*   **Primary / Secondary Voltage (kV)**: Line-to-line voltages.
*   **Short Circuit Voltage (uk %)**: Leakage impedance indicator.
*   **No-Load Current (I0 %)** & **Losses (kW)**: Defines core saturation and hysteresis limits.
*   **Cooling Type**: e.g., ONAN, ONAF (influences thermal time constants).
*   **Load Factor (K)**: Per-unit load (e.g., `1.0` = 100% nominal load, `1.5` = 150% overload). Adjust this to see real-time impacts on thermal heating and load currents!

##  Scenarios & Simulations
Select a test from the **Scenario Selection** dropdown in the GUI:
1.  **Full System Test (All)**: Runs all analytical scenarios sequentially and stores the outputs in memory.
2.  **Inrush Analysis**: Executes a 30-sample Monte Carlo simulation to plot worst-case inrush current and harmonic distribution.
3.  **Thermal Loading**: Integrates IEC 60076-7 differential equations over a 500-minute window to find steady-state Top-Oil and Hot-Spot temperatures.
4.  **Internal Fault**: Simulates a turn-to-turn winding short circuit.
5.  **External Fault**: Simulates a severe 3-phase through-fault 5 km away to test restraint algorithms.
6.  **Unbalanced Load**: Simulates a heavy asymmetrical load (Phase A = 140%, B & C = 80%) to calculate zero and negative sequence currents.
7.  **Harmonic Load**: Applies a typical 6-pulse non-linear load and visualizes the resulting distorted waveform.
8.  **Parameter Estimation / ML Diagnosis**: Evaluates the AI modules against synthetic data.

To export high-resolution PNG plots, you can also run:
```matlab
results = runProject;
txConfig = defaultTransformerConfig();
generateAllPlots(txConfig, results);
```
This will generate 16 detailed engineering plots in the `results/` folder.

##  Project Structure
```text
Fluxion/
├── app/               # GUI application (FluxionApp.m)
├── config/            # Default transformer & protection configurations
├── data/              # B-H curve datasets
├── reports/           # Auto-generated markdown technical reports
├── results/           # Exported PNG plots
├── scenarios/         # Individual scenario scripts (Harmonics, Faults, etc.)
├── src/+tx/           # Core physics, thermal, and ML algorithms (MATLAB Package)
└── tests/             # Automated unit tests
```

##  License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
