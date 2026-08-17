function load_results = simulateHarmonicLoad(txConfig, THD_target, K_load)
% simulateHarmonicLoad Simulates transformer operation feeding a non-linear load
%
% Models a typical 6-pulse rectifier load which generates 
% 5th, 7th, 11th, and 13th harmonics on the secondary side.
%
% Inputs:
%   txConfig: Transformer configuration struct
%   THD_target: Target Total Harmonic Distortion (e.g. 0.20 for 20%)
%   K_load: Load factor (pu)

if nargin < 3
    K_load = 1.0;
end
if nargin < 2
    THD_target = 0.25;
end

baseVals = tx.calculateBaseValues(txConfig);

fs = 5000; % Higher sampling frequency for harmonics
t = 0:1/fs:0.1; % 5 cycles

I2_fund = K_load * baseVals.I2n_L * sqrt(2); % Peak fundamental scaled by load factor

% Typical 6-pulse harmonic spectrum relative to fundamental
% h5 = 1/5 = 0.20, h7 = 1/7 = 0.14, h11 = 1/11 = 0.09
% We scale them to match the THD_target
spectrum = [1.0, 0, 0, 0, 0.20, 0, 0.14, 0, 0, 0, 0.09, 0, 0.07]; % Up to 13th
base_THD = sqrt(sum(spectrum(2:end).^2));
scale_factor = THD_target / base_THD;

i2_a = zeros(1, length(t));
i2_b = zeros(1, length(t));
i2_c = zeros(1, length(t));

% Construct the harmonic waveform
for h = 1:2:13
    if spectrum(h) > 0
        mag = I2_fund * spectrum(h);
        if h > 1
            mag = mag * scale_factor;
        end
        
        i2_a = i2_a + mag * cos(2*pi*txConfig.fn*h*t);
        i2_b = i2_b + mag * cos(2*pi*txConfig.fn*h*t - h*2*pi/3);
        i2_c = i2_c + mag * cos(2*pi*txConfig.fn*h*t + h*2*pi/3);
    end
end

i2 = [i2_a; i2_b; i2_c];

% Primary current reflects the secondary load (ideal transformer assumption for shape)
% plus some high frequency damping due to leakage reactance.
% We simply reflect it by the turns ratio for this scenario demonstration.
turn_ratio = txConfig.V1n / txConfig.V2n;
i1 = i2 / turn_ratio;

load_results.t = t;
load_results.i1 = i1;
load_results.i2 = i2;
load_results.THD = THD_target;
load_results.description = sprintf('Non-linear harmonic load (THD: %d%%)', round(THD_target*100));

end
