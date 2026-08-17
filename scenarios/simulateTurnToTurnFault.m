function fault_results = simulateTurnToTurnFault(txConfig, faulted_turns_ratio)
% simulateTurnToTurnFault Simulates an internal turn-to-turn fault
%
% Models a short circuit across a fraction of the primary winding.
% 
% Inputs:
%   txConfig: Transformer configuration
%   faulted_turns_ratio: Fraction of turns shorted (e.g. 0.05 for 5%)
%
% Outputs:
%   fault_results: Struct with current vectors

if nargin < 2
    faulted_turns_ratio = 0.05; % 5% turn fault
end

baseVals = tx.calculateBaseValues(txConfig);
eqCircuit = tx.estimateEquivalentCircuit(txConfig, baseVals);

% In a turn-to-turn fault, the shorted turns act as an auto-transformer
% with a very low impedance secondary shorted on itself.
% The current circulating in the shorted turns can be massive,
% while the terminal currents might not increase dramatically immediately.

fs = 2000;
t = 0:1/fs:0.1;
V_peak = txConfig.V1n * sqrt(2)/sqrt(3);

% Normal currents
I_load_pu = 1.0;
I1_mag = I_load_pu * baseVals.I1n_L * sqrt(2);
I2_mag = I_load_pu * baseVals.I2n_L * sqrt(2);

i1 = [I1_mag * cos(2*pi*txConfig.fn*t);
      I1_mag * cos(2*pi*txConfig.fn*t - 2*pi/3);
      I1_mag * cos(2*pi*txConfig.fn*t + 2*pi/3)];
      
i2 = [I2_mag * cos(2*pi*txConfig.fn*t - pi/6 + pi);
      I2_mag * cos(2*pi*txConfig.fn*t - 2*pi/3 - pi/6 + pi);
      I2_mag * cos(2*pi*txConfig.fn*t + 2*pi/3 - pi/6 + pi)];

% Induce internal fault on Phase A at t = 0.04s
fault_idx = find(t >= 0.04, 1);

% Fault current circulating in the shorted turns
% I_fault_circulating = V_shorted / Z_shorted
% Roughly: V_shorted = V_phase * faulted_turns_ratio
% Z_shorted = Z_leakage * faulted_turns_ratio (approximation)
% Actually, Z_shorted is very small, mostly resistive.
R_shorted = eqCircuit.R1 * faulted_turns_ratio;
X_shorted = eqCircuit.X1 * faulted_turns_ratio;
Z_shorted = sqrt(R_shorted^2 + X_shorted^2);

I_circ_mag = (V_peak * faulted_turns_ratio) / Z_shorted;

% This circulating current acts as an internal load on Phase A, 
% causing the primary terminal current to increase by:
% dI1 = I_circ * faulted_turns_ratio
dI1_mag = I_circ_mag * faulted_turns_ratio;

% Apply fault to primary Phase A
i1(1, fault_idx:end) = i1(1, fault_idx:end) + dI1_mag * cos(2*pi*txConfig.fn*t(fault_idx:end) - atan(X_shorted/R_shorted));

% Secondary currents don't change much because the fault is on the primary
% and acts as a parallel load to the magnetic core.

fault_results.t = t;
fault_results.i1 = i1;
fault_results.i2 = i2;
fault_results.circulating_current = I_circ_mag;
fault_results.description = sprintf('Turn-to-turn fault on Primary Phase A (%d%% turns)', faulted_turns_ratio*100);

end
