import re

app_file = r'C:\Users\yusuf\.gemini\antigravity\scratch\Fluxion\app\FluxionApp.m'
with open(app_file, 'r', encoding='utf-8') as f:
    app_code = f.read()

# 1. Add Properties
props = """    % IoT State
    IoTButton     matlab.ui.control.Button
    IoTTimer      
    IoTLineOil
    IoTLineHS
    IoTThermalModel
    IoTTime
    IsIoTRunning = false;
"""
app_code = app_code.replace("    results\n    end", "    results\n" + props + "    end")

# 2. Add ToggleIoT and IoTUpdate methods
methods = """
        function ToggleIoT(app, event)
            if ~app.IsIoTRunning
                % Start IoT Simulation
                app.IsIoTRunning = true;
                app.IoTButton.Text = 'Stop IoT Stream';
                app.IoTButton.BackgroundColor = [0.8500 0.3250 0.0980]; % Red
                
                app.LogArea.Value = [app.LogArea.Value; {'[IoT] Connecting to remote sensor stream...'}];
                drawnow;
                
                % Initialize thermal model for real-time
                if isempty(app.txConfig)
                    app.txConfig = defaultTransformerConfig();
                end
                app.IoTThermalModel = tx.thermalModel(app.txConfig, app.txConfig.Tamb);
                app.IoTTime = 0;
                
                % Prepare animated lines on UIAxes
                cla(app.UIAxes);
                hold(app.UIAxes, 'on');
                app.IoTLineOil = animatedline(app.UIAxes, 'Color', [0 0.4470 0.7410], 'LineWidth', 2);
                app.IoTLineHS = animatedline(app.UIAxes, 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 2);
                title(app.UIAxes, 'Live IoT Sensor Data: Transformer Temperatures');
                xlabel(app.UIAxes, 'Time (seconds)');
                ylabel(app.UIAxes, 'Temperature (°C)');
                legend(app.UIAxes, {'Top-Oil', 'Hot-Spot'}, 'Location', 'northwest');
                grid(app.UIAxes, 'on');
                
                % Create timer (runs every 1 second)
                app.IoTTimer = timer('ExecutionMode', 'fixedRate', ...
                                     'Period', 1.0, ...
                                     'TimerFcn', @(~,~) app.IoTUpdateCallback());
                start(app.IoTTimer);
                app.LogArea.Value = [app.LogArea.Value; {'[IoT] Streaming started!'}];
                scroll(app.LogArea, 'bottom');
            else
                % Stop IoT Simulation
                app.IsIoTRunning = false;
                app.IoTButton.Text = 'Live IoT Monitor';
                app.IoTButton.BackgroundColor = [0 0.4470 0.7410]; % Blue
                
                if ~isempty(app.IoTTimer) && isvalid(app.IoTTimer)
                    stop(app.IoTTimer);
                    delete(app.IoTTimer);
                end
                app.LogArea.Value = [app.LogArea.Value; {'[IoT] Sensor stream disconnected.'}];
                scroll(app.LogArea, 'bottom');
            end
        end
        
        function IoTUpdateCallback(app)
            % Simulate a noisy load factor around 1.1 to 1.3
            % to show dynamic heating
            noise = (rand() - 0.5) * 0.2;
            dynamic_K = 1.15 + noise;
            
            % Step the thermal model (simulating 1 minute per real second for visual effect)
            [oil, hs, fans] = app.IoTThermalModel.step(dynamic_K, app.txConfig.Tamb, 1);
            app.IoTTime = app.IoTTime + 1;
            
            % Update plot
            addpoints(app.IoTLineOil, app.IoTTime, oil);
            addpoints(app.IoTLineHS, app.IoTTime, hs);
            
            % Adjust axis limits dynamically
            if app.IoTTime > 60
                app.UIAxes.XLim = [app.IoTTime - 60, app.IoTTime];
            else
                app.UIAxes.XLim = [0, 60];
            end
            drawnow limitrate;
            
            % Occasional log updates
            if mod(app.IoTTime, 10) == 0
                msg = sprintf('[IoT %ds] Load: %.2f pu | Hot-Spot: %.1f C | Fans: %d', app.IoTTime, dynamic_K, hs, fans);
                app.LogArea.Value = [app.LogArea.Value; {msg}];
                scroll(app.LogArea, 'bottom');
            end
        end
"""
app_code = app_code.replace("methods (Access = private)", "methods (Access = private)\n" + methods)

# 3. Add the button in createComponents
btn = """
            app.ExportButton = uibutton(app.TabSim, 'push', 'Text', 'Export PDF/MD Report', ...
                'Position', [20 530 120 40], 'FontWeight', 'bold', 'BackgroundColor', [0.4660 0.6740 0.1880], 'FontColor', 'white');
            app.ExportButton.ButtonPushedFcn = createCallbackFcn(app, @ExportResults, true);
            
            app.IoTButton = uibutton(app.TabSim, 'push', 'Text', 'Live IoT Monitor', ...
                'Position', [150 530 120 40], 'FontWeight', 'bold', 'BackgroundColor', [0 0.4470 0.7410], 'FontColor', 'white');
            app.IoTButton.ButtonPushedFcn = createCallbackFcn(app, @ToggleIoT, true);
"""
app_code = re.sub(
    r"app\.ExportButton = uibutton.*?@ExportResults, true\);", 
    btn, 
    app_code, 
    flags=re.DOTALL
)

with open(app_file, 'w', encoding='utf-8') as f:
    f.write(app_code)
print("IoT module patched.")
