classdef differentialProtection < handle
    % differentialProtection ANSI 87T percentage differential relay
    %
    % Features:
    % - Dyn11 Phase Shift and Zero-Sequence Compensation
    % - CT Ratio Correction
    % - Sliding Window Discrete Fourier Transform (DFT)
    % - Dual-Slope Characteristic
    % - 2nd Harmonic Restraint (Inrush)
    % - 5th Harmonic Restraint (Overexcitation)
    
    properties
        fs               % Sampling frequency [Hz]
        fn               % Nominal frequency [Hz]
        samplesPerCycle  % Number of samples per cycle
        
        % Protection Settings
        I_pickup         % Minimum pickup current [pu]
        Slope1           % Slope 1 [%/100]
        Slope2           % Slope 2 [%/100]
        Breakpoint       % Breakpoint between Slope 1 and Slope 2 [pu]
        HighSet          % Instantaneous high-set trip [pu]
        Harm2_Limit      % 2nd harmonic restraint limit [%/100]
        Harm5_Limit      % 5th harmonic restraint limit [%/100]
        TripConfirmSteps % Required consecutive trip steps to confirm trip
        
        % CT and Transformer Settings
        CT1_ratio
        CT2_ratio
        I1n              % Primary nominal current
        I2n              % Secondary nominal current
        
        % Internal State
        buffer_i1        % Sliding window buffer for primary current
        buffer_i2        % Sliding window buffer for secondary current
        idx              % Current index in buffer
        tripCounter      % Counter for consecutive trip conditions
        isTripped        % Final trip state
    end
    
    methods
        function obj = differentialProtection(config)
            % Initialize settings from config struct
            obj.fs = config.fs;
            obj.fn = config.fn;
            obj.samplesPerCycle = round(obj.fs / obj.fn);
            
            obj.I_pickup = config.I_pickup;
            obj.Slope1 = config.Slope1;
            obj.Slope2 = config.Slope2;
            obj.Breakpoint = config.Breakpoint;
            obj.HighSet = config.HighSet;
            obj.Harm2_Limit = config.Harm2_Limit;
            obj.Harm5_Limit = config.Harm5_Limit;
            obj.TripConfirmSteps = config.TripConfirmTime * obj.fs;
            
            obj.CT1_ratio = config.CT1_ratio;
            obj.CT2_ratio = config.CT2_ratio;
            obj.I1n = config.I1n;
            obj.I2n = config.I2n;
            
            % Initialize buffers (3 phases x samplesPerCycle)
            obj.buffer_i1 = zeros(3, obj.samplesPerCycle);
            obj.buffer_i2 = zeros(3, obj.samplesPerCycle);
            obj.idx = 1;
            obj.tripCounter = zeros(3, 1);
            obj.isTripped = false;
        end
        
        function [trip, Idiff, Irest, reasonCode] = step(obj, i1_raw, i2_raw)
            % step Processes one sample of 3-phase currents
            % i1_raw: Primary currents [Ia; Ib; Ic] in Amperes
            % i2_raw: Secondary currents [Ia; Ib; Ic] in Amperes
            
            % 1. CT Ratio and Base normalization (to per unit)
            i1_pu = (i1_raw / obj.CT1_ratio) / (obj.I1n / obj.CT1_ratio); 
            i2_pu = (i2_raw / obj.CT2_ratio) / (obj.I2n / obj.CT2_ratio);
            
            % 2. Phase Compensation for Dyn11
            % Primary is Delta (D), Secondary is Star (y)
            % We compensate by applying a delta connection mathematically on the star side
            % i2_comp_a = (i2_a - i2_b) / sqrt(3)
            i2_comp = zeros(3,1);
            i2_comp(1) = (i2_pu(1) - i2_pu(2)) / sqrt(3);
            i2_comp(2) = (i2_pu(2) - i2_pu(3)) / sqrt(3);
            i2_comp(3) = (i2_pu(3) - i2_pu(1)) / sqrt(3);
            
            % Also, zero sequence is trapped in delta, so zero sequence in star side 
            % is naturally eliminated by the delta subtraction above.
            i1_comp = i1_pu; % Primary delta current is already line current
            
            % Update sliding buffers
            obj.buffer_i1(:, obj.idx) = i1_comp;
            obj.buffer_i2(:, obj.idx) = i2_comp;
            obj.idx = mod(obj.idx, obj.samplesPerCycle) + 1;
            
            % 3. Sliding Window DFT (1-cycle)
            N = obj.samplesPerCycle;
            n = 0:(N-1);
            
            % Basis functions
            W1 = exp(-1j * 2 * pi * 1 * n / N);
            W2 = exp(-1j * 2 * pi * 2 * n / N);
            W5 = exp(-1j * 2 * pi * 5 * n / N);
            
            % Phasors (3 phases)
            I1_fund = (2/N) * (obj.buffer_i1 * W1.');
            I2_fund = (2/N) * (obj.buffer_i2 * W1.');
            
            I1_2nd = (2/N) * (obj.buffer_i1 * W2.');
            I2_2nd = (2/N) * (obj.buffer_i2 * W2.');
            
            I1_5th = (2/N) * (obj.buffer_i1 * W5.');
            I2_5th = (2/N) * (obj.buffer_i2 * W5.');
            
            % 4. Calculate Differential and Restraining Currents
            % Idiff = |I1 + I2|  (assuming currents enter the transformer)
            I_diff_phasor = I1_fund + I2_fund;
            Idiff = abs(I_diff_phasor);
            
            % Irest = (|I1| + |I2|) / 2 (average restraining)
            Irest = (abs(I1_fund) + abs(I2_fund)) / 2;
            
            % Harmonic currents for restraint (sum of magnitudes)
            I_2nd_mag = abs(I1_2nd + I2_2nd);
            I_5th_mag = abs(I1_5th + I2_5th);
            
            % 5. Protection Logic per phase
            trip_inst = false(3,1);
            reasonCode = cell(3,1);
            
            for p = 1:3
                % High-set instantaneous trip
                if Idiff(p) > obj.HighSet
                    trip_inst(p) = true;
                    reasonCode{p} = 'HighSet';
                    continue;
                end
                
                % Harmonic Restraint
                if (I_2nd_mag(p) / (Idiff(p) + 1e-6)) > obj.Harm2_Limit
                    reasonCode{p} = 'Inrush_Restraint';
                    continue;
                end
                
                if (I_5th_mag(p) / (Idiff(p) + 1e-6)) > obj.Harm5_Limit
                    reasonCode{p} = 'Overexcitation_Restraint';
                    continue;
                end
                
                % Dual-Slope Characteristic
                if Idiff(p) < obj.I_pickup
                    reasonCode{p} = 'Normal';
                    continue;
                end
                
                if Irest(p) <= obj.Breakpoint
                    if Idiff(p) > obj.Slope1 * Irest(p)
                        trip_inst(p) = true;
                        reasonCode{p} = 'Zone1_Trip';
                    else
                        reasonCode{p} = 'Normal';
                    end
                else
                    % Slope 2 line eq: Idiff = (Irest - Breakpoint)*Slope2 + Slope1*Breakpoint
                    limit2 = (Irest(p) - obj.Breakpoint) * obj.Slope2 + obj.Slope1 * obj.Breakpoint;
                    if Idiff(p) > limit2
                        trip_inst(p) = true;
                        reasonCode{p} = 'Zone2_Trip';
                    else
                        reasonCode{p} = 'Normal';
                    end
                end
            end
            
            % Trip confirmation (delay to avoid noise trips)
            for p = 1:3
                if trip_inst(p)
                    obj.tripCounter(p) = obj.tripCounter(p) + 1;
                else
                    obj.tripCounter(p) = 0;
                end
            end
            
            if any(obj.tripCounter >= obj.TripConfirmSteps)
                obj.isTripped = true;
            end
            
            trip = obj.isTripped;
        end
    end
end
