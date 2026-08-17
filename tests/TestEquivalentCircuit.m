classdef TestEquivalentCircuit < matlab.unittest.TestCase
    
    methods (Test)
        function testParameterReproduction(testCase)
            import tx.*
            
            % Load config
            txConfig = defaultTransformerConfig();
            baseVals = calculateBaseValues(txConfig);
            
            % Estimate parameters
            eq = estimateEquivalentCircuit(txConfig, baseVals);
            
            % Calculate losses and parameters back from equivalent circuit
            % 1. No load test (rated voltage, secondary open)
            % Yeq = 1/Rm - j*(1/Xm)
            G0_calc = 1 / eq.pu.Rm;
            B0_calc = 1 / eq.pu.Xm;
            Y0_calc = sqrt(G0_calc^2 + B0_calc^2);
            
            P0_calc_W = G0_calc * txConfig.Sn;
            I0_calc_pu = Y0_calc;
            
            % 2. Short circuit test (rated current, secondary shorted)
            % Zeq = Req + j*Xeq
            Req_calc = eq.pu.Req;
            Zeq_calc = eq.pu.Zeq;
            
            Pcu_calc_W = Req_calc * txConfig.Sn;
            uk_calc_pu = Zeq_calc;
            
            % Verifications with 2% tolerance
            tol = 0.02;
            
            testCase.verifyLessThan(abs(P0_calc_W - txConfig.P0)/txConfig.P0, tol, 'No-load loss mismatch');
            testCase.verifyLessThan(abs(I0_calc_pu - txConfig.I0)/txConfig.I0, tol, 'No-load current mismatch');
            testCase.verifyLessThan(abs(Pcu_calc_W - txConfig.Pcu)/txConfig.Pcu, tol, 'Copper loss mismatch');
            testCase.verifyLessThan(abs(uk_calc_pu - txConfig.uk)/txConfig.uk, tol, 'Short-circuit voltage mismatch');
        end
    end
end
