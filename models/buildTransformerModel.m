function buildTransformerModel(varargin)
% buildTransformerModel Builds the Simulink digital twin model programmatically.

p = inputParser;
addParameter(p, 'ForceRebuild', false, @islogical);
parse(p, varargin{:});

modelName = 'transformer_digital_twin';

% Check if Simscape Electrical is available
hasSimscape = ~isempty(ver('physmod/elec')) || ~isempty(ver('simscape'));
if ~hasSimscape
    warning('Simscape Electrical is not available. The Simulink model cannot be built with physical blocks. Using fallback pure MATLAB simulations.');
    return;
end

% Check if model is already open/exists
if bdIsLoaded(modelName)
    if p.Results.ForceRebuild
        close_system(modelName, 0);
    else
        disp('Model already loaded. Use ForceRebuild to recreate.');
        return;
    end
end

if exist([modelName, '.slx'], 'file') == 4
    if p.Results.ForceRebuild
        delete([modelName, '.slx']);
    else
        disp('Model file already exists. Use ForceRebuild to overwrite.');
        return;
    end
end

% Create new model
new_system(modelName);
open_system(modelName);

% Set configuration parameters (Solver, Fast Restart)
set_param(modelName, 'Solver', 'ode23tb'); % Good for stiff systems (transformers)
set_param(modelName, 'MaxStep', '1e-4');
% set_param(modelName, 'InitializeStateControl', 'UseDefault'); % Not supported in some MATLAB versions

% Add Blocks (using try-catch to avoid failing completely if a block path changes in newer MATLABs)
try
    % 1. Three-Phase Source
    add_block('powerlib/Electrical Sources/Three-Phase Source', [modelName, '/Source'], 'Position', [50, 100, 100, 150]);
    
    % 2. Breaker
    add_block('powerlib/Elements/Three-Phase Breaker', [modelName, '/Breaker'], 'Position', [200, 100, 250, 150]);
    
    % 3. Transformer
    add_block('powerlib/Elements/Three-Phase Transformer (Two Windings)', [modelName, '/Transformer'], 'Position', [400, 100, 480, 180]);
    
    % 4. Load
    add_block('powerlib/Elements/Three-Phase Series RLC Load', [modelName, '/Load'], 'Position', [650, 100, 700, 150]);
    
    % 5. Measurements
    add_block('powerlib/Measurements/Three-Phase V-I Measurement', [modelName, '/Measurement_Pri'], 'Position', [300, 100, 350, 150]);
    add_block('powerlib/Measurements/Three-Phase V-I Measurement', [modelName, '/Measurement_Sec'], 'Position', [550, 100, 600, 150]);
    
    % 6. Powergui
    add_block('powerlib/powergui', [modelName, '/powergui'], 'Position', [50, 20, 120, 50]);
    
    % Configure Transformer (Dyn11)
    set_param([modelName, '/Transformer'], 'Winding1Connection', 'Delta (D11)');
    set_param([modelName, '/Transformer'], 'Winding2Connection', 'Yg');
    
    % Connect blocks
    add_line(modelName, 'Source/1', 'Breaker/1', 'autorouting', 'on');
    add_line(modelName, 'Source/2', 'Breaker/2', 'autorouting', 'on');
    add_line(modelName, 'Source/3', 'Breaker/3', 'autorouting', 'on');
    
    add_line(modelName, 'Breaker/1', 'Measurement_Pri/1', 'autorouting', 'on');
    add_line(modelName, 'Breaker/2', 'Measurement_Pri/2', 'autorouting', 'on');
    add_line(modelName, 'Breaker/3', 'Measurement_Pri/3', 'autorouting', 'on');
    
    add_line(modelName, 'Measurement_Pri/1', 'Transformer/1', 'autorouting', 'on');
    add_line(modelName, 'Measurement_Pri/2', 'Transformer/2', 'autorouting', 'on');
    add_line(modelName, 'Measurement_Pri/3', 'Transformer/3', 'autorouting', 'on');
    
    add_line(modelName, 'Transformer/1', 'Measurement_Sec/1', 'autorouting', 'on');
    add_line(modelName, 'Transformer/2', 'Measurement_Sec/2', 'autorouting', 'on');
    add_line(modelName, 'Transformer/3', 'Measurement_Sec/3', 'autorouting', 'on');
    
    add_line(modelName, 'Measurement_Sec/1', 'Load/1', 'autorouting', 'on');
    add_line(modelName, 'Measurement_Sec/2', 'Load/2', 'autorouting', 'on');
    add_line(modelName, 'Measurement_Sec/3', 'Load/3', 'autorouting', 'on');
    
    disp('Simulink physical model built successfully.');
catch ME
    warning('Failed to build physical Simulink model due to block path issues: %s', ME.message);
end

save_system(modelName);

end
