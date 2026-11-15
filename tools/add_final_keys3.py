from pathlib import Path
import re

p = Path("locale/messages.pot")
content = p.read_text(encoding="utf-8")

# Extract all existing msgid keys
existing_keys = set()
for line in content.split('\n'):
    stripped = line.strip()
    if stripped.startswith('msgid "') and stripped.endswith('"'):
        key = stripped[7:-1]
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
    
    # Read current content
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find the last msgid line and add new keys after it
    lines = content.split('\n')
    last_msgid_idx = -1
    for i, line in enumerate(lines):
        if line.strip().startswith('msgid "') and line.strip().endswith('"'):
            last_msgid_idx = i
    
    # Insert new keys after the last msgid block
    insert_pos = last_msgid_idx + 1
    # Skip any trailing blank lines after the last msgstr
    while insert_pos < len(lines) and lines[insert_pos].strip() == '':
        insert_pos += 1
    
    for i, entry in enumerate(new_entries):
        lines.insert(insert_pos + i, entry)
    
    content = '\n'.join(lines)
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
