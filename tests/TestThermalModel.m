classdef TestThermalModel < matlab.unittest.TestCase
    
    methods (Test)
        function testSteadyState(testCase)
            import tx.*
            txConfig = defaultTransformerConfig();
            
            % Start at 25 C
            T_amb = 25;
            thermal = thermalModel(txConfig, T_amb);
            
            % Run for a long time at nominal load (K=1)
            K = 1.0;
            dt = 1; % 1 minute
            t_total = 1000; % minutes (enough to reach steady state)
            
            for i = 1:t_total
                [theta_oil, theta_hs, fans] = thermal.step(K, T_amb, dt);
            end
            
            % Ultimate oil rise at K=1 should be dTopOiln
            expected_oil = T_amb + txConfig.dTopOiln;
            % Ultimate hot-spot rise at K=1 should be dTopOiln + dHotSpotn
            expected_hs = expected_oil + txConfig.dHotSpotn;
            
            testCase.verifyLessThan(abs(theta_oil - expected_oil), 1.0, 'Top-oil steady state mismatch');
            testCase.verifyLessThan(abs(theta_hs - expected_hs), 1.0, 'Hot-spot steady state mismatch');
        end
        
        function testFanHysteresis(testCase)
            import tx.*
            txConfig = defaultTransformerConfig();
            
            T_amb = 25;
            thermal = thermalModel(txConfig, T_amb);
            
            % Force temperature manually to test fan logic
            thermal.theta_top_oil = 60;
            [~,~,fans] = thermal.step(1.0, T_amb, 1);
            testCase.verifyFalse(fans, 'Fans should be off at 60 C initially');
            
            thermal.theta_top_oil = 66;
            [~,~,fans] = thermal.step(1.0, T_amb, 1);
            testCase.verifyTrue(fans, 'Fans should turn on above 65 C');
            
            thermal.theta_top_oil = 60;
            [~,~,fans] = thermal.step(1.0, T_amb, 1);
            testCase.verifyTrue(fans, 'Fans should stay on at 60 C due to hysteresis');
            
            thermal.theta_top_oil = 54;
            [~,~,fans] = thermal.step(1.0, T_amb, 1);
            testCase.verifyFalse(fans, 'Fans should turn off below 55 C');
        end
    end
end
