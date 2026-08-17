function eqCircuit = estimateEquivalentCircuit(txConfig, baseVals)
% estimateEquivalentCircuit Estimates the equivalent circuit parameters
%
% Inputs:
%   txConfig: Transformer configuration struct
%   baseVals: Base values struct
%
% Outputs:
%   eqCircuit: Struct containing R, L, Rm, Lm parameters referred to primary

eqCircuit = struct();

% 1. Short-circuit test (Series parameters)
% Pcu = 3 * I1n^2 * Req1 
% Zeq_pu = uk
% Req_pu = Pcu / Sn
Req_pu = txConfig.Pcu / txConfig.Sn;
Zeq_pu = txConfig.uk;
Xeq_pu = sqrt(Zeq_pu^2 - Req_pu^2);

% Convert to actual values referred to Primary
Zeq_ohm = Zeq_pu * baseVals.Z1n;
Req_ohm = Req_pu * baseVals.Z1n;
Xeq_ohm = Xeq_pu * baseVals.Z1n;

% Assuming 50-50 split for primary and secondary (referred to primary)
eqCircuit.R1 = Req_ohm * txConfig.Z1_ratio;
eqCircuit.X1 = Xeq_ohm * txConfig.Z1_ratio;
eqCircuit.L1 = eqCircuit.X1 / baseVals.omega;

eqCircuit.R2_prime = Req_ohm * (1 - txConfig.Z1_ratio);
eqCircuit.X2_prime = Xeq_ohm * (1 - txConfig.Z1_ratio);
eqCircuit.L2_prime = eqCircuit.X2_prime / baseVals.omega;

% 2. No-load test (Shunt parameters)
% P0 = V1n^2 / Rm (per phase equivalent)
% But wait! Using 3-phase power: P0 = (V1n_LL^2) / Rm_eq_3phase 
% Or per phase (Star equivalent): P0/3 = (V1n_LN^2) / Rm
% Let's use pu:
% Y0_pu = I0_pu
% G0_pu = P0 / Sn
G0_pu = txConfig.P0 / txConfig.Sn;
Y0_pu = txConfig.I0;
B0_pu = sqrt(Y0_pu^2 - G0_pu^2);

% Shunt resistance and reactance in per unit
Rm_pu = 1 / G0_pu;
Xm_pu = 1 / B0_pu;

% Convert to actual values referred to Primary
eqCircuit.Rm = Rm_pu * baseVals.Z1n;
eqCircuit.Xm = Xm_pu * baseVals.Z1n;
eqCircuit.Lm = eqCircuit.Xm / baseVals.omega;

% Per unit values in output
eqCircuit.pu = struct();
eqCircuit.pu.Req = Req_pu;
eqCircuit.pu.Zeq = Zeq_pu;
eqCircuit.pu.Xeq = Xeq_pu;
eqCircuit.pu.Rm = Rm_pu;
eqCircuit.pu.Xm = Xm_pu;
eqCircuit.pu.I0 = Y0_pu;
eqCircuit.pu.P0 = G0_pu;
eqCircuit.pu.Pcu = Req_pu;

end
