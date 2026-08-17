function estimatedConfig = estimateDigitalTwinParams(syntheticData)
% estimateDigitalTwinParams Uses optimization to estimate transformer parameters
%
% Inputs:
%   syntheticData: Struct with measured voltages, currents, temperatures
%
% Outputs:
%   estimatedConfig: Estimated txConfig struct

hasOptim = ~isempty(ver('optim'));

% Initial guess (say, 50% off from true)
Pcu_guess = 350e3; 
P0_guess = 60e3;

if hasOptim
    % We have Optimization Toolbox, use lsqnonlin or fminsearch
    % Objective function: minimize error between synthetic temperature and model
    
    % Let's use fminsearch (available in base MATLAB and robust for few vars)
    % True data
    T_oil_true = syntheticData.T_oil;
    K_load = syntheticData.K_load;
    
    % Objective function with positivity constraint penalty
    objFun = @(params) sum((simulateThermal(params(1), params(2), K_load) - T_oil_true).^2) ...
                       + 1e9 * (params(1) <= 0) + 1e9 * (params(2) <= 0);
    
    opts = optimset('Display','off');
    optParams = fminsearch(objFun, [Pcu_guess, P0_guess], opts);
    
    % Because only the ratio Pcu/P0 matters in steady-state thermal,
    % fminsearch might drift. We anchor P0 to the guess if it strays wildly,
    % or just return the ratio-based values.
    estimatedConfig.Pcu = abs(optParams(1));
    estimatedConfig.P0 = abs(optParams(2));
else
    % Fallback
    disp('Optimization Toolbox not found. Using naive estimation.');
    estimatedConfig.Pcu = Pcu_guess;
    estimatedConfig.P0 = P0_guess;
end

end

function T_oil = simulateThermal(Pcu, P0, K)
    % Minimal local thermal simulator for the objective function
    dTopOiln = 55;
    R = Pcu / P0;
    x = 0.8;
    tau = 150;
    
    dTheta_oil_ult = dTopOiln * ((1 + R * K^2) / (1 + R))^x;
    
    % Return steady state for simplicity
    T_oil = 25 + dTheta_oil_ult;
end
