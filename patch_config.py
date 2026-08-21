import os

app_file = r'C:\Users\yusuf\.gemini\antigravity\scratch\Fluxion\config\defaultTransformerConfig.m'
with open(app_file, 'r', encoding='utf-8') as f:
    code = f.read()

new_str = """txConfig.dTopOiln = 55;      % Nominal top-oil temperature rise [K]
txConfig.dHotSpotn = 23;     % Nominal hot-spot to top-oil gradient [K]

% DGA (Dissolved Gas Analysis) defaults [ppm]
txConfig.dga_CH4 = 120;
txConfig.dga_C2H4 = 30;
txConfig.dga_C2H2 = 15;
"""
code = code.replace("txConfig.dTopOiln = 55;      % Nominal top-oil temperature rise [K]\ntxConfig.dHotSpotn = 23;     % Nominal hot-spot to top-oil gradient [K]", new_str)
with open(app_file, 'w', encoding='utf-8') as f:
    f.write(code)

print('updated config')
