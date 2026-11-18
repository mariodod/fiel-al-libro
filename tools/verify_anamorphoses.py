from pathlib import Path
import re
from collections import Counter

scenes = list(Path("src/world/chapters").glob("ch_*.tscn"))
bad = []
with_ana = 0
total_ana = 0
for p in scenes:
    s = p.read_text(encoding="utf-8")
    ids = re.findall(r'^\[ext_resource[^\n]*? id="([^"]+)"', s, flags=re.M)
    dupes = [k for k, v in Counter(ids).items() if v > 1]
    if dupes:
        bad.append((p.name, dupes))
    n = s.count('name="Anamorphosis_')
    if n:
        with_ana += 1
        total_ana += n
        if n != 2:
            bad.append((p.name, f"expected 2 anamorphoses, got {n}"))
print(f"Scenes: {len(scenes)}, with anamorphoses: {with_ana}, total: {total_ana}")
print(f"Problems: {len(bad)}")
for item in bad[:10]:
    print(" ", item)
