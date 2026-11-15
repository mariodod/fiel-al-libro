from pathlib import Path

p = Path("locale/messages.pot")
content = p.read_text(encoding="utf-8")

# Extract all existing msgid keys
existing_keys = set()
for line in content.split('\n'):
    stripped = line.strip()
    if stripped.startswith('msgid "') and stripped.endswith('"'):
        key = stripped[7:-1]  # Remove 'msgid "' and '"'
        if key:
            existing_keys.add(key)

# Keys we need to add
new_keys = [
    'ui.venture.galeotes',
    'ui.venture.duelo_luz_luna',
    'ui.venture.leones_carro',
    'ui.venture.caballero_blanco'
]

# Check which are missing
missing = [k for k in new_keys if k not in existing_keys]

if missing:
    print(f"Missing keys: {missing}")
    # Build new key entries
    new_entries = []
    for key in missing:
        new_entries.append('#. META: namespace=ui')
        new_entries.append(f'msgid "{key}"')
        new_entries.append('msgstr ""')
        new_entries.append('')
    
    # Add new keys at the end of the file
    content = content.rstrip('\n')
    if content and not content.endswith('\n'):
        content += '\n'
    
    content = content + '\n'.join(new_entries) + '\n'
    
    p.write_text(content, encoding="utf-8")
    print(f"Added {len(missing)} new keys to messages.pot")
else:
    print("All keys already present")

# Verify
content2 = p.read_text(encoding="utf-8")
for key in ['ui.venture.galeotes', 'ui.venture.duelo_luz_luna', 'ui.venture.leones_carro', 'ui.venture.caballero_blanco']:
    if key in content2:
        print(f"FOUND: {key}")
    else:
        print(f"MISSING: {key}")
