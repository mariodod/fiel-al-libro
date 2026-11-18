from pathlib import Path

p = Path(".gitignore")
s = p.read_text(encoding="utf-8")
if "ana_*.txt" not in s:
    s = s.rstrip() + "\n\n# Temporary test output\nana_*.txt\n"
    p.write_text(s, encoding="utf-8")
print("gitignore updated")
