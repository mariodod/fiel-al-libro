from pathlib import Path
import re
from collections import Counter

counts = Counter()
samples = {}
for p in sorted(Path("src/world/chapters").glob("ch_*.tscn")):
    for line in p.read_text(encoding="utf-8").split("\n"):
        m = re.match(r'^transform = Transform3D\(([^)]*)\)', line)
        if not m:
            continue
        n = len([x for x in m.group(1).split(",") if x.strip()])
        counts[n] += 1
        samples.setdefault(n, line.strip())
for n, c in sorted(counts.items()):
    print(f"{n} values: {c}  e.g. {samples[n]}")
