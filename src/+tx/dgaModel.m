classdef dgaModel < handle
    % dgaModel Implements the IEC 60599 Duval Triangle 1 for Transformer DGA
    
    methods (Static)
        function [zone, desc, pct] = diagnose(CH4, C2H4, C2H2)
            total = CH4 + C2H4 + C2H2;
            if total == 0
                zone = ''Normal'';
                desc = ''Not enough gas for diagnosis'';
                pct = [0, 0, 0];
                return;
            end
            
            x = (CH4 / total) * 100;
            y = (C2H4 / total) * 100;
            z = (C2H2 / total) * 100;
            pct = [x, y, z];
            
            % Duval Triangle 1 exact logical boundaries
            if x >= 98
                zone = ''PD'';
                desc = ''Partial Discharge'';
            elseif z < 4 && y < 20 && x < 98
                zone = ''T1'';
                desc = ''Thermal Fault < 300 C'';
            elseif z < 4 && y >= 20 && y < 50
                zone = ''T2'';
                desc = ''Thermal Fault 300-700 C'';
            elseif z < 15 && y >= 50
                zone = ''T3'';
                desc = ''Thermal Fault > 700 C'';
            elseif z >= 15 && y >= 50
                zone = ''DT'';
                desc = ''Mix of Thermal and Electrical Fault'';
            elseif z >= 4 && z < 13 && y >= 40 && y < 50
                zone = ''DT'';
                desc = ''Mix of Thermal and Electrical Fault'';
            elseif z >= 13 && z <= 29 && y >= 40 && y < 50
                zone = ''D2'';
                desc = ''High Energy Discharge'';
            elseif z >= 29 && y >= 23 && y < 50
                zone = ''D2'';
                desc = ''High Energy Discharge'';
            elseif z >= 13 && z <= 29 && y >= 23 && y < 40
                zone = ''D2'';
                desc = ''High Energy Discharge'';
            elseif z >= 13 && y < 23
                zone = ''D1'';
                desc = ''Low Energy Discharge'';
            elseif z >= 4 && z < 13 && y < 40
                zone = ''D1'';
                desc = ''Low Energy Discharge'';
            else
                zone = ''DT'';
                desc = ''Mixed Faults'';
            end
        end
        
        function plotDuvalTriangle(ax, CH4, C2H4, C2H2)
            [~, desc, pct] = tx.dgaModel.diagnose(CH4, C2H4, C2H2);
            
            % Draw the triangle
            v_CH4 = [0, sqrt(3)/2];
            v_C2H4 = [1, 0];
            v_C2H2 = [-1, 0]; % actually standard triangle:
            % Let''s use Cartesian: C2H2=(0,0), C2H4=(100,0), CH4=(50, 100*sqrt(3)/2)
            
            vC2H2 = [0, 0];
            vC2H4 = [100, 0];
            vCH4 = [50, 86.6025];
            
            cla(ax);
            hold(ax, ''on'');
            
            % Plot outer triangle
            plot(ax, [vC2H2(1) vC2H4(1) vCH4(1) vC2H2(1)], [vC2H2(2) vC2H4(2) vCH4(2) vC2H2(2)], ''k'', ''LineWidth'', 2);
            
            % Map the point
            x_p = pct(3)*0 + pct(2)*1 + pct(1)*0.5;
            y_p = pct(3)*0 + pct(2)*0 + pct(1)*0.866025;
            
            scatter(ax, x_p, y_p, 150, ''rp'', ''filled'');
            text(ax, x_p+2, y_p+2, sprintf(''%s'', desc), ''Color'', ''r'', ''FontWeight'', ''bold'');
            
            % Labels
            text(ax, vCH4(1)-5, vCH4(2)+5, ''%CH4'', ''FontWeight'', ''bold'');
            text(ax, vC2H4(1)+2, vC2H4(2), ''%C2H4'', ''FontWeight'', ''bold'');
            text(ax, vC2H2(1)-10, vC2H2(2), ''%C2H2'', ''FontWeight'', ''bold'');
            
            title(ax, ''Duval Triangle 1 (DGA)'');
            axis(ax, ''off'');
            axis(ax, ''equal'');
            hold(ax, ''off'');
        end
    end
end