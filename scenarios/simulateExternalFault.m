function fault_results = simulateExternalFault(txConfig, fault_type, fault_distance_km)
% simulateExternalFault Simulates short circuits outside the protection zone
%
% This is used to test the stability of the differential protection
% (making sure the relay RESTRAINS during through-faults).
%
% Inputs:
%   txConfig: Transformer configuration struct
%   fault_type: String ('3PH', 'LL', 'SLG')
%   fault_distance_km: Distance to fault to calculate external impedance

if nargin < 2
    fault_type = '3PH';
    fault_distance_km = 5.0; % 5 km away
end

baseVals = tx.calculateBaseValues(txConfig);
eqCircuit = tx.estimateEquivalentCircuit(txConfig, baseVals);

% Typical line impedance (e.g. 0.4 ohms/km)
Z_line = 0.4 * fault_distance_km;

% Transformer impedance referred to secondary
Z_tx_sec = sqrt(eqCircuit.R1^2 + eqCircuit.X1^2) * (txConfig.V2n/txConfig.V1n)^2;

% Total fault impedance
Z_total = Z_tx_sec + Z_line;

% Fault current (solid 3-phase fault assumption)
V_phase_sec = (txConfig.V2n / sqrt(3));
I_fault_rms = V_phase_sec / Z_total;
I_fault_peak = I_fault_rms * sqrt(2);

fs = 2000;
t = 0:1/fs:0.1;

% Normal load current before fault
I_load_peak = baseVals.I2n_L * sqrt(2);
i2_normal = I_load_peak * cos(2*pi*txConfig.fn*t);

% Fault occurs at t = 0.04s
fault_idx = find(t >= 0.04, 1);

i2_a = i2_normal;
if strcmp(fault_type, '3PH') || strcmp(fault_type, 'SLG')
    i2_a(fault_idx:end) = I_fault_peak * cos(2*pi*txConfig.fn*t(fault_idx:end) - pi/4); % Lagging fault current
end

% Primary current is proportional (through-fault), CTs will see the same
% scaled current, generating a large Restraining Current but near-zero Differential Current.
turn_ratio = txConfig.V1n / txConfig.V2n;
i1_a = i2_a / turn_ratio;

fault_results.t = t;
fault_results.i1_a = i1_a;
fault_results.i2_a = i2_a;
fault_results.I_fault_rms = I_fault_rms;
fault_results.description = sprintf('External %s fault at %.1f km', fault_type, fault_distance_km);

end
