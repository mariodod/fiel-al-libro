from pathlib import Path

p = Path("locale/messages.pot")
content = p.read_text(encoding="utf-8")

# Fix all malformed keys - the file has literal backslash-n sequences
content = content.replace('msgid " ui.venture.galeotes\\', 'msgid "ui.venture.galeotes"')
content = content.replace('msgid " ui.venture.duelo_luz_luna\\', 'msgid "ui.venture.duelo_luz_luna"')
content = content.replace('msgid " ui.venture.leones_carro\\', 'msgid "ui.venture.leones_carro"')
content = content.replace('msgid " ui.venture.caballero_blanco\\', 'msgid "ui.venture.caballero_blanco"')

p.write_text(content, encoding="utf-8")
print("Fixed keys")
