#!/usr/bin/env python3
"""Reuse an existing recorded bark for keys that only had silent placeholders.

Real VO is a content task that needs an ElevenLabs key (tools/generate_barks.py).
Until then, every bark key should still make a *real* sound. This copies a
semantically appropriate recorded bark into each silent slot:

  chatter.desvelar     <- desvelar       (Sancho's verb)
  chatter.parry        <- parry
  chatter.revive       <- revive
  chatter.venture_down <- chatter.venture (the fight is over)
  chatter.pebble       <- chatter.rock    (a pebble is a rock)
  reaction.venture.*   <- reaction.molinos.* (the Venture of Montiel)

Idempotent: skips a target whose size shows it is already a real recording.
"""

from pathlib import Path
import shutil

ROOT = Path("assets/audio/barks")
SILENT_SIZE = 88244  # 1s of 44.1kHz 16-bit mono silence
SOURCES = {
    "chatter.desvelar": "desvelar",
    "chatter.parry": "parry",
    "chatter.revive": "revive",
    "chatter.venture_down": "chatter.venture",
    "chatter.pebble": "chatter.rock",
    "reaction.venture.book": "reaction.molinos.book",
    "reaction.venture.reality": "reaction.molinos.reality",
}


def main():
    for character in ("quixote", "sancho"):
        folder = ROOT / character
        for target, source in SOURCES.items():
            dst = folder / f"{target}.wav"
            src = folder / f"{source}.wav"
            if not src.exists():
                print(f"SKIP {dst.name}: source {src.name} missing")
                continue
            if dst.exists() and dst.stat().st_size != SILENT_SIZE:
                print(f"SKIP {dst.name}: already a real recording")
                continue
            shutil.copyfile(src, dst)
            print(f"{character}/{target}.wav <- {source}.wav")


if __name__ == "__main__":
    main()
