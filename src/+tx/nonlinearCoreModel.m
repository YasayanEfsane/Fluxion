classdef nonlinearCoreModel < handle
    % nonlinearCoreModel Physics-based nonlinear transformer core model
    %
    % This model implements a simplified dynamic hysteresis model based on
    % the Tellinen approach, extended with eddy current losses. It is chosen
    % because it provides explicit calculation of H from B and dB/dt, which
    % avoids the stiffness and non-convergence issues often associated with 
    % the Jiles-Atherton model in time-domain ODE solvers.
    % 
    % Features:
    % - Saturation (via anhysteretic B-H curve)
    % - Hysteresis loop (Tellinen type)
    % - Core loss (Eddy current + Hysteresis)
    % - Residual flux initialization
    
    properties
        bh_curve_data  % Table with H_A_m and B_T
        Acore          % Core cross-sectional area [m^2]
        lcore          % Core magnetic length [m]
        N              % Number of turns (primary side reference)
        Hc             % Coercive force [A/m]
        k_eddy         % Eddy current loss coefficient
        
        % State variables
        B_prev
        H_prev
        t_prev
    end
    
    methods
        function obj = nonlinearCoreModel(bh_file, Acore, lcore, N, Hc, k_eddy, B_residual)
            if nargin < 7
                B_residual = 0;
            end
            if nargin < 6
                k_eddy = 0.1;
            end
            if nargin < 5
                Hc = 20; % Default coercive force A/m
            end
            
            obj.bh_curve_data = readtable(bh_file);
            obj.Acore = Acore;
            obj.lcore = lcore;
            obj.N = N;
            obj.Hc = Hc;
            obj.k_eddy = k_eddy;
            
            obj.B_prev = B_residual;
            obj.H_prev = obj.getAnhystereticH(B_residual);
            obj.t_prev = 0;
        end
        
        function H_an = getAnhystereticH(obj, B)
            % Shape-preserving interpolation for the anhysteretic curve
            % Extrapolation is linear to avoid wild values in deep saturation
            H_an = interp1(obj.bh_curve_data.B_T, obj.bh_curve_data.H_A_m, B, 'linear', 'extrap');
        end
        
        function [i_mag, H, dBdt] = step(obj, v, dt)
            % step Solves one time step for the core model
            % Inputs:
            %   v : Applied voltage [V] (can be v = N * dPhi/dt)
            %   dt: Time step [s]
            % Outputs:
            %   i_mag: Magnetizing current [A]
            %   H: Magnetic field intensity [A/m]
            %   dBdt: Rate of change of flux density [T/s]
            
            % v = N * A * dB/dt  => dB/dt = v / (N * A)
            dBdt = v / (obj.N * obj.Acore);
            
            % Update B
            B_current = obj.B_prev + dBdt * dt;
            
            % Anhysteretic H
            H_an = obj.getAnhystereticH(B_current);
            
            % Hysteresis component (simplified Tellinen / Widening logic)
            % H(B) = H_an(B) + Hc * sign(dBdt)
            % To avoid discontinuity at dBdt=0, we can use a smoothed sign function
            % but for physical ODE solving, a dynamic approach is better.
            % Let's use a relaxation towards the major loop.
            
            if abs(dBdt) > 1e-6
                dir = sign(dBdt);
                H_hyst = H_an + dir * obj.Hc;
            else
                % If no voltage, hold previous H to avoid generating artificial energy
                H_hyst = obj.H_prev;
            end
            
            % Eddy current component (frequency dependent loss)
            % H_eddy = k_eddy * dB/dt
            H_eddy = obj.k_eddy * dBdt;
            
            % Total H
            H = H_hyst + H_eddy;
            
            % Current calculation: H * lcore = N * i
            i_mag = (H * obj.lcore) / obj.N;
            
            % Update states
            obj.B_prev = B_current;
            obj.H_prev = H;
        end
        
        function [phi] = getFlux(obj)
            phi = obj.B_prev * obj.Acore;
        end
        
        function resetState(obj, B_residual)
            obj.B_prev = B_residual;
            obj.H_prev = obj.getAnhystereticH(B_residual);
        end
    end
end
