from pathlib import Path

p = Path("locale/messages.pot")
content = p.read_text(encoding="utf-8")

# Add missing keys at the end of the file (before the final empty line if any)
new_keys = [
    '#. META: namespace=ui',
    'msgid "ui.venture.duelo_luz_luna"',
    'msgstr ""',
    '',
    '#. META: namespace=ui',
    'msgid "ui.venture.leones_carro"',
    'msgstr ""',
    '',
    '#. META: namespace=ui',
    'msgid "ui.venture.caballero_blanco"',
    'msgstr ""',
    '',
]

content = content.rstrip() + "\n" + "\n".join(new_keys) + "\n"
p.write_text(content, encoding="utf-8")
print("Added 3 missing keys")
