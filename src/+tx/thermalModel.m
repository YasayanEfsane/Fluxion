classdef thermalModel < handle
    % thermalModel IEC 60076-7 Dynamic Thermal Model for Power Transformers
    %
    % Calculates top-oil and hot-spot temperatures dynamically.
    % Handles ONAN/ONAF cooling mode switching with hysteresis.
    
    properties
        % Transformer Thermal Parameters
        dTopOiln        % Rated top-oil temperature rise [K]
        dHotSpotn       % Rated hot-spot temperature rise over top-oil [K]
        R               % Ratio of load losses to no-load losses
        tau_oil         % Oil time constant [min]
        tau_wdg         % Winding time constant [min]
        x               % Oil exponent
        y               % Winding exponent
        
        % Cooling limits (ONAN -> ONAF)
        fan_on_temp     % Top-oil temp to turn fans ON
        fan_off_temp    % Top-oil temp to turn fans OFF
        
        % State
        theta_top_oil   % Current top-oil temp
        d_theta_hot_spot % Current hot-spot temp rise over top-oil
        fans_on         % boolean
    end
    
    methods
        function obj = thermalModel(config, Tamb_initial)
            if nargin < 2
                Tamb_initial = 25;
            end
            
            obj.dTopOiln = config.dTopOiln;
            obj.dHotSpotn = config.dHotSpotn;
            
            % Default IEC parameters for ONAN/ONAF medium transformers
            obj.R = config.Pcu / config.P0;
            obj.tau_oil = 150; % minutes
            obj.tau_wdg = 5;   % minutes
            obj.x = 0.8;
            obj.y = 1.6;
            
            obj.fan_on_temp = 65;
            obj.fan_off_temp = 55;
            
            % Initial conditions
            obj.theta_top_oil = Tamb_initial;
            obj.d_theta_hot_spot = 0;
            obj.fans_on = false;
        end
        
        function [theta_oil, theta_hs, fans] = step(obj, K, Tamb, dt_min)
            % step Solves one time step for the thermal model
            % K: Load factor (I_load / I_rated)
            % Tamb: Ambient temperature [deg C]
            % dt_min: Time step in minutes
            
            % 1. Check cooling mode
            if ~obj.fans_on && obj.theta_top_oil >= obj.fan_on_temp
                obj.fans_on = true;
                obj.x = 0.9; % Exponent changes slightly with forced air
                obj.y = 1.6;
            elseif obj.fans_on && obj.theta_top_oil <= obj.fan_off_temp
                obj.fans_on = false;
                obj.x = 0.8;
                obj.y = 1.6;
            end
            
            % 2. Calculate ultimate top-oil temperature rise
            % dTheta_oil_ult = dTopOiln * ((1 + R*K^2)/(1 + R))^x
            dTheta_oil_ult = obj.dTopOiln * ((1 + obj.R * K^2) / (1 + obj.R))^obj.x;
            
            % Differential equation for top-oil
            % d(dTheta_oil)/dt = (dTheta_oil_ult - dTheta_oil) / tau_oil
            current_dTheta_oil = obj.theta_top_oil - Tamb; % Approximate
            rate_oil = (dTheta_oil_ult - current_dTheta_oil) / obj.tau_oil;
            new_dTheta_oil = current_dTheta_oil + rate_oil * dt_min;
            obj.theta_top_oil = Tamb + new_dTheta_oil;
            
            % 3. Calculate ultimate hot-spot temperature rise
            % dTheta_hs_ult = dHotSpotn * (K^y)
            dTheta_hs_ult = obj.dHotSpotn * (K^obj.y);
            
            % Differential equation for hot-spot rise over top-oil
            rate_hs = (dTheta_hs_ult - obj.d_theta_hot_spot) / obj.tau_wdg;
            obj.d_theta_hot_spot = obj.d_theta_hot_spot + rate_hs * dt_min;
            
            theta_hs = obj.theta_top_oil + obj.d_theta_hot_spot;
            theta_oil = obj.theta_top_oil;
            fans = obj.fans_on;
        end
    end
end
