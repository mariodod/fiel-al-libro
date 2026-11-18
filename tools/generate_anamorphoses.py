#!/usr/bin/env python3
"""Add two anamorphoses to every chapter (GDD §11.3: '2–4 anamorphoses').

An anamorphosis is a detail that does not add up, visible only in Lectura
mode from a vantage point. The system already exists in TruthObjectData,
Lectura and the Examine panel — the chapter scenes simply had none.

Each generated resource carries a unique id and two locale keys (desc/tell).
Tells are drawn from a pool of recurring motifs, prefixed by the chapter's own
subject so each is a distinct discovery. Spanish is the original; the other
five locales get the English rendering.
"""

from pathlib import Path
import re

CHAPTERS_DIR = Path("src/world/chapters")
OUT_DIR = Path("src/data/anamorphoses")
LOCALE_DIR = Path("locale")

# (slug, spanish tell, english tell)
MOTIFS = [
    ("weight", "Pesa más de lo que debería pesar.",
     "It weighs more than it should."),
    ("shadow", "La sombra cae hacia la luz, no desde ella.",
     "The shadow falls towards the light, not away from it."),
    ("sound", "Suena hueco al tocarlo, pero es macizo.",
     "It sounds hollow when touched, yet it is solid."),
    ("seam", "Tiene una costura donde no debería haber ninguna.",
     "There is a seam where no seam should be."),
    ("dust", "El polvo se acumula en contra del viento.",
     "The dust gathers against the wind."),
    ("glow", "Brilla por dentro cuando nada lo ilumina.",
     "It glows from within when nothing lights it."),
    ("words", "Bajo la pintura hay palabras que no dicen lo que parece.",
     "Under the paint are words that do not say what they seem to."),
    ("age", "Es nuevo en un lugar viejo desde hace siglos.",
     "It is new in a place that has been old for centuries."),
    ("echo", "El eco llega antes que la voz.",
     "The echo arrives before the voice."),
    ("number", "Las marcas no cuentan lo que parece que cuentan.",
     "The marks do not count what they seem to count."),
]

DESC_ES = "Un detalle que no encaja. Solo se ve desde un sitio, y solo en Lectura."
DESC_EN = "A detail that does not fit. Visible from one spot, and only in Lectura."


def chapter_titles():
    """chapter number -> (es title, en title), from the keys we authored."""
    out = {}
    for locale, target in (("es.po", 0), ("en.po", 1)):
        s = (LOCALE_DIR / locale).read_text(encoding="utf-8")
        for m in re.finditer(
            r'^msgid "(ui\.chapter\.(\d{2})\.title)"\nmsgstr "([^"]*)"', s, re.M
        ):
            num = int(m.group(2))
            title = m.group(3)
            if num not in out:
                out[num] = ["", ""]
            out[num][target] = title
    return out


def make_tres(ana_id, pos, angle):
    return f"""[gd_resource type="Resource" script_class="TruthObjectData" load_steps=7 format=3]

[ext_resource type="Script" path="res://src/data/truth_object_data.gd" id="1_data"]
[ext_resource type="Script" path="res://src/data/truth_face.gd" id="2_face"]
[ext_resource type="PackedScene" path="res://src/world/forms/rock_reality.tscn" id="rock_reality"]
[ext_resource type="PackedScene" path="res://src/world/forms/rock_book.tscn" id="rock_book"]

[sub_resource type="Resource" id="RealityFace"]
script = ExtResource("2_face")
name_key = &"ui.form.roca"
description_key = &"ui.anamorphosis.{ana_id}.desc"
tell_key = &"ui.anamorphosis.{ana_id}.tell"

[sub_resource type="Resource" id="BookFace"]
script = ExtResource("2_face")
name_key = &"ui.form.libro"
description_key = &"ui.anamorphosis.{ana_id}.desc"
tell_key = &"ui.anamorphosis.{ana_id}.tell"

[resource]
script = ExtResource("1_data")
id = &"{ana_id}"
display_name_key = &"ui.form.roca"
reality_form = ExtResource("rock_reality")
book_form = ExtResource("rock_book")
reality_face = SubResource("RealityFace")
book_face = SubResource("BookFace")
book_form_hovers = true
tag_height = 2.4
anamorphosis_id = &"{ana_id}"
anamorphosis_tell_key = &"ui.anamorphosis.{ana_id}.tell"
anamorphosis_evidence = 1
anamorphosis_vantage_pos = Vector3{pos}
anamorphosis_vantage_angle = {angle}
anamorphosis_vantage_radius = 5.0
"""


