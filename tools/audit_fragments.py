#!/usr/bin/env python3
"""Audit the 48 fragments' modern renderings across the shipped languages."""
from pathlib import Path
import json
import re

LANGS = ["es", "en", "fr", "de", "it", "pt_BR"]

rows = []
for p in sorted(Path("assets/manifiesto").glob("*.json")):
    raw = re.sub(r",\s*([}\]])", r"\1", p.read_text(encoding="utf-8"))
    d = json.loads(raw)
    modern = d.get("modern", {}) or {}
    missing = [lang for lang in LANGS if not modern.get(lang)]
    rows.append((d.get("id", p.stem), len(modern), missing))

total_missing = sum(len(m) for _, _, m in rows)
print(f"Fragments: {len(rows)}, missing modern renderings: {total_missing}")
for fid, n, missing in rows:
    if missing:
        print(f"  {fid}: has {n}, missing {','.join(missing)}")
