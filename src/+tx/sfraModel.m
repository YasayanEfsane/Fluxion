function [freq, mag_healthy, mag_fault, phase_healthy, phase_fault, fault_desc] = sfraModel(fault_type)
% sfraModel Simulates Sweep Frequency Response Analysis (SFRA)
% Generates a realistic Bode plot for a power transformer's transfer function
% and simulates how mechanical faults shift the resonances.
%
% Inputs:
%   fault_type : 'Healthy', 'Axial Displacement', 'Radial Deformation', 'Short-Circuited Turn'
%
% Outputs:
%   freq        : Frequency array (Hz)
%   mag_healthy : Magnitude (dB) of healthy transformer
%   mag_fault   : Magnitude (dB) of faulty transformer
%   phase_...   : Phase (degrees)
%   fault_desc  : Description of the physical interpretation

if nargin < 1
    fault_type = 'Axial Displacement';
end

% Frequency range: 20 Hz to 2 MHz (Logarithmic scale)
freq = logspace(log10(20), log10(2e6), 2000);
w = 2 * pi * freq;
s = 1j * w;

% Synthetic RLC ladder parameters for a "Healthy" transformer
% We model the transfer function using cascaded poles and zeros
% to mimic the core, interaction, and winding structural resonances.

% Core resonance (~1 kHz)
w_c1 = 2 * pi * 1e3;   z_c1 = 0.5;
% Interaction resonance (~10 kHz)
w_c2 = 2 * pi * 10e3;  z_c2 = 0.1;
% Winding resonances (High frequency)
w_w1 = 2 * pi * 150e3; z_w1 = 0.05;
w_w2 = 2 * pi * 400e3; z_w2 = 0.03;
w_w3 = 2 * pi * 900e3; z_w3 = 0.04;

% Zeros (Valleys/Anti-resonances)
w_z1 = 2 * pi * 4e3;   z_z1 = 0.2;
w_z2 = 2 * pi * 60e3;  z_z2 = 0.08;
w_z3 = 2 * pi * 250e3; z_z3 = 0.02;
w_z4 = 2 * pi * 600e3; z_z4 = 0.03;

% Baseline Transfer Function construction
H_healthy = 100 * (s.^2 + 2*z_z1*w_z1*s + w_z1^2) ...
          .* (s.^2 + 2*z_z2*w_z2*s + w_z2^2) ...
          .* (s.^2 + 2*z_z3*w_z3*s + w_z3^2) ...
          .* (s.^2 + 2*z_z4*w_z4*s + w_z4^2) ...
          ./ ( (s.^2 + 2*z_c1*w_c1*s + w_c1^2) ...
             .* (s.^2 + 2*z_c2*w_c2*s + w_c2^2) ...
             .* (s.^2 + 2*z_w1*w_w1*s + w_w1^2) ...
             .* (s.^2 + 2*z_w2*w_w2*s + w_w2^2) ...
             .* (s.^2 + 2*z_w3*w_w3*s + w_w3^2) );

% Apply normalization factor to keep dB roughly realistic (-80 to +10 dB)
H_healthy = H_healthy * 1e18 ./ s; % Adding a generic 1/s integrator for LF slope

mag_healthy = 20 * log10(abs(H_healthy)) - 40;
phase_healthy = angle(H_healthy) * 180/pi;

% Fault Modifiers
fault_desc = 'No mechanical deformation detected.';
mag_fault = mag_healthy;
phase_fault = phase_healthy;

switch fault_type
    case 'Axial Displacement'
        % Shifts mid/high frequency resonances (changes series capacitance)
        shift = 1.15; % 15% shift in frequencies
        fault_desc = 'Axial displacement detected. Mid-to-high frequency resonances (100kHz - 1MHz) are shifted right due to altered series capacitance.';
        H_fault = 100 * (s.^2 + 2*z_z1*w_z1*s + w_z1^2) ...
          .* (s.^2 + 2*z_z2*(w_z2*shift)*s + (w_z2*shift)^2) ...
          .* (s.^2 + 2*z_z3*(w_z3*shift)*s + (w_z3*shift)^2) ...
          .* (s.^2 + 2*z_z4*(w_z4*shift)*s + (w_z4*shift)^2) ...
          ./ ( (s.^2 + 2*z_c1*w_c1*s + w_c1^2) ...
             .* (s.^2 + 2*z_c2*w_c2*s + w_c2^2) ...
             .* (s.^2 + 2*z_w1*(w_w1*shift)*s + (w_w1*shift)^2) ...
             .* (s.^2 + 2*z_w2*(w_w2*shift)*s + (w_w2*shift)^2) ...
             .* (s.^2 + 2*z_w3*(w_w3*shift)*s + (w_w3*shift)^2) );
        H_fault = H_fault * 1e18 ./ s;
        mag_fault = 20 * log10(abs(H_fault)) - 40;
        phase_fault = angle(H_fault) * 180/pi;

    case 'Radial Deformation'
        % Changes mutual inductance, affects lower-mid frequencies (Hoop stress)
        shift = 0.8; % 20% shift left
        fault_desc = 'Radial deformation (Hoop Stress) detected. Low-to-mid frequencies are shifted left due to altered leakage inductance.';
        H_fault = 100 * (s.^2 + 2*z_z1*(w_z1*shift)*s + (w_z1*shift)^2) ...
          .* (s.^2 + 2*z_z2*(w_z2*shift)*s + (w_z2*shift)^2) ...
          .* (s.^2 + 2*z_z3*w_z3*s + w_z3^2) ...
          .* (s.^2 + 2*z_z4*w_z4*s + w_z4^2) ...
          ./ ( (s.^2 + 2*z_c1*w_c1*s + w_c1^2) ...
             .* (s.^2 + 2*z_c2*(w_c2*shift)*s + (w_c2*shift)^2) ...
             .* (s.^2 + 2*z_w1*(w_w1*shift)*s + (w_w1*shift)^2) ...
             .* (s.^2 + 2*z_w2*w_w2*s + w_w2^2) ...
             .* (s.^2 + 2*z_w3*w_w3*s + w_w3^2) );
        H_fault = H_fault * 1e18 ./ s;
        mag_fault = 20 * log10(abs(H_fault)) - 40;
        phase_fault = angle(H_fault) * 180/pi;
        
    case 'Short-Circuited Turn'
        % Destroys the low frequency response (core magnetization)
        fault_desc = 'Short-circuited turn detected. Low frequency core response (<10 kHz) is severely attenuated due to loss of magnetizing impedance.';
        w_c1_f = 2 * pi * 5e3; z_c1_f = 2.0; % Heavily damped and shifted
        H_fault = 100 * (s.^2 + 2*z_z1*w_z1*s + w_z1^2) ...
          .* (s.^2 + 2*z_z2*w_z2*s + w_z2^2) ...
          .* (s.^2 + 2*z_z3*w_z3*s + w_z3^2) ...
          .* (s.^2 + 2*z_z4*w_z4*s + w_z4^2) ...
          ./ ( (s.^2 + 2*z_c1_f*w_c1_f*s + w_c1_f^2) ...
             .* (s.^2 + 2*z_c2*w_c2*s + w_c2^2) ...
             .* (s.^2 + 2*z_w1*w_w1*s + w_w1^2) ...
             .* (s.^2 + 2*z_w2*w_w2*s + w_w2^2) ...
             .* (s.^2 + 2*z_w3*w_w3*s + w_w3^2) );
        H_fault = H_fault * 1e18 ./ s;
        mag_fault = 20 * log10(abs(H_fault)) - 40 - 15; % Overall attenuation
        phase_fault = angle(H_fault) * 180/pi;
end

end
