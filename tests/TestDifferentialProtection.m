classdef TestDifferentialProtection < matlab.unittest.TestCase
    
    methods (Test)
        function testNormalOperationNoTrip(testCase)
            import tx.*
            protConfig = defaultProtectionConfig();
            
            relay = differentialProtection(protConfig);
            
            % Simulate 3 cycles of normal nominal load
            t = 0:(1/protConfig.fs):0.06;
            
            % Primary current (Delta)
            I1_mag = protConfig.I1n;
            i1 = [I1_mag * cos(2*pi*50*t);
                  I1_mag * cos(2*pi*50*t - 2*pi/3);
                  I1_mag * cos(2*pi*50*t + 2*pi/3)];
                  
            % Secondary current (Star)
            % Dyn11 means secondary leads primary by 30 degrees (if Delta leads Star)
            % Delta is usually HV (ABC).
            % Actually, it depends on exact definitions, let's just make Idiff 0
            % by forcing the secondary current to perfectly match the compensated primary.
            I2_mag = protConfig.I2n;
            i2 = [I2_mag * cos(2*pi*50*t - pi/6 + pi); % +pi because it's entering the other side
                  I2_mag * cos(2*pi*50*t - 2*pi/3 - pi/6 + pi);
                  I2_mag * cos(2*pi*50*t + 2*pi/3 - pi/6 + pi)];
            
            for k = 1:length(t)
                [trip, Idiff, Irest, reason] = relay.step(i1(:,k), i2(:,k));
            end
            
            testCase.verifyFalse(trip, 'Relay should not trip under normal load');
            testCase.verifyLessThan(Idiff(1), 0.1, 'Differential current should be near zero');
        end
        
        function testInternalFaultTrip(testCase)
            import tx.*
            protConfig = defaultProtectionConfig();
            
            relay = differentialProtection(protConfig);
            
            t = 0:(1/protConfig.fs):0.06;
            
            % Internal fault: current only from primary, secondary is zero
            I1_mag = 5 * protConfig.I1n;
            i1 = [I1_mag * cos(2*pi*50*t);
                  I1_mag * cos(2*pi*50*t - 2*pi/3);
                  I1_mag * cos(2*pi*50*t + 2*pi/3)];
            i2 = zeros(3, length(t));
            
            trip = false;
            for k = 1:length(t)
                [trip, Idiff, Irest, reason] = relay.step(i1(:,k), i2(:,k));
            end
            
            testCase.verifyTrue(trip, 'Relay should trip under internal fault');
        end
    end
end
