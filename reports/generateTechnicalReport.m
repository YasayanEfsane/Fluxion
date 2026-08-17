function generateTechnicalReport(results)
% generateTechnicalReport Generates a markdown report for the results

fid = fopen('reports/TechnicalReport.md', 'w');
fprintf(fid, '# Fluxion Technical Report\n\n');
fprintf(fid, '## 1. Parameters\n');
fprintf(fid, 'The base values and equivalent circuit parameters have been successfully calculated.\n');
fprintf(fid, 'Primary Base Voltage (L-L): %.2f kV\n', results.baseVals.V1n_LL / 1000);
fprintf(fid, 'Secondary Base Voltage (L-L): %.2f kV\n', results.baseVals.V2n_LL / 1000);
fprintf(fid, 'Equivalent R (pu): %.4f\n', results.eqCircuit.pu.Req);
fprintf(fid, 'Equivalent X (pu): %.4f\n\n', results.eqCircuit.pu.Xeq);

fprintf(fid, '## 2. Inrush Analysis\n');
fprintf(fid, 'Monte Carlo simulation completed with %d samples.\n', height(results.mc_results.table));
fprintf(fid, 'Max Inrush Current (pu): %.2f\n\n', max(results.mc_results.peak_pu));

fprintf(fid, '## 3. Thermal Analysis\n');
fprintf(fid, 'Top-oil steady-state temperature at nominal load: %.1f deg C\n', results.thermal_steady.top_oil);
fprintf(fid, 'Hot-spot steady-state temperature at nominal load: %.1f deg C\n', results.thermal_steady.hot_spot);

fclose(fid);
disp('Technical report generated at reports/TechnicalReport.md');

end
