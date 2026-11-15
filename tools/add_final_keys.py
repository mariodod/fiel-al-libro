from pathlib import Path

p = Path("locale/messages.pot")
content = p.read_text(encoding="utf-8")

# Add missing keys at the end, matching the existing format with literal \\n
new_keys = [
    '\\n#. META: namespace=ui\\nmsgid "ui.venture.duelo_luz_luna"\\nmsgstr ""\\n',
    '\\n#. META: namespace=ui\\nmsgid "ui.venture.leones_carro"\\nmsgstr ""\\n',
    '\\n#. META: namespace=ui\\nmsgid "ui.venture.caballero_blanco"\\nmsgstr ""\\n',
]

content = content.rstrip('\\n') + ''.join(new_keys) + '\n'
p.write_text(content, encoding="utf-8")
print("Added 3 missing keys")

# Verify
content2 = p.read_text(encoding="utf-8")
for key in ['ui.venture.galeotes', 'ui.venture.duelo_luz_luna', 'ui.venture.leones_carro', 'ui.venture.caballero_blanco']:
    if key in content2:
        print(f"FOUND: {key}")
    else:
        print(f"MISSING: {key}")
