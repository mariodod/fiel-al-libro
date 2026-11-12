#!/usr/bin/env python3
"""
Generate placeholder WAV files for all bark audio keys.

Run this script to create silent placeholder WAV files for all bark keys.
Replace these with real voice recordings as they are recorded.

Usage:
    python tools/generate_bark_audio.py
"""

import struct
import os

DIRECTORY = "assets/audio/barks"
SAMPLE_RATE = 44100
DURATION = 1.0  # seconds
NUM_CHANNELS = 1
BITS_PER_SAMPLE = 16
BYTES_PER_SAMPLE = BITS_PER_SAMPLE // 8

# All bark keys that need audio files
BARK_KEYS = [
    # Quixote barks
    ("quixote", "dia.quixote.bark.001"),
    ("quixote", "dia.quixote.bark.002"),
    # Quixote chatter (thing-based)
    ("quixote", "dia.quixote.chatter.rock"),
    ("quixote", "dia.quixote.chatter.windmill"),
    ("quixote", "dia.quixote.chatter.dummy"),
    ("quixote", "dia.quixote.chatter.locked"),
    ("quixote", "dia.quixote.chatter.down"),
    ("quixote", "dia.quixote.chatter.parry"),
    ("quixote", "dia.quixote.chatter.desvelar"),
    ("quixote", "dia.quixote.chatter.straw_man"),
    ("quixote", "dia.quixote.chatter.venture_down"),
    ("quixote", "dia.quixote.chatter.venture"),
    ("quixote", "dia.quixote.chatter.revive"),
    # Quixote chatter idle
    ("quixote", "dia.quixote.chatter.idle.1"),
    ("quixote", "dia.quixote.chatter.idle.2"),
    ("quixote", "dia.quixote.chatter.idle.3"),
    ("quixote", "dia.quixote.chatter.idle.4"),
    ("quixote", "dia.quixote.chatter.idle.5"),
    ("quixote", "dia.quixote.chatter.idle.6"),
    # Quixote reactions
    ("quixote", "dia.quixote.reaction.windmill.book"),
    ("quixote", "dia.quixote.reaction.windmill.reality"),
    ("quixote", "dia.quixote.reaction.rock.book"),
    ("quixote", "dia.quixote.reaction.rock.reality"),
    ("quixote", "dia.quixote.reaction.venture.reality"),
    ("quixote", "dia.quixote.reaction.venture.book"),
    # Sancho barks
    ("sancho", "dia.sancho.bark.001"),
    ("sancho", "dia.sancho.bark.002"),
    # Sancho chatter (thing-based)
    ("sancho", "dia.sancho.chatter.rock"),
    ("sancho", "dia.sancho.chatter.windmill"),
    ("sancho", "dia.sancho.chatter.dummy"),
    ("sancho", "dia.sancho.chatter.locked"),
    ("sancho", "dia.sancho.chatter.down"),
    ("sancho", "dia.sancho.chatter.parry"),
    ("sancho", "dia.sancho.chatter.desvelar"),
    ("sancho", "dia.sancho.chatter.straw_man"),
    ("sancho", "dia.sancho.chatter.venture_down"),
    ("sancho", "dia.sancho.chatter.venture"),
    ("sancho", "dia.sancho.chatter.revive"),
    # Sancho chatter idle
    ("sancho", "dia.sancho.chatter.idle.1"),
    ("sancho", "dia.sancho.chatter.idle.2"),
    ("sancho", "dia.sancho.chatter.idle.3"),
    ("sancho", "dia.sancho.chatter.idle.4"),
    ("sancho", "dia.sancho.chatter.idle.5"),
    ("sancho", "dia.sancho.chatter.idle.6"),
    # Sancho reactions
    ("sancho", "dia.sancho.reaction.windmill.book"),
    ("sancho", "dia.sancho.reaction.windmill.reality"),
    ("sancho", "dia.sancho.reaction.rock.book"),
    ("sancho", "dia.sancho.reaction.rock.reality"),
    ("sancho", "dia.sancho.reaction.venture.reality"),
    ("sancho", "dia.sancho.reaction.venture.book"),
]


def write_wav(filepath, duration_seconds=1.0, sample_rate=44100):
    """Write a silent WAV file."""
    num_samples = int(sample_rate * duration_seconds)
    data = b"\x00\x00" * num_samples  # Silent 16-bit mono

    with open(filepath, "wb") as f:
        # RIFF header
        f.write(b"RIFF")
        f.write(struct.pack("<I", 36 + len(data)))  # File size - 8
        f.write(b"WAVE")

        # fmt chunk
        f.write(b"fmt ")
        f.write(struct.pack("<I", 16))  # Chunk size
        f.write(struct.pack("<H", 1))   # Audio format (PCM)
        f.write(struct.pack("<H", NUM_CHANNELS))   # Num channels
        f.write(struct.pack("<I", sample_rate))
        f.write(struct.pack("<I", sample_rate * NUM_CHANNELS * BYTES_PER_SAMPLE))  # Byte rate
        f.write(struct.pack("<H", NUM_CHANNELS * BYTES_PER_SAMPLE))  # Block align
        f.write(struct.pack("<H", BITS_PER_SAMPLE))  # Bits per sample

        # data chunk
        f.write(b"data")
        f.write(struct.pack("<I", len(data)))
        f.write(data)


def main():
    os.makedirs(DIRECTORY, exist_ok=True)

    for character_id, bark_key in BARK_KEYS:
        # Strip the character prefix from the key for the filename
        # e.g., "dia.quixote.bark.001" -> "bark.001.wav"
        #      "dia.quixote.chatter.rock" -> "chatter.rock.wav"
        #      "dia.quixote.reaction.windmill.book" -> "reaction.windmill.book.wav"
        parts = bark_key.split(".")
        # parts = ["dia", "quixote", "bark", "001"] or ["dia", "quixote", "chatter", "rock"]
        suffix_parts = parts[2:]  # Remove "dia" and character_id
        filename = "_".join(suffix_parts) + ".wav"
        filepath = os.path.join(DIRECTORY, filename)

        write_wav(filepath, DURATION, SAMPLE_RATE)
        print(f"Created: {filepath}")

    print(f"\nGenerated {len(BARK_KEYS)} bark audio files in {DIRECTORY}/")


if __name__ == "__main__":
    main()