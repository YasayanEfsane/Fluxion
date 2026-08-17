function [V, L] = agingModel(theta_hs, dt_hours)
% agingModel Calculates insulation aging according to IEC 60076-7
%
% Inputs:
%   theta_hs: Hot-spot temperature [deg C] (scalar or array)
%   dt_hours: Time duration for each temperature value [hours]
%
% Outputs:
%   V: Aging acceleration factor (relative to 98 deg C reference)
%   L: Loss of life [hours]

% IEC 60076-7 reference temperature for normal aging is 98 deg C
% Activation energy for non-thermally upgraded paper
% Formula: V = 2^( (theta_hs - 98) / 6 )  (Simplified Montsinger rule)
% Or more rigorous Arrhenius: V = exp( (15000 / (110 + 273)) - (15000 / (theta_hs + 273)) )
% We'll use the standard Arrhenius formula from IEC
% For non-thermally upgraded paper: A = 15000, reference temp = 98 C (371 K)
% V = exp(15000/371 - 15000./(theta_hs + 273));

% Standard IEC 60076-7 uses reference 98 C
V = 2.^((theta_hs - 98) / 6);

L = sum(V .* dt_hours);

end
