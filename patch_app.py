import os

app_file = r'C:\Users\yusuf\.gemini\antigravity\scratch\Fluxion\app\FluxionApp.m'
with open(app_file, 'r', encoding='utf-8') as f:
    app_code = f.read()

# 1. Update Scenario Items
old_scen = "'Items', {'Full System Test (All)', 'Inrush Analysis', 'Internal Fault', 'External Fault (Through-Fault)', 'Thermal Loading', 'Harmonic Load', 'Unbalanced Load', 'ML Condition Diagnosis', 'Parameter Estimation (AI)'});"
new_scen = "'Items', {'Full System Test (All)', 'Inrush Analysis', 'Internal Fault', 'External Fault (Through-Fault)', 'Thermal Loading', 'Harmonic Load', 'Unbalanced Load', 'ML Condition Diagnosis', 'Parameter Estimation (AI)', 'DGA Chemical Diagnosis'});"
app_code = app_code.replace(old_scen, new_scen)

# 2. Update Plot Items
old_plot = "'Items', {'Monte Carlo (Inrush)', 'Thermal (Steady-State)', 'Protection Relay (Differential)', 'Harmonic Waveform', 'Unbalanced Load Currents', 'External Fault Waveform'},"
new_plot = "'Items', {'Monte Carlo (Inrush)', 'Thermal (Steady-State)', 'Protection Relay (Differential)', 'Harmonic Waveform', 'Unbalanced Load Currents', 'External Fault Waveform', 'Duval Triangle (DGA)'},"
app_code = app_code.replace(old_plot, new_plot)

# 3. Add the DGA execution logic in RunSimulation around line 216
logic_str = """
                if strcmp(scenario, 'Full System Test (All)') || strcmp(scenario, 'DGA Chemical Diagnosis')
                    app.LogArea.Value = [app.LogArea.Value; {'Running DGA Chemical Diagnosis (Duval Triangle 1)...'}];
                    drawnow;
                    
                    % Read from config which is synced with the UI table
                    ch4 = app.txConfig.dga_CH4;
                    c2h4 = app.txConfig.dga_C2H4;
                    c2h2 = app.txConfig.dga_C2H2;
                    
                    [zone, desc, pct] = tx.dgaModel.diagnose(ch4, c2h4, c2h2);
                    
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Gas Proportions: CH4=%%%.1f, C2H4=%%%.1f, C2H2=%%%.1f', pct(1), pct(2), pct(3))}];
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Duval Zone: %s -> %s', zone, desc)}];
                    app.PlotSelector.Value = 'Duval Triangle (DGA)';
                end
                
                app.LogArea.Value = [app.LogArea.Value; {'Simulation completed!'}];
"""
app_code = app_code.replace("app.LogArea.Value = [app.LogArea.Value; {'Simulation completed!'}];", logic_str)

# 4. Add the DGA plot logic in updatePlot around line 250
plot_logic_str = """
                case 'Duval Triangle (DGA)'
                    if isfield(app.txConfig, 'dga_CH4')
                        tx.dgaModel.plotDuvalTriangle(app.UIAxes, app.txConfig.dga_CH4, app.txConfig.dga_C2H4, app.txConfig.dga_C2H2);
                    else
                        title(app.UIAxes, 'DGA parameters not found.');
                    end
                    
                case 'Harmonic Waveform'
"""
app_code = app_code.replace("case 'Harmonic Waveform'", plot_logic_str)

with open(app_file, 'w', encoding='utf-8') as f:
    f.write(app_code)

print('updated app')
