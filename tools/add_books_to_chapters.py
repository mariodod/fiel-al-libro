#!/usr/bin/env python3
"""
Add book truth object nodes to chapter .tscn scenes for chapters ch_15–ch_50.
Each chapter gets its fragment's book object placed in the scene.
"""

from pathlib import Path
import re

CHAPTERS_DIR = Path("src/world/chapters")
BOOKS_DIR = Path("src/data/primitives")

# Chapter -> fragment mapping (fragment_id, slug, position_x, position_z)
# Position is where the book object will be placed in the scene
CHAPTER_BOOKS = {
    "ch_15_muerto_camino": ("bk.ch15.muerto_camino.01", "muerto_camino", -30, -30),
    "ch_16_barca_encantada": ("bk.ch16.barca_encantada.01", "barca_encantada", -40, -20),
    "ch_17_hombre_muerto": ("bk.ch17.hombre_muerto.01", "hombre_muerto", -50, -10),
    "ch_18_libros_quemados": ("bk.ch18.libros_quemados.01", "libros_quemados", -30, -10),
    "ch_20_dulcinea_encantada": ("bk.ch20.dulcinea_encantada.01", "dulcinea_encantada", -20, -30),
    "ch_22_duelo_luz_luna": ("bk.ch22.duelo_luz_luna.01", "duelo_luz_luna", -10, -40),
    "ch_23_montesinos": ("bk.ch23.montesinos.01", "montesinos", 0, -50),
    "ch_24_altisidora": ("bk.ch24.altisidora.01", "altisidora", 10, -40),
    "ch_25_conde_altisidora": ("bk.ch25.conde_altisidora.01", "conde_altisidora", 20, -30),
    "ch_26_melisendra": ("bk.ch26.melisendra.01", "melisendra", 30, -20),
    "ch_27_molinos_llenadores": ("bk.ch27.molinos_llenadores.01", "molinos_llenadores", 40, -10),
    "ch_28_encantada": ("bk.ch28.encantada.01", "encantada", 50, 0),
    "ch_29_penitentes": ("bk.ch29.penitentes.01", "penitentes", 40, 10),
    "ch_30_leones_carro": ("bk.ch30.leones_carro.01", "leones_carro", 30, 20),
    "ch_31_cueva_hermoso": ("bk.ch31.cueva_hermoso.01", "cueva_hermoso", 20, 30),
    "ch_32_ventura_duque": ("bk.ch32.ventura_duque.01", "ventura_duque", 10, 40),
    "ch_33_leones_reales": ("bk.ch33.leones_reales.01", "leones_reales", 0, 50),
    "ch_34_encantamiento": ("bk.ch34.encantamiento.01", "encantamiento", -10, 40),
    "ch_35_caballero_blanco": ("bk.ch35.caballero_blanco.01", "caballero_blanco", -20, 30),
    "ch_36_cuidado_sancho": ("bk.ch36.cuidado_sancho.01", "cuidado_sancho", -30, 20),
    "ch_37_encantamiento_duquesa": ("bk.ch37.encantamiento_duquesa.01", "encantamiento_duquesa", -40, 10),
    "ch_38_clavileño": ("bk.ch38.clavileño.01", "clavileño", -50, 0),
    "ch_39_sancho_gobernador": ("bk.ch39.sancho_gobernador.01", "sancho_gobernador", -50, -10),
    "ch_40_entierro_rico": ("bk.ch40.entierro_rico.01", "entierro_rico", -40, -20),
    "ch_41_oviedo": ("bk.ch41.oviedo.01", "oviedo", -30, -30),
    "ch_42_maestro_pedro": ("bk.ch42.maestro_pedro.01", "maestro_pedro", -20, -40),
    "ch_43_caso_penal": ("bk.ch43.caso_penal.01", "caso_penal", -10, -50),
    "ch_44_duelo_evitados": ("bk.ch44.duelo_evitados.01", "duelo_evitados", 0, -50),
    "ch_45_encantamiento_sancho": ("bk.ch45.encantamiento_sancho.01", "encantamiento_sancho", 10, -40),
    "ch_46_leones_corte": ("bk.ch46.leones_corte.01", "leones_corte", 20, -30),
    "ch_47_despedida": ("bk.ch47.despedida.01", "despedida", 30, -20),
    "ch_48_regreso_pueblo": ("bk.ch48.regreso_pueblo.01", "regreso_pueblo", 40, -10),
    "ch_50_impertinente": ("bk.ch50.impertinente.01", "impertinente", 50, 0),
}

def find_max_id(tscn_content):
    """Find the highest ext_resource id in the .tscn file."""
    max_id = 0
    for line in tscn_content.split('\n'):
        match = re.match(r'\[ext_resource type=".+" id="(\d+)_', line)
        if match:
            max_id = max(max_id, int(match.group(1)))
    return max_id

def find_last_ext_resource_line(lines):
    """Find the line number of the last ext_resource entry."""
    last_idx = -1
    for i, line in enumerate(lines):
        if line.startswith('[ext_resource'):
            last_idx = i
    return last_idx

def find_first_node_line(lines):
    """Find the line number of the first [node entry."""
    for i, line in enumerate(lines):
        if line.startswith('[node'):
            return i
    return -1

def add_book_to_tscn(tscn_path, fragment_id, slug, pos_x, pos_z):
    """Add a book truth object to a chapter .tscn scene."""
    content = tscn_path.read_text()
    
    # Check if book already exists
    if f"book_{fragment_id}.tres" in content or f"Book_{slug.capitalize()}" in content:
        print(f"  SKIP (already has book): {tscn_path.name}")
        return False
    
    max_id = find_max_id(content)
    new_id = max_id + 1
    
    # Create ext_resource line
    ext_resource_line = f'[ext_resource type="Resource" path="res://src/data/primitives/book_{fragment_id}.tres" id="{new_id}_book_{slug}"]'
    
    # Create node lines
    node_lines = [
        f'[node name="Book_{slug.capitalize()}" type="Node3D" parent="."]',
        f'transform = Transform3D(1, 0, 0, 0, 1, {pos_x}, 0, {pos_z})',
        f'script = ExtResource("2_object")',
        f'data = ExtResource("{new_id}_book_{slug}")',
        ''
    ]
    
    lines = content.split('\n')
    
    # Insert ext_resource after the last ext_resource entry
    last_ext_idx = find_last_ext_resource_line(lines)
    lines.insert(last_ext_idx + 1, ext_resource_line)
    
    # Insert node before the first node entry
    first_node_idx = find_first_node_line(lines)
    # Adjust for the inserted ext_resource line
    first_node_idx += 1
    for i, line in enumerate(node_lines):
        lines.insert(first_node_idx + i, line)
    
    tscn_path.write_text('\n'.join(lines))
    print(f"  ADDED book to {tscn_path.name} (id={new_id})")
    return True

def main():
    count = 0
    for chapter_name, (fragment_id, slug, pos_x, pos_z) in CHAPTER_BOOKS.items():
        tscn_path = CHAPTERS_DIR / f"{chapter_name}.tscn"
        if not tscn_path.exists():
            print(f"MISSING: {tscn_path}")
            continue
        
        book_tres = Path(f"src/data/primitives/book_{fragment_id}.tres")
        if not book_tres.exists():
            print(f"MISSING tres: {book_tres}")
            continue
        
        if add_book_to_tscn(tscn_path, fragment_id, slug, pos_x, pos_z):
            count += 1
    
    print(f"\nAdded book objects to {count} chapter scenes")

if __name__ == "__main__":
    main()
