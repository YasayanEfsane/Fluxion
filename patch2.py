import os

app_file = r'C:\Users\yusuf\.gemini\antigravity\scratch\Fluxion\app\FluxionApp.m'

with open(app_file, 'r', encoding='utf-8') as f:
    app_code = f.read()

old_str = "title(app.UIAxes, 'Thermal Heating Curve (Real Data)');"
new_str = """[V_st, ~] = tx.agingModel(app.results.thermal_history.hs(end), 1);
                        exp_life = 30 / V_st;
                        title(app.UIAxes, sprintf('Thermal Heating Curve (RUL: %.1f Years)', exp_life));"""
app_code = app_code.replace(old_str, new_str)

with open(app_file, 'w', encoding='utf-8') as f:
    f.write(app_code)

print('Updated FluxionApp.m embedded plot title')
