% generate_bh_curve.m
% Generates a realistic B-H curve for the 50 MVA transformer
% and saves it to a CSV file.

% Typical Silicon Steel B-H characteristics
% H [A/m], B [T]
H_data = [0, 10, 20, 30, 40, 50, 60, 70, 80, 100, 150, 200, 300, 500, 1000, 2000, 5000, 10000, 50000, 100000]';
B_data = [0, 0.4, 0.7, 0.9, 1.1, 1.25, 1.35, 1.45, 1.5, 1.58, 1.65, 1.7, 1.78, 1.85, 1.95, 2.02, 2.08, 2.15, 2.25, 2.35]';

% Ensure symmetry (add negative part)
H_full = [-flipud(H_data(2:end)); H_data];
B_full = [-flipud(B_data(2:end)); B_data];

T = table(H_full, B_full, 'VariableNames', {'H_A_m', 'B_T'});
writetable(T, 'bh_curve.csv');
disp('B-H curve generated and saved to bh_curve.csv');
