#!/usr/bin/env python3
"""Remove ONLY the dead ch15-ch50 .01 duplicate keys from messages.pot.

ch_01 fragments legitimately use .01 (bk.ch01.molinos.01), so those keys stay.
The dead duplicates are the ui.book/ui.face keys for ch15-50 that carry an
extra .01 suffix the game never references.
"""

from pathlib import Path
import re

POT_PATH = Path("locale/messages.pot")

content = POT_PATH.read_text(encoding="utf-8")

# Dead key pattern: ui.book/ui.face + bk.ch{15-50} + slug + .01 + suffix
dead_pattern = re.compile(
    r'^(?:#\. META: namespace=ui\n)?'
    r'msgid "(?:ui\.(?:book|face)\.bk\.ch(?:1[5-9]|[2-4][0-9]|50)\.[^"]*\.01\.[^"]*)"\n'
    r'msgstr ""\n\n',
    flags=re.MULTILINE,
)

new_content, count = dead_pattern.subn("", content)

POT_PATH.write_text(new_content, encoding="utf-8")
print(f"Removed {count} dead ch15-50 .01 key blocks from messages.pot")

# Verify: no dead keys remain, but ch01 .01 keys are intact
dead_remaining = re.findall(
    r'^msgid "(ui\.(?:book|face)\.bk\.ch(?:1[5-9]|[2-4][0-9]|50)\.[^"]*\.01\.[^"]*)"$',
    new_content,
    flags=re.MULTILINE,
)
print(f"Remaining dead ch15-50 .01 msgids: {len(dead_remaining)}")
for key in dead_remaining[:5]:
    print(f"  {key}")

legit = re.findall(
    r'^msgid "(ui\.book\.bk\.ch01\.[^"]*\.01\.[^"]*)"$',
    new_content,
    flags=re.MULTILINE,
)
print(f"Legitimate ch01 .01 msgids still present: {len(legit)}")
