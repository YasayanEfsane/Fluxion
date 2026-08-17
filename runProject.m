function results = runProject(varargin)
% runProject Main entry point for the Fluxion simulations

p = inputParser;
addParameter(p, 'Scenario', 'all', @ischar);
addParameter(p, 'UseParallel', false, @islogical);
parse(p, varargin{:});

addpath(genpath(pwd));
disp('--- Fluxion Digital Twin ---');

% Check dependencies
hasParallel = ~isempty(ver('parallel'));
hasSimscape = ~isempty(ver('physmod/elec')) || ~isempty(ver('simscape'));
hasStats = ~isempty(ver('stats'));
hasOptim = ~isempty(ver('optim'));

fprintf('Toolbox Status:\n');
fprintf('  Parallel Computing: %d\n', hasParallel);
fprintf('  Simscape Electrical: %d\n', hasSimscape);
fprintf('  Statistics/ML: %d\n', hasStats);
fprintf('  Optimization: %d\n\n', hasOptim);

results = struct();
txConfig = defaultTransformerConfig();

disp('Running base calculations...');
results.baseVals = tx.calculateBaseValues(txConfig);
results.eqCircuit = tx.estimateEquivalentCircuit(txConfig, results.baseVals);

disp('Running Monte Carlo Inrush Simulation...');
use_parallel_actual = p.Results.UseParallel && hasParallel;
results.mc_results = tx.runMonteCarlo(txConfig, 20, use_parallel_actual); % 20 for fast demo
disp('Monte Carlo complete.');

disp('Running Thermal Steady State...');
thermal = tx.thermalModel(txConfig, 25);
for i=1:1000
    [oil, hs, fans] = thermal.step(1.0, 25, 1);
end
results.thermal_steady = struct('top_oil', oil, 'hot_spot', hs);

disp('Generating HTML/PDF Report (placeholder)...');
generateTechnicalReport(results);
disp('Project execution completed successfully.');

end
