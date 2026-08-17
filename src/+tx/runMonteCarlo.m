function mc_results = runMonteCarlo(txConfig, N_samples, use_parallel)
% runMonteCarlo Performs Monte Carlo simulation for Inrush currents
%
% Randomizes closing angle and residual flux.

if nargin < 3
    use_parallel = false;
end
if nargin < 2
    N_samples = 200;
end

% Set fixed seed for reproducibility
rng(42, 'twister');

closing_angles = 360 * rand(N_samples, 1);
residual_fluxes = -0.8 + 1.6 * rand(N_samples, 1);

peak_currents = zeros(N_samples, 1);
peak_pu = zeros(N_samples, 1);

% Check for parallel pool
if use_parallel && ~isempty(ver('parallel'))
    parfor i = 1:N_samples
        res = tx.simulateInrush(txConfig, closing_angles(i), residual_fluxes(i), 0.2);
        peak_currents(i) = res.peak_current;
        peak_pu(i) = res.peak_pu;
    end
else
    for i = 1:N_samples
        res = tx.simulateInrush(txConfig, closing_angles(i), residual_fluxes(i), 0.2);
        peak_currents(i) = res.peak_current;
        peak_pu(i) = res.peak_pu;
    end
end

mc_table = table(closing_angles, residual_fluxes, peak_currents, peak_pu);

% Generate surface plot data by gridding
[X, Y] = meshgrid(linspace(0, 360, 20), linspace(-0.8, 0.8, 20));
Z = griddata(closing_angles, residual_fluxes, peak_pu, X, Y, 'natural');

mc_results = struct();
mc_results.table = mc_table;
mc_results.closing_angles = closing_angles;
mc_results.residual_fluxes = residual_fluxes;
mc_results.peak_currents = peak_currents;
mc_results.peak_pu = peak_pu;
mc_results.surface_X = X;
mc_results.surface_Y = Y;
mc_results.surface_Z = Z;

end
