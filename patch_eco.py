import os

app_file = r'C:\Users\yusuf\.gemini\antigravity\scratch\Fluxion\config\defaultTransformerConfig.m'
with open(app_file, 'r', encoding='utf-8') as f:
    code = f.read()

new_str = """% DGA (Dissolved Gas Analysis) defaults [ppm]
txConfig.dga_CH4 = 120;
txConfig.dga_C2H4 = 30;
txConfig.dga_C2H2 = 15;

% Economic Analysis Parameters
txConfig.electricity_price = 0.12; % Electricity price [$/kWh]
txConfig.fan_power = 5.0;          % Cooling fan power consumption [kW]
"""
code = code.replace("""% DGA (Dissolved Gas Analysis) defaults [ppm]
txConfig.dga_CH4 = 120;
txConfig.dga_C2H4 = 30;
txConfig.dga_C2H2 = 15;
""", new_str)
with open(app_file, 'w', encoding='utf-8') as f:
    f.write(code)

flux_app = r'C:\Users\yusuf\.gemini\antigravity\scratch\Fluxion\app\FluxionApp.m'
with open(flux_app, 'r', encoding='utf-8') as f:
    app_code = f.read()

old_scen = "'Items', {'Full System Test (All)', 'Inrush Analysis', 'Internal Fault', 'External Fault (Through-Fault)', 'Thermal Loading', 'Harmonic Load', 'Unbalanced Load', 'ML Condition Diagnosis', 'Parameter Estimation (AI)', 'DGA Chemical Diagnosis'});"
new_scen = "'Items', {'Full System Test (All)', 'Inrush Analysis', 'Internal Fault', 'External Fault (Through-Fault)', 'Thermal Loading', 'Harmonic Load', 'Unbalanced Load', 'ML Condition Diagnosis', 'Parameter Estimation (AI)', 'DGA Chemical Diagnosis', 'Cost & Efficiency Analysis'});"
app_code = app_code.replace(old_scen, new_scen)

old_plot = "'Items', {'Monte Carlo (Inrush)', 'Thermal (Steady-State)', 'Protection Relay (Differential)', 'Harmonic Waveform', 'Unbalanced Load Currents', 'External Fault Waveform', 'Duval Triangle (DGA)'},"
new_plot = "'Items', {'Monte Carlo (Inrush)', 'Thermal (Steady-State)', 'Protection Relay (Differential)', 'Harmonic Waveform', 'Unbalanced Load Currents', 'External Fault Waveform', 'Duval Triangle (DGA)', 'Economic Cost Analysis'},"
app_code = app_code.replace(old_plot, new_plot)

eco_logic = """
                if strcmp(scenario, 'Full System Test (All)') || strcmp(scenario, 'Cost & Efficiency Analysis')
                    app.LogArea.Value = [app.LogArea.Value; {'Running Economic & Cost Analysis...'}];
                    drawnow;
                    
                    price = app.txConfig.electricity_price;
                    P0_kW = app.txConfig.P0 / 1000;
                    Pcu_kW = app.txConfig.Pcu / 1000;
                    
                    % Calculate losses at current load
                    total_loss_kW = P0_kW + (K_load^2) * Pcu_kW;
                    
                    % Add fan power if load > 0.8 (simple approximation for ONAF)
                    if K_load >= 0.8
                        total_loss_kW = total_loss_kW + app.txConfig.fan_power;
                        fan_status = 'ON';
                    else
                        fan_status = 'OFF';
                    end
                    
                    daily_cost = total_loss_kW * 24 * price;
                    annual_cost = daily_cost * 365;
                    
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Total Losses (Load %%%.0f): %.1f kW (Fans %s)', K_load*100, total_loss_kW, fan_status)}];
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Cost of Wasted Energy: $%.2f / day', daily_cost)}];
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Annual Cost: $%.0f / year', annual_cost)}];
                    
                    % Savings comparison (reduce load by 10%)
                    if K_load > 0.2
                        K_new = K_load - 0.1;
                        new_loss = P0_kW + (K_new^2) * Pcu_kW;
                        new_annual = (new_loss * 24 * price) * 365;
                        savings = annual_cost - new_annual;
                        app.LogArea.Value = [app.LogArea.Value; {sprintf('Idea: Reducing load by %%10 saves $%.0f per year!', savings)}];
                    end
                    
                    app.results.eco_P0 = P0_kW;
                    app.results.eco_Pcu = (K_load^2) * Pcu_kW;
                    app.results.eco_Fan = (K_load >= 0.8) * app.txConfig.fan_power;
                    
                    app.PlotSelector.Value = 'Economic Cost Analysis';
                end
                
                app.LogArea.Value = [app.LogArea.Value; {'Simulation completed!'}];
"""
app_code = app_code.replace("app.LogArea.Value = [app.LogArea.Value; {'Simulation completed!'}];", eco_logic)

plot_logic = """
                case 'Economic Cost Analysis'
                    if isfield(app.results, 'eco_P0')
                        pie_data = [app.results.eco_P0, app.results.eco_Pcu, app.results.eco_Fan];
                        pie_labels = {'Core Loss (P0)', 'Copper Loss (Pcu)', 'Cooling Fans'};
                        
                        % Filter out 0 values for pie chart
                        idx = pie_data > 0;
                        
                        cla(app.UIAxes);
                        pie(app.UIAxes, pie_data(idx), pie_labels(idx));
                        title(app.UIAxes, 'Distribution of Energy Losses & Cost');
                    else
                        title(app.UIAxes, 'Run Cost Analysis first.');
                    end
                    
                case 'Harmonic Waveform'
"""
app_code = app_code.replace("case 'Harmonic Waveform'", plot_logic)

with open(flux_app, 'w', encoding='utf-8') as f:
    f.write(app_code)

print('Economic feature added!')
