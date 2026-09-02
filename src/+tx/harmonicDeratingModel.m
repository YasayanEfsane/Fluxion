function [I_max_pu, derated_MVA, F_HL, spectrum_h, spectrum_I] = harmonicDeratingModel(Sn, load_type, Pec_R)
% harmonicDeratingModel Calculates the transformer derating due to harmonics
% Based on IEEE C57.110 standard.
%
% Inputs:
%   Sn        : Nominal Power in VA
%   load_type : Type of non-linear load ('Linear', '6-Pulse EV Charger', '12-Pulse EV Charger')
%   Pec_R     : Rated eddy current loss as a per-unit of I^2R losses (default 0.1)
%
% Outputs:
%   I_max_pu    : Maximum allowable RMS current in per-unit (Derating Factor)
%   derated_MVA : New safe maximum power rating in MVA
%   F_HL        : Harmonic Loss Factor
%   spectrum_h  : Harmonic orders
%   spectrum_I  : Harmonic current magnitudes (pu)

if nargin < 3
    Pec_R = 0.1; % 10% eddy current losses is typical for power transformers
end

% Define the harmonic spectrum based on load type
switch load_type
    case '6-Pulse EV Charger'
        % Typical 6-pulse rectifier (h = 6k +/- 1, I_h ~ 1/h)
        k = 1:5; 
        spectrum_h = [1, sort([6*k-1, 6*k+1])];
        spectrum_I = [1.00, 1./spectrum_h(2:end)]; % Idealized
        % Add some practical damping for higher harmonics
        spectrum_I(2:end) = spectrum_I(2:end) .* exp(-0.05 * spectrum_h(2:end));
        
    case '12-Pulse EV Charger'
        % Typical 12-pulse rectifier (h = 12k +/- 1)
        k = 1:3;
        spectrum_h = [1, sort([12*k-1, 12*k+1])];
        spectrum_I = [1.00, 1./spectrum_h(2:end)];
        spectrum_I(2:end) = spectrum_I(2:end) .* exp(-0.05 * spectrum_h(2:end));
        
    otherwise % 'Linear'
        spectrum_h = 1;
        spectrum_I = 1.0;
end

% RMS value of the harmonic current relative to fundamental
% Calculate THD just for reference
I_rms_sq = sum(spectrum_I.^2);
I_1_sq = spectrum_I(1)^2;

% Harmonic Loss Factor (F_HL)
% F_HL = sum(Ih^2 * h^2) / sum(Ih^2)
sum_Ih2_h2 = sum((spectrum_I.^2) .* (spectrum_h.^2));
sum_Ih2 = sum(spectrum_I.^2);
F_HL = sum_Ih2_h2 / sum_Ih2;

% Derating Calculation (IEEE C57.110)
% I_max (pu) = sqrt( (1 + Pec_R) / (1 + F_HL * Pec_R) )
% This assumes that total loss under harmonic load should not exceed 
% rated total loss (I^2*R + eddy).
I_max_pu = sqrt( (1 + Pec_R) / (1 + F_HL * Pec_R) );

% Derated Capacity
derated_MVA = (Sn * I_max_pu) / 1e6;

end
