function protConfig = defaultProtectionConfig()
% defaultProtectionConfig Returns default settings for ANSI 87T

protConfig = struct();
protConfig.fs = 2000; % 2 kHz sampling rate
protConfig.fn = 50;   % 50 Hz system

protConfig.I_pickup = 0.2;   % 0.2 pu
protConfig.Slope1 = 0.3;     % 30%
protConfig.Slope2 = 0.8;     % 80%
protConfig.Breakpoint = 2.0; % 2 pu
protConfig.HighSet = 10.0;   % 10 pu

protConfig.Harm2_Limit = 0.15; % 15% 2nd harmonic
protConfig.Harm5_Limit = 0.35; % 35% 5th harmonic

protConfig.TripConfirmTime = 0.01; % 10 ms (half cycle)

% CT Ratings (based on 50 MVA 154/34.5 kV)
% I1n = 50M / (sqrt(3)*154k) = 187 A. Use 300/5 CT
protConfig.CT1_ratio = 300 / 5;
protConfig.I1n = 187.45;

% I2n = 50M / (sqrt(3)*34.5k) = 836 A. Use 1200/5 CT
protConfig.CT2_ratio = 1200 / 5;
protConfig.I2n = 836.74;

end
