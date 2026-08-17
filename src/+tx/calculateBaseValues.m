function baseVals = calculateBaseValues(txConfig)
% calculateBaseValues Calculates base values for per-unit system
%
% Inputs:
%   txConfig: Transformer configuration struct
%
% Outputs:
%   baseVals: Struct containing base values (V, I, Z, Y) for both sides

baseVals = struct();

baseVals.Sn = txConfig.Sn;
baseVals.omega = 2 * pi * txConfig.fn;

% Primary side (HV) - Delta or Star? 
% Vector group is Dyn11 -> HV is Delta (D), LV is Star (y)
% For per-unit, base power is 3-phase Sn. Base voltage is L-L V1n.
baseVals.V1n_LL = txConfig.V1n;
baseVals.V1n_LN = baseVals.V1n_LL / sqrt(3); % Star equivalent
baseVals.I1n_L = baseVals.Sn / (sqrt(3) * baseVals.V1n_LL); % Line current
baseVals.Z1n = (baseVals.V1n_LL^2) / baseVals.Sn;

% Secondary side (LV) - Star
baseVals.V2n_LL = txConfig.V2n;
baseVals.V2n_LN = baseVals.V2n_LL / sqrt(3);
baseVals.I2n_L = baseVals.Sn / (sqrt(3) * baseVals.V2n_LL);
baseVals.Z2n = (baseVals.V2n_LL^2) / baseVals.Sn;

% Turns ratio
baseVals.N_ratio = txConfig.V1n / txConfig.V2n; % L-L ratio

end
