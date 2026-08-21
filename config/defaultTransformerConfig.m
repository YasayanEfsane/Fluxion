function txConfig = defaultTransformerConfig()
% defaultTransformerConfig Returns the default parameters for the 50 MVA transformer
%
% Returns a struct containing the physical and electrical parameters of the 
% 154/34.5 kV, 50 MVA, Dyn11 three-phase power transformer.

txConfig = struct();
txConfig.Sn = 50e6;          % Nominal power [VA]
txConfig.V1n = 154e3;        % Primary nominal voltage (L-L, RMS) [V]
txConfig.V2n = 34.5e3;       % Secondary nominal voltage (L-L, RMS) [V]
txConfig.fn = 50;            % Nominal frequency [Hz]
txConfig.vectorGroup = 'Dyn11'; % Vector group

txConfig.uk = 0.125;         % Short-circuit voltage [pu]
txConfig.Pcu = 265e3;        % Nominal copper loss [W]
txConfig.P0 = 42e3;          % No-load loss [W]
txConfig.I0 = 0.0075;        % No-load current [pu]

txConfig.tapRange = [-0.10, 0.10]; % Tap range [pu]
txConfig.tapStep = 0.0125;   % Tap step [pu]
txConfig.cooling = 'ONAN/ONAF'; % Cooling modes

txConfig.Tamb = 25;          % Ambient temperature [deg C]
txConfig.dTopOiln = 55;      % Nominal top-oil temperature rise [K]
txConfig.dHotSpotn = 23;     % Nominal hot-spot to top-oil gradient [K]

% DGA (Dissolved Gas Analysis) defaults [ppm]
txConfig.dga_CH4 = 120;
txConfig.dga_C2H4 = 30;
txConfig.dga_C2H2 = 15;


% Assumptions for missing parameters
txConfig.Z1_ratio = 0.5;     % Primary impedance ratio (assumed 50-50 split for R and X)
txConfig.CT1_ratio = 300 / 5;  % Assumed Primary CT Ratio
txConfig.CT2_ratio = 1200 / 5; % Assumed Secondary CT Ratio
end