def add_locale_keys(entries):
    for name in ["messages.pot", "en.po", "es.po", "fr.po", "de.po", "it.po", "pt_BR.po"]:
        p = LOCALE_DIR / name
        s = p.read_text(encoding="utf-8")
        additions = []
        for key, es, en in entries:
            for suffix, val_es, val_en in (("desc", DESC_ES, DESC_EN), ("tell", es, en)):
                full = f"ui.anamorphosis.{key}.{suffix}"
                if re.search(r'^msgid "' + re.escape(full) + r'"$', s, flags=re.M):
                    continue
                val = "" if name == "messages.pot" else (val_es if name == "es.po" else val_en)
                additions.append(
                    f'#. META: namespace=ui\nmsgid "{full}"\nmsgstr "{val}"\n'
                )
        if additions:
            m = re.search(r'^msgid "(?!")', s, flags=re.M)
            pos = m.start() if m else len(s)
            s = s[:pos] + "\n".join(additions) + "\n" + s[pos:]
            p.write_text(s, encoding="utf-8")
        print(f"  {name}: +{len(additions)} keys")


def add_nodes_to_scenes(mapping):
    for chapter_num, items in mapping.items():
        paths = list(CHAPTERS_DIR.glob(f"ch_{chapter_num:02d}_*.tscn"))
        assert len(paths) == 1, (chapter_num, paths)
        path = paths[0]
        s = path.read_text(encoding="utf-8")
        if 'name="Anamorphosis_' in s:
            continue

        ids = [int(n) for n in re.findall(r'^\[ext_resource[^\n]*? id="(\d+)_', s, flags=re.M)]
        next_id = max(ids, default=0) + 1

        lines = s.split("\n")
        ext_lines = []
        node_lines = []
        for i, (ana_id, res_name) in enumerate(items):
            ext_lines.append(
                f'[ext_resource type="Resource" path="res://src/data/anamorphoses/{ana_id}.tres" '
                f'id="{next_id + i}_ana{i}"]'
            )
            x = 8.0 if i == 0 else -8.0
            node_lines += [
                f'[node name="Anamorphosis_{res_name}" type="Node3D" parent="."]',
                f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, 0, -12)",
                'script = ExtResource("2_object")',
                f'data = ExtResource("{next_id + i}_ana{i}")',
                "",
            ]
        last_ext = max(i for i, l in enumerate(lines) if l.startswith("[ext_resource"))
        for j, ext in enumerate(ext_lines):
            lines.insert(last_ext + 1 + j, ext)
        s = "\n".join(lines).rstrip() + "\n\n" + "\n".join(node_lines)
        path.write_text(s, encoding="utf-8")


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    titles = chapter_titles()
    entries = []
    mapping = {}

    chapters = sorted(
        {int(m.group(1)) for p in CHAPTERS_DIR.glob("ch_*.gd")
         if (m := re.match(r"ch_(\d+)_", p.name))}
    )
    for idx, num in enumerate(chapters):
        es_title, en_title = titles.get(num, (f"Capítulo {num}", f"Chapter {num}"))
        items = []
        for slot in range(2):
            motif = MOTIFS[(idx * 2 + slot) % len(MOTIFS)]
            slug, es_tell, en_tell = motif
            ana_id = f"ana.ch{num:02d}.{slug}"
            tell_es = f"{es_title}: {es_tell}"
            tell_en = f"{en_title}: {en_tell}"

            pos = "(2, 0, -17)" if slot == 0 else "(-2, 0, -17)"
            angle = 180.0 if slot == 0 else 0.0
            (OUT_DIR / f"{ana_id}.tres").write_text(make_tres(ana_id, pos, angle), encoding="utf-8")

            entries.append((ana_id, tell_es, tell_en))
            items.append((ana_id, slug.capitalize()))
        mapping[num] = items

    add_locale_keys(entries)
    add_nodes_to_scenes(mapping)
    print(f"Generated {len(entries)} anamorphoses across {len(chapters)} chapters")


if __name__ == "__main__":
    main()
