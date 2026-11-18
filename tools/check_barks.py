#!/usr/bin/env python3
"""Check that every dia.<char>.<slug> key maps to an existing bark WAV file."""
from pathlib import Path
import re

po = Path("locale/en.po").read_text(encoding="utf-8")
keys = sorted(set(re.findall(r'^msgid "(dia\.[^"]+)"', po, flags=re.MULTILINE)))
missing = []
for key in keys:
    parts = key.split(".")
    if len(parts) < 3:
        continue
    slug = ".".join(parts[2:])
    for char in ("quixote", "sancho"):
        if parts[1] != char:
            continue
        path = Path("assets/audio/barks") / char / f"{slug}.wav"
        if not path.exists():
            missing.append(str(path))
print(f"Bark keys: {len(keys)}, missing WAVs: {len(missing)}")
for p in missing:
    print(" ", p)
