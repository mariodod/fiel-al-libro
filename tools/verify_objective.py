#!/usr/bin/env python3
"""Final verification of the Phase 2 chapter content objective."""

from pathlib import Path
import re

CHAPTERS_DIR = Path("src/world/chapters")
BOOKS_DIR = Path("src/data/primitives")
VENTURES_DIR = Path("src/data/ventures")
ENEMIES_DIR = Path("src/data/enemies")
LOCALE_DIR = Path("locale")

# Chapters ch_14 through ch_50
chapter_nums = [14, 15, 16, 17, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30,
                31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45,
                46, 47, 48, 50]

# Get all chapter script/scene names
scenes = list(CHAPTERS_DIR.glob("ch_*.tscn"))
scripts = list(CHAPTERS_DIR.glob("ch_*.gd"))
print(f"Chapter scenes: {len(scenes)}")
print(f"Chapter scripts: {len(scripts)}")

# Count venture nodes in scenes
venture_scenes = []
for s in scenes:
    if "src/data/ventures/" in s.read_text(encoding="utf-8", errors="replace"):
        venture_scenes.append(s.name)
print(f"Scenes with Venture nodes: {len(venture_scenes)}")
for v in sorted(venture_scenes):
    print(f"  {v}")

# Count book .tres files
books = list(BOOKS_DIR.glob("book_bk*.tres"))
print(f"Book .tres files: {len(books)}")

# Venture and enemy data
ventures = list(VENTURES_DIR.glob("*.tres"))
enemies = list(ENEMIES_DIR.glob("*.tres"))
print(f"Venture .tres files: {len(ventures)}")
print(f"Enemy .tres files: {len(enemies)}")

# Region graph chapters
rg = Path("src/data/region_graph.tres").read_text(encoding="utf-8")
rg_chapters = re.findall(r'^\t"ch_\d+[a-z_]*": \{', rg, flags=re.MULTILINE)
print(f"Region graph chapter entries: {len(rg_chapters)}")

# Locale completeness
for po_file in ["en.po", "es.po", "fr.po", "de.po", "it.po", "pt_BR.po"]:
    c = (LOCALE_DIR / po_file).read_text(encoding="utf-8")
    # Count non-empty fragment msgstr
    entries = re.findall(r'msgid "(ui\.(?:book|face)\.bk\.ch(?:1[5-9]|[2-4][0-9]|50)\.[^"]*)"\nmsgstr "([^"]*)"', c)
    filled = sum(1 for k, v in entries if v)
    print(f"{po_file}: {filled}/{len(entries)} fragment keys translated")
