#!/usr/bin/env python3
"""Verify all fragment keys have non-empty msgstr in all 6 PO files."""

from pathlib import Path
import re

LOCALE_DIR = Path("locale")
PO_FILES = ["en.po", "es.po", "fr.po", "de.po", "it.po", "pt_BR.po"]

FRAGMENT_IDS = [
    "bk.ch15.muerto_camino", "bk.ch16.barca_encantada", "bk.ch17.hombre_muerto",
    "bk.ch18.libros_quemados", "bk.ch20.dulcinea_encantada", "bk.ch22.duelo_luz_luna",
    "bk.ch23.montesinos", "bk.ch24.altisidora", "bk.ch25.conde_altisidora",
    "bk.ch26.melisendra", "bk.ch27.molinos_llenadores", "bk.ch28.encantada",
    "bk.ch29.penitentes", "bk.ch30.leones_carro", "bk.ch31.cueva_hermoso",
    "bk.ch32.ventura_duque", "bk.ch33.leones_reales", "bk.ch34.encantamiento",
    "bk.ch35.caballero_blanco", "bk.ch36.cuidado_sancho", "bk.ch37.encantamiento_duquesa",
    "bk.ch38.clavileño", "bk.ch39.sancho_gobernador", "bk.ch40.entierro_rico",
    "bk.ch41.oviedo", "bk.ch42.maestro_pedro", "bk.ch43.caso_penal",
    "bk.ch44.duelo_evitados", "bk.ch45.encantamiento_sancho", "bk.ch46.leones_corte",
    "bk.ch47.despedida", "bk.ch48.regreso_pueblo", "bk.ch50.impertinente",
]

SUFFIXES = [
    "name",
    "reality.desc",
    "reality.tell",
    "book.desc",
    "book.tell",
]

def parse_po(path):
    """Parse PO file into {msgid: msgstr}."""
    entries = {}
    content = path.read_text(encoding="utf-8")
    for m in re.finditer(r'msgid "([^"]*)"\nmsgstr "([^"]*)"', content):
        entries[m.group(1)] = m.group(2)
    return entries

all_ok = True
for po_file in PO_FILES:
    po_path = LOCALE_DIR / po_file
    entries = parse_po(po_path)
    empty = []
    missing = []
    for frag_id in FRAGMENT_IDS:
        for suffix in SUFFIXES:
            if suffix == "name":
                key = f"ui.book.{frag_id}.name"
            else:
                key = f"ui.face.{frag_id}.{suffix}"
            if key not in entries:
                missing.append(key)
            elif not entries[key]:
                empty.append(key)
    status = "OK" if not missing and not empty else "FAIL"
    if missing or empty:
        all_ok = False
    print(f"{po_file}: {status} (missing={len(missing)}, empty={len(empty)})")
    for k in missing[:3]:
        print(f"    MISSING: {k}")
    for k in empty[:3]:
        print(f"    EMPTY: {k}")

print()
if all_ok:
    print("ALL 6 LOCALES: 33 fragments x 5 keys = 165 translations each, all non-empty")
else:
    print("SOME LOCALES HAVE MISSING OR EMPTY TRANSLATIONS")
