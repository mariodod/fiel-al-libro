#!/usr/bin/env python3
"""
Generate region_graph.tres additions for chapters ch_14-ch_50,
locale keys for new fragments, and venture data for combat chapters.
"""

# Chapter → (region_id, chapter_number, fragment_id, is_combat, next_chapter)
CHAPTERS = [
    ("ch_14_galeotes", "camino_la_mancha", 14, "bk.ch14.galeotes.01", False, "ch_15_muerto_camino"),
    ("ch_15_muerto_camino", "camino_la_mancha", 15, "bk.ch15.muerto_camino.01", False, "ch_16_barca_encantada"),
    ("ch_16_barca_encantada", "camino_la_mancha", 16, "bk.ch16.barca_encantada.01", False, "ch_17_hombre_muerto"),
    ("ch_17_hombre_muerto", "sierra_morena", 17, "bk.ch17.hombre_muerto.01", False, "ch_18_libros_quemados"),
    ("ch_18_libros_quemados", "sierra_morena", 18, "bk.ch18.libros_quemados.01", False, "ch_20_dulcinea_encantada"),
    ("ch_20_dulcinea_encantada", "sierra_morena", 20, "bk.ch20.dulcinea_encantada.01", False, "ch_22_duelo_luz_luna"),
    ("ch_22_duelo_luz_luna", "el_toboso", 22, "bk.ch22.duelo_luz_luna.01", True, "ch_23_montesinos"),
    ("ch_23_montesinos", "el_toboso", 23, "bk.ch23.montesinos.01", False, "ch_24_altisidora"),
    ("ch_24_altisidora", "el_toboso", 24, "bk.ch24.altisidora.01", False, "ch_25_conde_altisidora"),
    ("ch_25_conde_altisidora", "los_riscos", 25, "bk.ch25.conde_altisidora.01", False, "ch_26_melisendra"),
    ("ch_26_melisendra", "los_riscos", 26, "bk.ch26.melisendra.01", False, "ch_27_molinos_llenadores"),
    ("ch_27_molinos_llenadores", "los_riscos", 27, "bk.ch27.molinos_llenadores.01", False, "ch_28_encantada"),
    ("ch_28_encantada", "el_castillo_del_duque", 28, "bk.ch28.encantada.01", False, "ch_29_penitentes"),
    ("ch_29_penitentes", "el_castillo_del_duque", 29, "bk.ch29.penitentes.01", False, "ch_30_leones_carro"),
    ("ch_30_leones_carro", "el_castillo_del_duque", 30, "bk.ch30.leones_carro.01", True, "ch_31_cueva_hermoso"),
    ("ch_31_cueva_hermoso", "camino_la_mancha", 31, "bk.ch31.cueva_hermoso.01", False, "ch_32_ventura_duque"),
    ("ch_32_ventura_duque", "camino_la_mancha", 32, "bk.ch32.ventura_duque.01", False, "ch_33_leones_reales"),
    ("ch_33_leones_reales", "camino_la_mancha", 33, "bk.ch33.leones_reales.01", False, "ch_34_encantamiento"),
    ("ch_34_encantamiento", "sierra_morena", 34, "bk.ch34.encantamiento.01", False, "ch_35_caballero_blanco"),
    ("ch_35_caballero_blanco", "sierra_morena", 35, "bk.ch35.caballero_blanco.01", True, "ch_36_cuidado_sancho"),
    ("ch_36_cuidado_sancho", "sierra_morena", 36, "bk.ch36.cuidado_sancho.01", False, "ch_37_encantamiento_duquesa"),
    ("ch_37_encantamiento_duquesa", "los_riscos", 37, "bk.ch37.encantamiento_duquesa.01", False, "ch_38_clavileño"),
    ("ch_38_clavileño", "los_riscos", 38, "bk.ch38.clavileño.01", False, "ch_39_sancho_gobernador"),
    ("ch_39_sancho_gobernador", "los_riscos", 39, "bk.ch39.sancho_gobernador.01", False, "ch_40_entierro_rico"),
    ("ch_40_entierro_rico", "el_castillo_del_duque", 40, "bk.ch40.entierro_rico.01", False, "ch_41_oviedo"),
    ("ch_41_oviedo", "el_castillo_del_duque", 41, "bk.ch41.oviedo.01", False, "ch_42_maestro_pedro"),
    ("ch_42_maestro_pedro", "el_castillo_del_duque", 42, "bk.ch42.maestro_pedro.01", False, "ch_43_caso_penal"),
    ("ch_43_caso_penal", "camino_la_mancha", 43, "bk.ch43.caso_penal.01", False, "ch_44_duelo_evitados"),
    ("ch_44_duelo_evitados", "camino_la_mancha", 44, "bk.ch44.duelo_evitados.01", False, "ch_45_encantamiento_sancho"),
    ("ch_45_encantamiento_sancho", "camino_la_mancha", 45, "bk.ch45.encantamiento_sancho.01", False, "ch_46_leones_corte"),
    ("ch_46_leones_corte", "camino_la_mancha", 46, "bk.ch46.leones_corte.01", False, "ch_47_despedida"),
    ("ch_47_despedida", "camino_la_mancha", 47, "bk.ch47.despedida.01", False, "ch_48_regreso_pueblo"),
    ("ch_48_regreso_pueblo", "camino_la_mancha", 48, "bk.ch48.regreso_pueblo.01", False, "ch_50_impertinente"),
    ("ch_50_impertinente", "camino_la_mancha", 50, "bk.ch50.impertinente.01", False, None),
]

