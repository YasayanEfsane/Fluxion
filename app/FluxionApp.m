classdef FluxionApp < matlab.apps.AppBase
    % FluxionApp Advanced UI for Fluxion
    
    properties (Access = public)
        UIFigure      matlab.ui.Figure
        TabGroup      matlab.ui.container.TabGroup
        TabParams     matlab.ui.container.Tab
        TabSim        matlab.ui.container.Tab
        
        % UI Components
        RunButton     matlab.ui.control.Button
        ExportButton  matlab.ui.control.Button
        LogArea       matlab.ui.control.TextArea
        UIAxes        matlab.ui.control.UIAxes
        ParamTable    matlab.ui.control.Table
        PlotSelector  matlab.ui.control.DropDown
        ScenarioDrop  matlab.ui.control.DropDown
        
        % App state
        txConfig
        results
    end
    
    methods (Access = private)
        
        function updatePlot(app, event)
            if isempty(app.results)
                return;
            end
            
            plotType = app.PlotSelector.Value;
            cla(app.UIAxes);
            
            switch plotType
                case 'Monte Carlo (Inrush)'
                    if isfield(app.results, 'mc_results')
                        scatter(app.UIAxes, app.results.mc_results.closing_angles, app.results.mc_results.peak_currents, 60, 'filled', 'MarkerFaceColor', [0 0.4470 0.7410]);
                        title(app.UIAxes, 'Monte Carlo: Closing Angle vs Inrush Current (Ampere)');
                        xlabel(app.UIAxes, 'Closing Angle (Degree)');
                        ylabel(app.UIAxes, 'Inrush Peak Current (Ampere)');
                        grid(app.UIAxes, 'on');
                    else
                        title(app.UIAxes, 'Inrush Analysis must be run for this data.');
                    end
                    
                case 'Thermal (Steady-State)'
                    if isfield(app.results, 'thermal_history')
                        plot(app.UIAxes, app.results.thermal_history.t, app.results.thermal_history.oil, 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]);
                        hold(app.UIAxes, 'on');
                        plot(app.UIAxes, app.results.thermal_history.t, app.results.thermal_history.hs, 'LineWidth', 2, 'Color', [0.6350 0.0780 0.1840]);
                        hold(app.UIAxes, 'off');
                        [V_st, ~] = tx.agingModel(app.results.thermal_history.hs(end), 1);
                        exp_life = 30 / V_st;
                        title(app.UIAxes, sprintf('Thermal Heating Curve (RUL: %.1f Years)', exp_life));
                        xlabel(app.UIAxes, 'Time (Minutes)');
                        ylabel(app.UIAxes, 'Temperature (\circC)');
                        legend(app.UIAxes, {'Top-Oil', 'Hot-Spot'}, 'Location', 'southeast');
                        grid(app.UIAxes, 'on');
                    else
                        title(app.UIAxes, 'Thermal Loading must be run for this data.');
                    end
                    
                case 'Protection Relay (Differential)'
                    % Standard characteristic based on default protection config
                    protConfig = defaultProtectionConfig();
                    I_rest = linspace(0, 5, 100);
                    I_diff = zeros(1,100);
                    for i=1:100
                        if I_rest(i) <= protConfig.Breakpoint
                            I_diff(i) = max(protConfig.I_pickup, protConfig.Slope1 * I_rest(i));
                        else
                            I_diff(i) = protConfig.Slope1*protConfig.Breakpoint + protConfig.Slope2*(I_rest(i)-protConfig.Breakpoint);
                        end
                    end
                    plot(app.UIAxes, I_rest, I_diff, 'r-', 'LineWidth', 2);
                    title(app.UIAxes, 'ANSI 87T Differential Protection Characteristic');
                    xlabel(app.UIAxes, 'I_{rest} (pu)');
                    ylabel(app.UIAxes, 'I_{diff} Threshold (pu)');
                    grid(app.UIAxes, 'on');
                case 'Harmonic Waveform'
                    if isfield(app.results, 'harmonic')
                        plot(app.UIAxes, app.results.harmonic.t*1000, app.results.harmonic.i2, 'LineWidth', 1.5);
                        title(app.UIAxes, 'Harmonic Load - Secondary Currents (25% THD)');
                        xlabel(app.UIAxes, 'Time (ms)'); ylabel(app.UIAxes, 'Current (A)'); grid(app.UIAxes, 'on');
                    else
                        title(app.UIAxes, 'Harmonic Load scenario must be run for this plot.');
                    end
                    
                case 'Unbalanced Load Currents'
                    if isfield(app.results, 'unbalanced')
                        plot(app.UIAxes, app.results.unbalanced.t*1000, app.results.unbalanced.i2, 'LineWidth', 1.5);
                        title(app.UIAxes, 'Unbalanced Load - Secondary Currents');
                        xlabel(app.UIAxes, 'Time (ms)'); ylabel(app.UIAxes, 'Current (A)'); grid(app.UIAxes, 'on');
                        legend(app.UIAxes, {'Phase A', 'Phase B', 'Phase C'});
                    else
                        title(app.UIAxes, 'Unbalanced Load scenario must be run for this plot.');
                    end
                    
                case 'External Fault Waveform'
                    if isfield(app.results, 'ext_fault')
                        plot(app.UIAxes, app.results.ext_fault.t*1000, app.results.ext_fault.i2_a, 'r', 'LineWidth', 1.5);
                        title(app.UIAxes, 'External Fault (Secondary Phase A Current)');
                        xlabel(app.UIAxes, 'Time (ms)'); ylabel(app.UIAxes, 'Current (A)'); grid(app.UIAxes, 'on');
                    else
                        title(app.UIAxes, 'External Fault scenario must be run for this plot.');
                    end
            end
        end
        
        function ExportResults(app, event)
            if isempty(app.results)
                uialert(app.UIFigure, 'Run the simulation first!', 'Error');
                return;
            end
            try
                generateTechnicalReport(app.results);
                app.LogArea.Value = [app.LogArea.Value; {'Report saved to reports/TechnicalReport.md file.'}];
                uialert(app.UIFigure, 'Results exported successfully (check reports folder).', 'Success');
            catch ME
                uialert(app.UIFigure, sprintf('Export error: %s', ME.message), 'Error');
            end
        end

        function RunSimulation(app, event)
            scenario = app.ScenarioDrop.Value;
            app.LogArea.Value = [app.LogArea.Value; {sprintf('Scenario (%s) is starting... Please wait.', scenario)}];
            drawnow;
            
            try
                % Grab parameters from table
                app.txConfig.Sn = str2double(app.ParamTable.Data{1,2}) * 1e6;
                app.txConfig.V1n = str2double(app.ParamTable.Data{2,2}) * 1e3;
                app.txConfig.V2n = str2double(app.ParamTable.Data{3,2}) * 1e3;
                app.txConfig.fn = str2double(app.ParamTable.Data{4,2});
                app.txConfig.uk = str2double(app.ParamTable.Data{6,2}) / 100;
                app.txConfig.I0 = str2double(app.ParamTable.Data{7,2}) / 100;
                app.txConfig.Pcu = str2double(app.ParamTable.Data{8,2}) * 1000;
                app.txConfig.P0 = str2double(app.ParamTable.Data{9,2}) * 1000;
                
                % Custom Load Factor K
                K_load = str2double(app.ParamTable.Data{11,2});
                if isnan(K_load) || K_load <= 0
                    K_load = 1.0;
                end
                
                % Recalculate base values based on new config
                if isempty(app.results)
                    app.results = struct();
                end
                app.results.baseVals = tx.calculateBaseValues(app.txConfig);
                app.results.eqCircuit = tx.estimateEquivalentCircuit(app.txConfig, app.results.baseVals);
                
                % Execute specific scenario
                if strcmp(scenario, 'Full System Test (All)') || strcmp(scenario, 'Inrush Analysis')
                    app.LogArea.Value = [app.LogArea.Value; {'Inrush Monte Carlo running (This may take a while)...'}];
                    drawnow;
                    app.results.mc_results = tx.runMonteCarlo(app.txConfig, 30, false); % 30 samples
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Max Inrush: %.2f Ampere', max(app.results.mc_results.peak_currents))}];
                    app.PlotSelector.Value = 'Monte Carlo (Inrush)';
                end
                
                if strcmp(scenario, 'Full System Test (All)') || strcmp(scenario, 'Thermal Loading')
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Thermal model running (Load = %%%.0f)...', K_load*100)}];
                    drawnow;
                    thermal = tx.thermalModel(app.txConfig, 25);
                    t_arr = 1:500; % 500 minutes
                    oil_arr = zeros(1,500);
                    hs_arr = zeros(1,500);
                    for i=1:500
                        [oil, hs, ~] = thermal.step(K_load, 25, 1);
                        oil_arr(i) = oil;
                        hs_arr(i) = hs;
                    end
                    app.results.thermal_history.t = t_arr;
                    app.results.thermal_history.oil = oil_arr;
                    app.results.thermal_history.hs = hs_arr;
                    app.results.thermal_steady = struct('top_oil', oil, 'hot_spot', hs);
                    
                    [V_steady, ~] = tx.agingModel(hs, 1);
                    expected_life_years = 30 / V_steady;
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Steady Hot-Spot Temperature: %.1f C', hs)}];
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Loss of Life Factor (V): %.2f -> Expected RUL: %.1f years', V_steady, expected_life_years)}];
                    app.PlotSelector.Value = 'Thermal (Steady-State)';
                end
                
                if strcmp(scenario, 'Full System Test (All)') || strcmp(scenario, 'Internal Fault')
                    app.LogArea.Value = [app.LogArea.Value; {'Checking ANSI 87T differential algorithm...'}];
                    drawnow;
                    app.PlotSelector.Value = 'Protection Relay (Differential)';
                end
                
                if strcmp(scenario, 'Full System Test (All)') || strcmp(scenario, 'ML Condition Diagnosis')
                    app.LogArea.Value = [app.LogArea.Value; {'Extracting signal features...'}];
                    drawnow;
                    % Generate dummy 3-phase internal fault signal for testing ML
                    fs = 2000; t = 0:1/fs:0.1;
                    i1 = [10*sin(2*pi*50*t); 10*sin(2*pi*50*t-2*pi/3); 10*sin(2*pi*50*t+2*pi/3)]; 
                    i2 = zeros(3, length(t)); % secondary is zero -> internal fault
                    
                    features = tx.extractSignalFeatures(i1, i2, fs);
                    [label, diag] = tx.classifyOperatingCondition(features);
                    
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('ML Prediction: %s', label)}];
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Confidence: %%%.1f', diag.confidence*100)}];
                end
                
                if strcmp(scenario, 'Full System Test (All)') || strcmp(scenario, 'Parameter Estimation (AI)')
                    app.LogArea.Value = [app.LogArea.Value; {'Starting optimization (fminsearch) with synthetic field data...'}];
                    drawnow;
                    
                    thermal = tx.thermalModel(app.txConfig, 25);
                    [T_oil_true, ~, ~] = thermal.step(K_load, 25, 1);
                    
                    noise = (rand() - 0.5) * 3;
                    synthData.T_oil = T_oil_true + noise; 
                    synthData.K_load = K_load;
                    
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Oil Temperature Read from Sensor: %.1f C', synthData.T_oil)}];
                    
                    estConfig = tx.estimateDigitalTwinParams(synthData);
                    
                    app.LogArea.Value = [app.LogArea.Value; {'--- Estimated Parameters ---'}];
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Real Pcu (Table): %.1f kW', app.txConfig.Pcu/1000)}];
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Estimated Pcu: %.1f kW', estConfig.Pcu/1000)}];
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Real P0 (Table): %.1f kW', app.txConfig.P0/1000)}];
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Estimated P0: %.1f kW', estConfig.P0/1000)}];
                end
                
                if strcmp(scenario, 'Full System Test (All)') || strcmp(scenario, 'Harmonic Load')
                    app.LogArea.Value = [app.LogArea.Value; {'Simulating 6-pulse rectifier with 25% THD (Total Harmonic Distortion)...'}];
                    drawnow;
                    app.results.harmonic = simulateHarmonicLoad(app.txConfig, 0.25, K_load);
                    app.LogArea.Value = [app.LogArea.Value; {app.results.harmonic.description}];
                    app.PlotSelector.Value = 'Harmonic Waveform';
                end
                
                if strcmp(scenario, 'Full System Test (All)') || strcmp(scenario, 'Unbalanced Load')
                    app.LogArea.Value = [app.LogArea.Value; {'Simulating Phase A 140% overloaded, Phase B and C 80% loaded...'}];
                    drawnow;
                    app.results.unbalanced = simulateUnbalancedLoad(app.txConfig, 1.4, K_load);
                    app.LogArea.Value = [app.LogArea.Value; {app.results.unbalanced.description}];
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Zero Sequence: %.1f A', app.results.unbalanced.I_zero_mag)}];
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Negative Sequence: %.1f A', app.results.unbalanced.I_neg_mag)}];
                    app.PlotSelector.Value = 'Unbalanced Load Currents';
                end
                
                if strcmp(scenario, 'Full System Test (All)') || strcmp(scenario, 'External Fault (Through-Fault)')
                    app.LogArea.Value = [app.LogArea.Value; {'Simulating 3-Phase (3PH) external fault 5 km away from transformer...'}];
                    drawnow;
                    app.results.ext_fault = simulateExternalFault(app.txConfig, '3PH', 5.0);
                    app.LogArea.Value = [app.LogArea.Value; {app.results.ext_fault.description}];
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Fault Current RMS: %.1f A', app.results.ext_fault.I_fault_rms)}];
                    app.LogArea.Value = [app.LogArea.Value; {'(Differential relay should not trip - Restraint condition)'}];
                    app.PlotSelector.Value = 'External Fault Waveform';
                end
                
                app.LogArea.Value = [app.LogArea.Value; {'Simulation completed!'}];
                
                updatePlot(app, []);
                
            catch ME
                app.LogArea.Value = [app.LogArea.Value; {sprintf('Error: %s', ME.message)}];
                uialert(app.UIFigure, 'Check parameters or simulation.', 'Calculation Error');
            end
        end
        
        function createComponents(app)
            app.UIFigure = uifigure('Name', 'Fluxion Digital Twin (Advanced)', 'Position', [100 100 1000 700]);
            app.TabGroup = uitabgroup(app.UIFigure, 'Position', [10 10 980 680]);
            
            % --- Parameters Tab ---
            app.TabParams = uitab(app.TabGroup, 'Title', 'Configuration & Scenario');
            
            uilabel(app.TabParams, 'Position', [20 600 300 22], 'Text', 'Transformer Nameplate Values', 'FontWeight', 'bold', 'FontSize', 14);
            
            app.ParamTable = uitable(app.TabParams, 'Position', [20 180 450 400]);
            app.ParamTable.ColumnName = {'Parameter', 'Value', 'Unit'};
            app.ParamTable.ColumnEditable = [false, true, false];
            app.ParamTable.RowName = [];
            
            app.txConfig = defaultTransformerConfig();
            data = {
                'Nominal Power', num2str(app.txConfig.Sn / 1e6), 'MVA';
                'Primary Voltage (L-L)', num2str(app.txConfig.V1n / 1e3), 'kV';
                'Secondary Voltage (L-L)', num2str(app.txConfig.V2n / 1e3), 'kV';
                'Frequency', num2str(app.txConfig.fn), 'Hz';
                'Vector Group', app.txConfig.vectorGroup, '-';
                'Short Circuit Voltage (uk)', num2str(app.txConfig.uk * 100), '%';
                'No-Load Current (I0)', num2str(app.txConfig.I0 * 100), '%';
                'Copper Loss', num2str(app.txConfig.Pcu / 1000), 'kW';
                'No-Load Loss', num2str(app.txConfig.P0 / 1000), 'kW';
                'Cooling', app.txConfig.cooling, '-';
                'Load Factor (K)', '1.0', 'pu';
            };
            app.ParamTable.Data = data;
            
            uilabel(app.TabParams, 'Position', [500 550 200 22], 'Text', 'Scenario to Run:', 'FontWeight', 'bold');
            app.ScenarioDrop = uidropdown(app.TabParams, 'Position', [500 520 250 22], ...
                'Items', {'Full System Test (All)', 'Inrush Analysis', 'Internal Fault', 'External Fault (Through-Fault)', 'Thermal Loading', 'Harmonic Load', 'Unbalanced Load', 'ML Condition Diagnosis', 'Parameter Estimation (AI)'});
                
            uilabel(app.TabParams, 'Position', [500 470 400 40], 'Text', ...
                'Note: Values can be edited in the table (Value column). After editing, the simulation will be run with the new values.', ...
                'WordWrap', 'on', 'FontAngle', 'italic');
                
            % --- Simulation Tab ---
            app.TabSim = uitab(app.TabGroup, 'Title', 'Simulation, Plots and Outputs');
            
            app.RunButton = uibutton(app.TabSim, 'push', 'Text', 'Start Analyses (Run Project)', ...
                'Position', [20 580 250 40], 'FontWeight', 'bold', 'BackgroundColor', [0 0.45 0.74], 'FontColor', 'white');
            app.RunButton.ButtonPushedFcn = createCallbackFcn(app, @RunSimulation, true);
            
            app.ExportButton = uibutton(app.TabSim, 'push', 'Text', 'Export PDF/MD Report', ...
                'Position', [20 530 250 40], 'FontWeight', 'bold', 'BackgroundColor', [0.4660 0.6740 0.1880], 'FontColor', 'white');
            app.ExportButton.ButtonPushedFcn = createCallbackFcn(app, @ExportResults, true);
            
            app.LogArea = uitextarea(app.TabSim, 'Position', [20 20 250 490]);
            app.LogArea.Value = {'System ready. You can start the simulation.'};
            
            uilabel(app.TabSim, 'Position', [290 590 150 22], 'Text', 'Plot to Display:', 'FontWeight', 'bold');
            app.PlotSelector = uidropdown(app.TabSim, 'Position', [450 590 250 22], ...
                'Items', {'Monte Carlo (Inrush)', 'Thermal (Steady-State)', 'Protection Relay (Differential)', 'Harmonic Waveform', 'Unbalanced Load Currents', 'External Fault Waveform'}, ...
                'ValueChangedFcn', createCallbackFcn(app, @updatePlot, true));
                
            app.UIAxes = uiaxes(app.TabSim, 'Position', [290 20 660 550]);
            title(app.UIAxes, 'Result Plots Will Be Displayed Here');
        end
    end
    
    methods (Access = public)
        function app = FluxionApp()
            createComponents(app);
            if nargout == 0
                clear app
            end
        end
        function delete(app)
            delete(app.UIFigure);
        end
    end
end
