#!/usr/bin/env python3
"""
Add missing locale keys to messages.pot for the new book fragments.
"""

from pathlib import Path

POT_PATH = Path("locale/messages.pot")

# All fragments that need locale keys (ch_15–ch_50)
FRAGMENT_IDS = [
    "bk.ch15.muerto_camino.01",
    "bk.ch16.barca_encantada.01",
    "bk.ch17.hombre_muerto.01",
    "bk.ch18.libros_quemados.01",
    "bk.ch20.dulcinea_encantada.01",
    "bk.ch22.duelo_luz_luna.01",
    "bk.ch23.montesinos.01",
    "bk.ch24.altisidora.01",
    "bk.ch25.conde_altisidora.01",
    "bk.ch26.melisendra.01",
    "bk.ch27.molinos_llenadores.01",
    "bk.ch28.encantada.01",
    "bk.ch29.penitentes.01",
    "bk.ch30.leones_carro.01",
    "bk.ch31.cueva_hermoso.01",
    "bk.ch32.ventura_duque.01",
    "bk.ch33.leones_reales.01",
    "bk.ch34.encantamiento.01",
    "bk.ch35.caballero_blanco.01",
    "bk.ch36.cuidado_sancho.01",
    "bk.ch37.encantamiento_duquesa.01",
    "bk.ch38.clavileño.01",
    "bk.ch39.sancho_gobernador.01",
    "bk.ch40.entierro_rico.01",
    "bk.ch41.oviedo.01",
    "bk.ch42.maestro_pedro.01",
    "bk.ch43.caso_penal.01",
    "bk.ch44.duelo_evitados.01",
    "bk.ch45.encantamiento_sancho.01",
    "bk.ch46.leones_corte.01",
    "bk.ch47.despedida.01",
    "bk.ch48.regreso_pueblo.01",
    "bk.ch50.impertinente.01",
]

def read_existing_keys(pot_path):
    """Read existing msgids from the POT file."""
    keys = set()
    with open(pot_path, 'r', encoding='utf-8') as f:
        content = f.read()
    # Find all msgid lines
    import re
    for match in re.finditer(r'^msgid "([^"]*)"$', content, re.MULTILINE):
        key = match.group(1)
        if key:  # Skip empty msgid ""
            keys.add(key)
    return keys

def generate_missing_keys(existing_keys):
    """Generate missing locale keys for all fragments."""
    new_keys = []
    
    for frag_id in FRAGMENT_IDS:
        keys = [
            f'ui.face.{frag_id}.reality.desc',
            f'ui.face.{frag_id}.reality.tell',
            f'ui.face.{frag_id}.book.desc',
            f'ui.face.{frag_id}.book.tell',
            f'ui.book.{frag_id}.name',
        ]
        for key in keys:
            if key not in existing_keys:
                new_keys.append(key)
    
    return new_keys

def add_keys_to_pot(pot_path, new_keys):
    """Add new keys to the POT file before the first msgid entry."""
    with open(pot_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find the first msgid line to insert before it
    import re
    match = re.search(r'^msgid "', content, re.MULTILINE)
    if not match:
        print("ERROR: No msgid lines found in POT file")
        return 0
    
    insert_pos = match.start()
    
    # Build new key entries with proper formatting
    new_entries = []
    for key in sorted(new_keys):
        new_entries.append(f'#. META: namespace=ui')
        new_entries.append(f'msgid "{key}"')
        new_entries.append('msgstr ""')
        new_entries.append('')
    
    # Insert before the first msgid
    new_content = content[:insert_pos] + '\n'.join(new_entries) + '\n' + content[insert_pos:]
    
    with open(pot_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    return len(new_keys)

def main():
    existing_keys = read_existing_keys(POT_PATH)
    print(f"Existing keys in messages.pot: {len(existing_keys)}")
    
    new_keys = generate_missing_keys(existing_keys)
    print(f"Missing keys to add: {len(new_keys)}")
    
    if new_keys:
        count = add_keys_to_pot(POT_PATH, new_keys)
        print(f"Added {count} new keys to messages.pot")
    else:
        print("No new keys to add")

if __name__ == "__main__":
    main()