REGION_CHAPTER_MAP = {
    "camino_la_mancha": ["ch_01_windmills", "ch_02_basque", "ch_03_canting_sea", "ch_14_galeotes", "ch_15_muerto_camino", "ch_16_barca_encantada", "ch_31_cueva_hermoso", "ch_32_ventura_duque", "ch_33_leones_reales", "ch_43_caso_penal", "ch_44_duelo_evitados", "ch_45_encantamiento_sancho", "ch_46_leones_corte", "ch_47_despedida", "ch_48_regreso_pueblo", "ch_50_impertinente"],
    "sierra_morena": ["ch_04_encinados", "ch_05_montesinos", "ch_06_bridge", "ch_17_hombre_muerto", "ch_18_libros_quemados", "ch_20_dulcinea_encantada", "ch_34_encantamiento", "ch_35_caballero_blanco", "ch_36_cuidado_sancho"],
    "el_toboso": ["ch_07_dulcinea", "ch_08_celestina", "ch_22_duelo_luz_luna", "ch_23_montesinos", "ch_24_altisidora"],
    "los_riscos": ["ch_09_ensayo_setup", "ch_10_ensayo_resolution", "ch_25_conde_altisidora", "ch_26_melisendra", "ch_27_molinos_llenadores", "ch_37_encantamiento_duquesa", "ch_38_clavileño", "ch_39_sancho_gobernador"],
    "el_castillo_del_duque": ["ch_11_mirrors", "ch_12_magician", "ch_13_duke", "ch_28_encantada", "ch_29_penitentes", "ch_30_leones_carro", "ch_40_entierro_rico", "ch_41_oviedo", "ch_42_maestro_pedro"],
}

COMBAT_CHAPTERS = {
    "ch_14_galeotes": "venture_galeotes",
    "ch_22_duelo_luz_luna": "venture_duelo_luz_luna",
    "ch_30_leones_carro": "venture_leones_carro",
    "ch_35_caballero_blanco": "venture_caballero_blanco",
}

def generate_region_graph_additions():
    """Generate the chapter entries to add to region_graph.tres"""
    lines = []
    
    # First, update ch_13_duke to unlock ch_14_galeotes instead of empty
    lines.append('	"ch_13_duke": {')
    lines.append('		"region_id": "el_castillo_del_duque",')
    lines.append('		"chapter_number": 13,')
    lines.append('		"scene_path": "res://src/world/chapters/ch_13_duke.tscn",')
    lines.append('		"venture_id": "venture_duke",')
    lines.append('		"case_id": "",')
    lines.append('		"unlocks": ["ch_14_galeotes"],')
    lines.append('	},')
    lines.append('')
    
    for chapter_id, region_id, chapter_num, frag_id, is_combat, next_chapter in CHAPTERS:
        scene_path = f'res://src/world/chapters/{chapter_name_to_scene(chapter_id)}.tscn'
        if is_combat:
            venture_id = COMBAT_CHAPTERS[chapter_id]
            case_id = '""'
        else:
            venture_id = '""'
            case_id = f'"{chapter_id}"'
        
        unlocks = f'["{next_chapter}"]' if next_chapter else '[]'
        
        lines.append(f'\t"{chapter_id}": {{')
        lines.append(f'\t\t"region_id": "{region_id}",')
        lines.append(f'\t\t"chapter_number": {chapter_num},')
        lines.append(f'\t\t"scene_path": "{scene_path}",')
        lines.append(f'\t\t"venture_id": {venture_id},')
        lines.append(f'\t\t"case_id": {case_id},')
        lines.append(f'\t\t"unlocks": {unlocks},')
        lines.append('\t},')
        lines.append('')
    
    return '\n'.join(lines)

def chapter_name_to_scene(chapter_id):
    """Map chapter_id to scene filename"""
    # chapter_id is like "ch_14_galeotes", scene is "ch_14_galeotes.tscn"
    return chapter_id

def generate_locale_keys():
    """Generate all missing locale keys for fragments"""
    keys = []
    for chapter_id, region_id, chapter_num, frag_id, is_combat, next_chapter in CHAPTERS:
        # fragment_id is like "bk.ch14.galeotes.01"
        # We need keys for:
        # ui.face.{frag_id_without_.01}.reality.desc
        # ui.face.{frag_id_without_.01}.reality.tell
        # ui.face.{frag_id_without_.01}.book.desc
        # ui.face.{frag_id_without_.01}.book.tell
        # ui.book.{frag_id_without_.01}.name
        
        frag_base = frag_id.replace(".01", "")
        
        keys.extend([
            f'msgid "ui.face.{frag_base}.reality.desc"',
            f'msgstr ""',
            f'',
            f'msgid "ui.face.{frag_base}.reality.tell"',
            f'msgstr ""',
            f'',
            f'msgid "ui.face.{frag_base}.book.desc"',
            f'msgstr ""',
            f'',
            f'msgid "ui.face.{frag_base}.book.tell"',
            f'msgstr ""',
            f'',
            f'msgid "ui.book.{frag_base}.name"',
            f'msgstr ""',
            f'',
        ])
    
    return '\n'.join(new_keys for new_keys in keys)

if __name__ == "__main__":
    print("=== REGION_GRAPH.TRES ADDITIONS ===")
    print(generate_region_graph_additions())
    print()
    print("=== LOCALE KEYS ===")
    print(generate_locale_keys())
