import os

app_file = r'C:\Users\yusuf\.gemini\antigravity\scratch\Fluxion\app\FluxionApp.m'
plots_file = r'C:\Users\yusuf\.gemini\antigravity\scratch\Fluxion\scenarios\generateAllPlots.m'

with open(app_file, 'r', encoding='utf-8') as f:
    app_code = f.read()

# Replace line 177 in app
old_app_str = "app.LogArea.Value = [app.LogArea.Value; {sprintf('Steady Hot-Spot Temperature: %.1f C', hs)}];"
new_app_str = """[V_steady, ~] = tx.agingModel(hs, 1);
                    expected_life_years = 30 / V_steady;
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Steady Hot-Spot Temperature: %.1f C', hs)}];
                    app.LogArea.Value = [app.LogArea.Value; {sprintf('Loss of Life Factor (V): %.2f -> Expected RUL: %.1f years', V_steady, expected_life_years)}];"""
app_code = app_code.replace(old_app_str, new_app_str)

with open(app_file, 'w', encoding='utf-8') as f:
    f.write(app_code)


with open(plots_file, 'r', encoding='utf-8') as f:
    plots_code = f.read()

old_plot_str = r"title('Thermal Heating Curve'); xlabel('Time (min)'); ylabel('Temperature (\circC)');"
new_plot_str = r"""[V_steady, ~] = tx.agingModel(hs_arr(end), 1);
expected_life = 30 / V_steady;
title(sprintf('Thermal Heating Curve (Expected RUL: %.1f Years)', expected_life));
xlabel('Time (min)'); ylabel('Temperature (\circC)');"""
plots_code = plots_code.replace(old_plot_str, new_plot_str)

with open(plots_file, 'w', encoding='utf-8') as f:
    f.write(plots_code)

print('Updated both files.')
