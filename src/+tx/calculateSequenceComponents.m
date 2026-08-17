function [seq_pos, seq_neg, seq_zero] = calculateSequenceComponents(phasors)
% calculateSequenceComponents Calculates symmetrical components from 3-phase phasors
%
% Inputs:
%   phasors: 3x1 or 3xN complex array [PhasorA; PhasorB; PhasorC]
%
% Outputs:
%   seq_pos: Positive sequence phasor
%   seq_neg: Negative sequence phasor
%   seq_zero: Zero sequence phasor

a = exp(1j * 2 * pi / 3);
A_mat = [1, 1,   1;
         1, a^2, a;
         1, a,   a^2];
         
A_inv = (1/3) * conj(A_mat);

seq = A_inv * phasors;

seq_zero = seq(1, :);
seq_pos = seq(2, :);
seq_neg = seq(3, :);

end
