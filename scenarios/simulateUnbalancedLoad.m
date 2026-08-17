function load_results = simulateUnbalancedLoad(txConfig, unbalance_factor, K_load)
% simulateUnbalancedLoad Simulates unbalanced phase loading
%
% Inputs:
%   txConfig: Transformer configuration struct
%   unbalance_factor: Factor by which Phase A is overloaded (e.g. 1.5)
%   K_load: Base load factor (pu)

if nargin < 3
    K_load = 1.0;
end
if nargin < 2
    unbalance_factor = 1.4;
end

baseVals = tx.calculateBaseValues(txConfig);

fs = 2000;
t = 0:1/fs:0.1;

I2_peak = K_load * baseVals.I2n_L * sqrt(2);

% Phase A is heavily loaded, Phase B and C are lightly loaded
mag_A = I2_peak * unbalance_factor;
mag_B = I2_peak * 0.8;
mag_C = I2_peak * 0.8;

i2_a = mag_A * cos(2*pi*txConfig.fn*t);
i2_b = mag_B * cos(2*pi*txConfig.fn*t - 2*pi/3);
i2_c = mag_C * cos(2*pi*txConfig.fn*t + 2*pi/3);

i2 = [i2_a; i2_b; i2_c];

% Calculate sequence components for Phase A at t=0
% Convert to phasors
I_A = mag_A * exp(1j*0);
I_B = mag_B * exp(-1j*2*pi/3);
I_C = mag_C * exp(1j*2*pi/3);

a = exp(1j*2*pi/3);
I_zero = (1/3) * (I_A + I_B + I_C);
I_pos  = (1/3) * (I_A + a*I_B + a^2*I_C);
I_neg  = (1/3) * (I_A + a^2*I_B + a*I_C);

load_results.t = t;
load_results.i2 = i2;
load_results.I_zero_mag = abs(I_zero);
load_results.I_pos_mag = abs(I_pos);
load_results.I_neg_mag = abs(I_neg);
load_results.description = sprintf('Unbalanced load (Phase A overloaded by %.1fx)', unbalance_factor);

end
