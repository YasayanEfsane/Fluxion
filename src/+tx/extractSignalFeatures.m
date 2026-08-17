function features = extractSignalFeatures(i1_raw, i2_raw, fs)
% extractSignalFeatures Extracts features for ML classification
%
% Inputs:
%   i1_raw: 3xN primary current matrix
%   i2_raw: 3xN secondary current matrix
%   fs: Sampling frequency

% Basic signal processing
N = size(i1_raw, 2);
t = (0:N-1) / fs;

% RMS and Peak
rms_i1 = rms(i1_raw, 2);
peak_i1 = max(abs(i1_raw), [], 2);
crest_factor = peak_i1 ./ (rms_i1 + 1e-6);

% THD and Harmonics using FFT for Phase A
Y = fft(i1_raw(1,:));
P2 = abs(Y/N);
P1 = P2(1:floor(N/2)+1);
P1(2:end-1) = 2*P1(2:end-1);
f = fs*(0:(N/2))/N;

% Find fundamental (50 Hz), 2nd (100 Hz), 5th (250 Hz)
% (Assuming integer cycles in window)
[~, idx_50] = min(abs(f - 50));
[~, idx_100] = min(abs(f - 100));
[~, idx_250] = min(abs(f - 250));

fund_mag = P1(idx_50);
harm2_mag = P1(idx_100);
harm5_mag = P1(idx_250);

ratio_2nd = harm2_mag / (fund_mag + 1e-6);
ratio_5th = harm5_mag / (fund_mag + 1e-6);

% Symmetrical components for fundamental
[seq_pos, seq_neg, seq_zero] = tx.calculateSequenceComponents(i1_raw(:, 1));

features = struct();
features.RMS_A = rms_i1(1);
features.CrestFactor_A = crest_factor(1);
features.Harm2_Ratio = ratio_2nd;
features.Harm5_Ratio = ratio_5th;
features.SeqNeg_Mag = abs(seq_neg);
features.SeqZero_Mag = abs(seq_zero);

end
