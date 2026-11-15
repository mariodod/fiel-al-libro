#!/usr/bin/env python3
"""
Remove duplicate msgid entries from PO files, keeping the first occurrence.
Handles the case where duplicate msgid lines may have msgstr lines after them.
"""

from pathlib import Path
import re

PO_FILES = [
    Path("locale/de.po"),
    Path("locale/it.po"),
    Path("locale/pt_BR.po"),
    Path("locale/fr.po"),
]

def remove_duplicates(po_path):
    with open(po_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    lines = content.split('\n')
    new_lines = []
    seen_keys = set()
    skip_next = False
    
    for line in lines:
        if skip_next:
            # Skip the msgstr line that follows a duplicate msgid
            skip_next = False
            continue
        
        # Check if this line is a msgid
        stripped = line.strip()
        if stripped.startswith('msgid "') and stripped.endswith('"'):
            key = stripped[7:-1]  # Remove 'msgid "' and '"'
            if key in seen_keys:
                skip_next = True  # Skip this msgid and the following msgstr
                continue
            seen_keys.add(key)
        
        new_lines.append(line)
    
    with open(po_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_lines))
    
    print(f"Cleaned {po_path.name}")

def main():
    for po_file in PO_FILES:
        remove_duplicates(po_file)

if __name__ == "__main__":
    main()
