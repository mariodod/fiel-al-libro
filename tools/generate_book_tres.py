#!/usr/bin/env python3
"""
Generate missing book .tres files for chapters ch_15–ch_50.
Each fragment needs a TruthObjectData resource so it can be placed in the world.
"""

import json
import os
from pathlib import Path

MANIFIESTO_DIR = Path("assets/manifiesto")
OUTPUT_DIR = Path("src/data/primitives")

# Map chapter slugs to form types
# Most fragments use rock forms. Windmill-related ones use windmill forms.
FORM_MAP = {
    "molinos": ("windmill_reality", "windmill_book", False),  # windmill doesn't hover
    "molinos_llenadores": ("windmill_reality", "windmill_book", False),
}

# All fragments that need book .tres files (ch_15–ch_50, excluding ch_14 which already has one)
FRAGMENTS = [
    # Chapter 15
    ("bk.ch15.muerto_camino.01", "muerto_camino", 15),
    # Chapter 16
    ("bk.ch16.barca_encantada.01", "barca_encantada", 16),
    # Chapter 17
    ("bk.ch17.hombre_muerto.01", "hombre_muerto", 17),
    # Chapter 18
    ("bk.ch18.libros_quemados.01", "libros_quemados", 18),
    # Chapter 20
    ("bk.ch20.dulcinea_encantada.01", "dulcinea_encantada", 20),
    # Chapter 22
    ("bk.ch22.duelo_luz_luna.01", "duelo_luz_luna", 22),
    # Chapter 23
    ("bk.ch23.montesinos.01", "montesinos", 23),
    # Chapter 24
    ("bk.ch24.altisidora.01", "altisidora", 24),
    # Chapter 25
    ("bk.ch25.conde_altisidora.01", "conde_altisidora", 25),
    # Chapter 26
    ("bk.ch26.melisendra.01", "melisendra", 26),
    # Chapter 27
    ("bk.ch27.molinos_llenadores.01", "molinos_llenadores", 27),
    # Chapter 28
    ("bk.ch28.encantada.01", "encantada", 28),
    # Chapter 29
    ("bk.ch29.penitentes.01", "penitentes", 29),
    # Chapter 30
    ("bk.ch30.leones_carro.01", "leones_carro", 30),
    # Chapter 31
    ("bk.ch31.cueva_hermoso.01", "cueva_hermoso", 31),
    # Chapter 32
    ("bk.ch32.ventura_duque.01", "ventura_duque", 32),
    # Chapter 33
    ("bk.ch33.leones_reales.01", "leones_reales", 33),
    # Chapter 34
    ("bk.ch34.encantamiento.01", "encantamiento", 34),
    # Chapter 35
    ("bk.ch35.caballero_blanco.01", "caballero_blanco", 35),
    # Chapter 36
    ("bk.ch36.cuidado_sancho.01", "cuidado_sancho", 36),
    # Chapter 37
    ("bk.ch37.encantamiento_duquesa.01", "encantamiento_duquesa", 37),
    # Chapter 38
    ("bk.ch38.clavileño.01", "clavileño", 38),
    # Chapter 39
    ("bk.ch39.sancho_gobernador.01", "sancho_gobernador", 39),
    # Chapter 40
    ("bk.ch40.entierro_rico.01", "entierro_rico", 40),
    # Chapter 41
    ("bk.ch41.oviedo.01", "oviedo", 41),
    # Chapter 42
    ("bk.ch42.maestro_pedro.01", "maestro_pedro", 42),
    # Chapter 43
    ("bk.ch43.caso_penal.01", "caso_penal", 43),
    # Chapter 44
    ("bk.ch44.duelo_evitados.01", "duelo_evitados", 44),
    # Chapter 45
    ("bk.ch45.encantamiento_sancho.01", "encantamiento_sancho", 45),
    # Chapter 46
    ("bk.ch46.leones_corte.01", "leones_corte", 46),
    # Chapter 47
    ("bk.ch47.despedida.01", "despedida", 47),
    # Chapter 48
    ("bk.ch48.regreso_pueblo.01", "regreso_pueblo", 48),
    # Chapter 50
    ("bk.ch50.impertinente.01", "impertinente", 50),
]

def get_form_info(slug):
    """Get reality_form, book_form, book_form_hovers for a slug."""
    if slug in FORM_MAP:
        return FORM_MAP[slug]
    # Default: rock forms, hovers = true
    return ("rock_reality", "rock_book", True)

def generate_tres(fragment_id, slug, chapter_num):
    """Generate .tres file content for a fragment."""
    reality_form, book_form, hovers = get_form_info(slug)
    
    # Fragment id without .01 suffix for data id
    frag_id = fragment_id.replace(".01", "")
    
    tres = f"""[gd_resource type="Resource" script_class="TruthObjectData" load_steps=7 format=3]

[ext_resource type="Script" path="res://src/data/truth_object_data.gd" id="1_data"]
[ext_resource type="Script" path="res://src/data/truth_face.gd" id="2_face"]
[ext_resource type="PackedScene" path="res://src/world/forms/{reality_form}.tscn" id="rock_reality"]
[ext_resource type="PackedScene" path="res://src/world/forms/{book_form}.tscn" id="rock_book"]

[sub_resource type="Resource" id="RealityFace"]
script = ExtResource("2_face")
name_key = &"ui.form.roca"
description_key = &"ui.face.{frag_id}.reality.desc"
tell_key = &"ui.face.{frag_id}.reality.tell"

[sub_resource type="Resource" id="BookFace"]
script = ExtResource("2_face")
name_key = &"ui.form.libro"
description_key = &"ui.face.{frag_id}.book.desc"
tell_key = &"ui.face.{frag_id}.book.tell"
fragment_id = &"{frag_id}"

[resource]
script = ExtResource("1_data")
id = &"{frag_id}"
display_name_key = &"ui.book.{frag_id}.name"
reality_form = ExtResource("rock_reality")
book_form = ExtResource("rock_book")
reality_face = SubResource("RealityFace")
book_face = SubResource("BookFace")
book_form_hovers = {str(hovers).lower()}
tag_height = 3.4
anamorphosis_id = &""
anamorphosis_evidence = 1
"""
    return tres

def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    count = 0
    for fragment_id, slug, chapter_num in FRAGMENTS:
        output_path = OUTPUT_DIR / f"book_{fragment_id}.tres"
        if output_path.exists():
            print(f"SKIP (exists): {output_path}")
            continue
        
        content = generate_tres(fragment_id, slug, chapter_num)
        output_path.write_text(content)
        print(f"CREATED: {output_path}")
        count += 1
    
    print(f"\nGenerated {count} book .tres files")

if __name__ == "__main__":
    main()
