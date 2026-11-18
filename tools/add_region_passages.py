#!/usr/bin/env python3
"""Add Book/Reality region passage keys to messages.pot and all 6 PO files.

DRAFT COPY: these passages are drafted content for the owner to verify against
the novel, exactly as the Manifiesto fragments are marked unverified until a
human checks them. The keys and their wiring are production; the wording is
a first pass.
"""

from pathlib import Path
import re

LOCALE_DIR = Path("locale")

# id -> (spanish, english)
PASSAGES = {
    "camino_la_mancha": (
        "Campos que no se acaban, y en ellos un gigante detrás de cada molino. El camino a la primera venta está empedrado de promesas.",
        "Endless fields, and a giant behind every windmill. The road to the first inn is paved with promises.",
        "Trigo, polvo y molinos que no son más que molinos. La venta tiene una cama y un estante de libros que nadie ha leído.",
        "Wheat, dust, and windmills that are only windmills. The inn keeps a bed and a shelf of books nobody has read.",
    ),
    "sierra_morena": (
        "Un muro de montaña seca donde cada cueva escupe un hechizo y cada bandido es un caballero encantado.",
        "A wall of dry mountain where every cave mouths a spell and every bandit is an enchanted knight.",
        "Roca desnuda, calor y la boca de una cueva que huele a sudor e incienso. Los bandidos esperan donde el camino se estrecha.",
        "Bare rock, heat, and the mouth of a cave that smells of sweat and incense. Bandits wait where the road narrows.",
    ),
    "el_toboso": (
        "Un pueblo bajo hechizo, donde una campesina es una dama y el río corre con luz encantada.",
        "A village under a spell, where a peasant girl is a lady and the river runs with enchanted light.",
        "Agua lenta, casas bajas y una muchacha que no sabe que la han nombrado. El pueblo es corriente; solo él no lo es.",
        "Slow water, low houses, and a girl who does not know she has been named. The village is ordinary; only he is not.",
    ),
    "los_riscos": (
        "Acantilados a pique y una iglesia gótica donde un hombre puede poner a juicio un mundo entero.",
        "Sheer cliffs and a Gothic church where a man may put a whole world on trial.",
        "Niebla entre las rocas, una iglesia de piedra fría y un sabio que ha escrito un libro sobre un cuchillo.",
        "Fog in the rocks, a church of cold stone, and a scholar who has written a book about a knife.",
    ),
    "el_castillo_del_duque": (
        "Seda, espejos y un duque que representa la caballería como un teatro. Cada pasillo es un decorado; cada criado está en el secreto.",
        "Silk, mirrors, and a duke who stages chivalry as theatre. Every corridor is a set; every servant is in on the joke.",
        "Un castillo frío de habitaciones doradas, un duque aburrido y dos personas que han decidido creer sus mentiras.",
        "A cold castle with gilded rooms, a bored duke, and two people who have decided to believe his lies.",
    ),
}

PO_FILES = ["en.po", "es.po", "fr.po", "de.po", "it.po", "pt_BR.po"]


def entries_for(po_file):
    result = {}
    for rid, (book_es, book_en, real_es, real_en) in PASSAGES.items():
        if po_file == "es.po":
            book, real = book_es, real_es
        else:
            book, real = book_en, real_en
        result[f"ui.region.{rid}.book"] = book
        result[f"ui.region.{rid}.reality"] = real
    return result


def add_to_po(path, values):
    content = path.read_text(encoding="utf-8")
    existing = set(re.findall(r'^msgid "([^"]*)"$', content, flags=re.MULTILINE))
    new = []
    for key, value in values.items():
        if key in existing:
            # Already present: fill an empty msgstr if needed.
            pat = re.compile(r'(msgid "' + re.escape(key) + r'"\n)msgstr ""')
            content, n = pat.subn(r'\1msgstr "' + value + '"', content, count=1)
            if n:
                print(f"  {path.name}: filled {key}")
            continue
        new.append(f'#. META: namespace=ui\nmsgid "{key}"\nmsgstr "{value}"\n')
    if new:
        # Insert before the first real msgid (after the header).
        m = re.search(r'^msgid "(.+)"$', content, flags=re.MULTILINE)
        pos = m.start()
        content = content[:pos] + "".join(new) + "\n" + content[pos:]
        print(f"  {path.name}: added {len(new)} passage keys")
    path.write_text(content, encoding="utf-8")


def main():
    pot = LOCALE_DIR / "messages.pot"
    content = pot.read_text(encoding="utf-8")
    existing = set(re.findall(r'^msgid "([^"]*)"$', content, flags=re.MULTILINE))
    new_keys = []
    for rid in PASSAGES:
        for suffix in ("book", "reality"):
            key = f"ui.region.{rid}.{suffix}"
            if key not in existing:
                new_keys.append(key)
    if new_keys:
        m = re.search(r'^msgid "(.+)"$', content, flags=re.MULTILINE)
        pos = m.start()
        block = "".join(f'#. META: namespace=ui\nmsgid "{k}"\nmsgstr ""\n' for k in new_keys)
        content = content[:pos] + block + "\n" + content[pos:]
        pot.write_text(content, encoding="utf-8")
        print(f"messages.pot: added {len(new_keys)} passage keys")
    for po_file in PO_FILES:
        add_to_po(LOCALE_DIR / po_file, entries_for(po_file))


if __name__ == "__main__":
    main()
