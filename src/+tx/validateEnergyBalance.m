function isBalanced = validateEnergyBalance(v_in, i_in, v_out, i_out, dt)
% validateEnergyBalance Checks if energy is conserved in the digital twin
%
% Integrates Pin and Pout over time and compares with expected losses.

P_in = sum(v_in .* i_in, 1); % Instantaneous input power
P_out = sum(v_out .* i_out, 1); % Instantaneous output power

E_in = sum(P_in) * dt;
E_out = sum(P_out) * dt;

E_loss = E_in - E_out;

% The difference should ideally be equal to core + copper losses + stored magnetic energy.
% For a simple validation, E_loss must be >= 0 (passive system check).
% And shouldn't be excessively large compared to E_in (e.g. > 20% implies very low efficiency).

if E_loss < -1e-3
    warning('Energy balance violated: System is generating artificial energy!');
    isBalanced = false;
elseif E_loss > 0.5 * E_in
    warning('Energy balance violated: Unrealistic losses (>50%).');
    isBalanced = false;
else
    isBalanced = true;
end

end
