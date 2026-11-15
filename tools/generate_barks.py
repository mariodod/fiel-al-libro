#!/usr/bin/env python3
"""
Generate bark audio files for Fiel al Libro using ElevenLabs API.

Usage:
    python generate_barks.py --api-key YOUR_API_KEY
    python generate_barks.py --api-key YOUR_API_KEY --dry-run
    python generate_barks.py --api-key YOUR_API_KEY --voice-quixote <id> --voice-sancho <id>
    python generate_barks.py --api-key YOUR_API_KEY --list-voices

Output goes to:
    assets/audio/barks/<character>/<slug>.wav
"""

import argparse
import sys
import time
from pathlib import Path

try:
    import requests
except ImportError:
    print("ERROR: 'requests' package not installed. Run: pip install requests")
    sys.exit(1)

# ──────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ──────────────────────────────────────────────────────────────────────────────
# Set these or pass via --api-key / --voice-quixote / --voice-sancho
API_KEY = ""          # Your ElevenLabs API key
VOICE_QUIXOTE = ""    # Voice ID for Quixote (deep, grandiose, noble)
VOICE_SANCHO = ""     # Voice ID for Sancho (earthy, loyal, weary)

# ElevenLabs API
ELEVENLABS_BASE = "https://api.elevenlabs.io/v1"
MODEL_ID = "eleven_multilingual_v2"

# Output directory (relative to project root or absolute)
OUTPUT_DIR = Path("assets/audio/barks")

# ── Character voice settings ──────────────────────────────────────────────────
VOICE_SETTINGS = {
    "quixote": {"stability": 0.45, "similarity_boost": 0.80, "style": 0.40},
    "sancho":  {"stability": 0.60, "similarity_boost": 0.70, "style": 0.30},
}

# ── All bark data ─────────────────────────────────────────────────────────────
# Format: (character, slug, spanish_text)
# slug becomes the filename: assets/audio/barks/<character>/<slug>.wav
# Keys follow pattern: dia.<character>.<category>.<slug>

BARKS = []

# ── Generic bark pool (2 per character) ──
BARKS += [
    ("quixote", "bark.001", "¡Por Dios, Sancho! ¿Qué demonios es eso?"),
    ("quixote", "bark.002", "¡A mí, caballeros! ¡A la carga!"),
    ("sancho",  "bark.001", "Señor, eso no es un gigante, es un molino."),
    ("sancho",  "bark.002", "¡Ay, señor! ¡No se meta en esos líos!"),
]

# ── Idle chatter (6 per character, cycled) ──
QUIXOTE_IDLE = [
    "Molinos, Sancho. Y gigantes, si el viento quiere que lo sean.",
    "Aventura nos llama, Sancho. ¡Adelante!",
    "La gloria espera, amigo Sancho.",
    "Cabalgamos hacia la justicia.",
    "El mundo está lleno de encantamientos.",
    "¡Viva la caballería!",
]
SANCHO_IDLE = [
    "Una piedra, señor. De las que hay a montones.",
    "Espera, señor, que no veo nada claro.",
    "¿Y ahora adónde vamos, señor?",
    "Creo que deberíamos descansar.",
    "Tengo hambre, señor.",
    "Mire, señor, no es tal cosa.",
]

for i, text in enumerate(QUIXOTE_IDLE, 1):
    BARKS.append(("quixote", f"chatter.idle.{i}", text))
for i, text in enumerate(SANCHO_IDLE, 1):
    BARKS.append(("sancho", f"chatter.idle.{i}", text))

# ── Situational chatter ──
SITUATIONAL = [
    ("quixote", "chatter.locked", "¡Ahí está! ¡Después de él!"),
    ("quixote", "chatter.down", "¡Levántese, señor! ¡No se quede ahí!"),
    ("quixote", "chatter.venture", "Un gigante, señor. ¡Mire, un gigante!"),
    ("quixote", "chatter.straw_man", "Un maniquí, señor. Está puesto para que le den."),
    ("quixote", "chatter.rock", "Una piedra, señor. Sencilla y callada."),
    ("quixote", "chatter.windmill", "Un molino, señor. Solo un molino."),
    ("quixote", "chatter.book", "Un libro, señor. ¿Y quién lo ha puesto aquí?"),
    ("quixote", "chatter.dummy", "Un maniquí, señor. Está puesto para que le den."),
    ("sancho",  "chatter.locked", "Ah, ¿vamos a por él, señor?"),
    ("sancho",  "chatter.down",   "¡Levántese, señor! ¡No se quede ahí!"),
    ("sancho",  "chatter.venture","Un gigante, señor. ¡Mire, un gigante!"),
    ("sancho",  "chatter.straw_man","Un maniquí, señor. Está puesto para que le den."),
    ("sancho",  "chatter.rock",   "Una piedra, señor. De las que hay a montones."),
    ("sancho",  "chatter.windmill","Un molino, señor. Solo un molino."),
    ("sancho",  "chatter.book",   "Un libro, señor. ¿Y quién lo ha puesto aquí?"),
    ("sancho",  "chatter.dummy",  "Un maniquí, señor. Está puesto para que le den."),
]
BARKS += SITUATIONAL

# ── Combat verbs ──
COMBAT = [
    ("quixote", "desvelar", "¡La verdad se revela! ¡La piel del libro se despega!"),
    ("quixote", "parry",    "¡Así! ¡Así se defiende un caballero!"),
    ("quixote", "revive",   "¡Levántese, Sancho! ¡No se rinda!"),
    ("sancho",  "desvelar", "¡Mire, señor! ¡La piel del libro se despega!"),
    ("sancho",  "parry",    "¡Así! ¡Así se para un golpe!"),
    ("sancho",  "revive",   "¡Señor, ánimos! ¡Levántese!"),
]
BARKS += COMBAT

# ── Reaction barks (reading changes) ──
# object_id comes from TruthObjectData.id in .tres files (fragment ids like bk.ch01.apertura)
# layer: "book" or "reality"
REACTION_OBJECTS = [
    "rock", "windmill", "book_stand", "tome",
    "molinos", "nombre", "caballeros", "posada",
    "rocinante", "duena", "pastores", "yanguesas",
    "manuscrito", "balsamo", "caballero_bosque", "armas_letras",
    "leones", "galeotes", "leyenda",
    "innkeeper", "musician",
]

# Quixote reaction lines (Book / Reality)
QUIXOTE_REACTIONS = {
    "rock":         ("¡Un libro! ¡Mirad, un libro! ¿Quién lo ha puesto aquí?", "Una piedra. Sólo una piedra. Perdóneme."),
    "windmill":     ("¡Un gigante! ¡Mirad, un gigante!", "Un molino. Sólo un molino."),
    "book_stand":   ("Un libro. ¡Un libro!", "Un atril. Solo un atril."),
    "tome":         ("Un tomo encantado. ¡Mire!", "Un libro viejo. Nada más."),
    "molinos":      ("¡Molinos gigantes!", "Molinos de viento, nada más."),
    "nombre":       ("¡El nombre! ¡El nombre!", "Un nombre. Solo un nombre."),
    "caballeros":   ("¡Caballeros andantes!", "Unos caballeros. Nada más."),
    "posada":       ("¡Una posada encantada!", "Una posada. Nada más."),
    "rocinante":    ("¡Rocinante! ¡Mi noble corcel!", "Un caballo. Solo un caballo."),
    "duena":        ("¡Una dama! ¡Una dama encantada!", "Una dama. Nada más."),
    "pastores":     ("¡Pastores! ¡Un rebaño!", "Unos pastores. Nada más."),
    "yanguesas":    ("¡Yanguesas! ¡Doncellas!", "Unas muchachas. Nada más."),
    "manuscrito":   ("¡El manuscrito! ¡El libro sagrado!", "Un libro viejo. Nada más."),
    "balsamo":      ("¡El bálsamo de Fierabrás!", "Una medicina. Nada más."),
    "caballero_bosque": ("Un caballero del bosque.", "Un hombre en el bosque."),
    "armas_letras": ("¡Armas y letras! ¡Ambas!", "Un libro sobre armas y letras."),
    "leones":       ("¡Leones! ¡Bestias feroces!", "Unos leones. Nada más."),
    "galeotes":     ("¡Galeotes! ¡Prisioneros!", "Unos galeotes. Nada más."),
    "leyenda":      ("¡La leyenda! ¡La historia!", "Una leyenda. Nada más."),
    "innkeeper":    ("¡Un posadero!", "Un hombre. Nada más."),
    "musician":     ("¡Un músico! ¡Música!", "Un hombre con un instrumento."),
}

# Sancho reaction lines (more grounded, shorter)
SANCHO_REACTIONS = {
    "rock":         ("¡Un libro, señor! ¿Y quién lo puso aquí?", "Una piedra, señor. Solo eso."),
    "windmill":     ("¡Un gigante, señor! ¡Un gigante!", "Un molino, señor. Solo un molino."),
    "book_stand":   ("Un libro, señor.", "Un atril, señor."),
    "tome":         ("Un tomo, señor.", "Un libro viejo, señor."),
    "molinos":      ("¡Molinos, señor!", "Molinos de viento, señor."),
    "nombre":       ("¡El nombre, señor!", "Un nombre, señor."),
    "caballeros":   ("¡Caballeros, señor!", "Unos caballeros, señor."),
    "posada":       ("¡Una posada, señor!", "Una posada, señor."),
    "rocinante":    ("¡Rocinante, señor!", "Un caballo, señor."),
    "duena":        ("¡Una dama, señor!", "Una dama, señor."),
    "pastores":     ("¡Pastores, señor!", "Unos pastores, señor."),
    "yanguesas":    ("¡Doncellas, señor!", "Unas muchachas, señor."),
    "manuscrito":   ("¡El manuscrito, señor!", "Un libro, señor."),
    "balsamo":      ("¡El bálsamo, señor!", "Una medicina, señor."),
    "caballero_bosque": ("Un caballero en el bosque, señor.", "Un hombre en el bosque, señor."),
    "armas_letras": ("¡Armas y letras, señor!", "Un libro, señor."),
    "leones":       ("¡Leones, señor! ¡Bestias feroces!", "Unos leones, señor."),
    "galeotes":     ("¡Galeotes, señor! ¡Prisioneros!", "Unos galeotes, señor."),
    "leyenda":      ("¡Una leyenda, señor!", "Una leyenda, señor."),
    "innkeeper":    ("Un posadero, señor.", "Un hombre, señor."),
    "musician":     ("Un músico, señor.", "Un hombre con un instrumento, señor."),
}

for obj_id, (book_line, reality_line) in QUIXOTE_REACTIONS.items():
    BARKS.append(("quixote", f"reaction.{obj_id}.book", book_line))
    BARKS.append(("quixote", f"reaction.{obj_id}.reality", reality_line))

for obj_id, (book_line, reality_line) in SANCHO_REACTIONS.items():
    BARKS.append(("sancho", f"reaction.{obj_id}.book", book_line))
    BARKS.append(("sancho", f"reaction.{obj_id}.reality", reality_line))

# ──────────────────────────────────────────────────────────────────────────────
# ElevenLabs API client
# ──────────────────────────────────────────────────────────────────────────────

class ElevenLabsClient:
    def __init__(self, api_key: str, model_id: str = MODEL_ID):
        self.api_key = api_key
        self.model_id = model_id
        self.session = requests.Session()
        self.session.headers.update({
            "xi-api-key": api_key,
            "Content-Type": "application/json",
        })

    def list_voices(self):
        resp = self.session.get(f"{ELEVENLABS_BASE}/voices", timeout=30)
        resp.raise_for_status()
        return resp.json().get("voices", [])

    def generate(self, voice_id: str, text: str, voice_settings: dict) -> bytes:
        payload = {
            "text": text,
            "model_id": self.model_id,
            "voice_settings": voice_settings,
        }
        resp = self.session.post(
            f"{ELEVENLABS_BASE}/text-to-speech/{voice_id}",
            json=payload,
            timeout=60,
        )
        if resp.status_code == 429:
            raise RateLimitError("Rate limited by ElevenLabs")
        resp.raise_for_status()
        return resp.content


class RateLimitError(Exception):
    pass


# ──────────────────────────────────────────────────────────────────────────────
# Main generation
# ──────────────────────────────────────────────────────────────────────────────

def slug_for(character: str, key: str) -> str:
    """Convert dia.<character>.<category>.<slug> to just <slug> for filename."""
    parts = key.split(".")
    # parts[0] = "dia", parts[1] = character, rest = slug parts
    if len(parts) >= 3 and parts[0] == "dia" and parts[1] == character:
        return "_".join(parts[2:])
    return key  # fallback


def generate_barks(api_key: str, voice_quixote: str, voice_sancho: str,
                   output_dir: Path, dry_run: bool = False,
                   rate_limit_delay: float = 0.25):
    client = ElevenLabsClient(api_key)

    # Map character to voice_id
    voices = {"quixote": voice_quixote, "sancho": voice_sancho}

    # Validate voices exist
    if not dry_run:
        print("Fetching available voices...")
        available = client.list_voices()
        available_ids = {v["voice_id"] for v in available}
        for char, vid in voices.items():
            if vid not in available_ids:
                print(f"ERROR: Voice ID '{vid}' for {char} not found in ElevenLabs account.")
                print(f"Available voices: {[(v['name'], v['voice_id']) for v in available]}")
                sys.exit(1)

    total = len(BARKS)
    print(f"{'DRY RUN: ' if dry_run else ''}Generating {total} bark files...")
    print(f"Output directory: {output_dir.resolve()}")
    print()

    success = 0
    failed = 0

    for i, (character, slug, text) in enumerate(BARKS, 1):
        voice_id = voices[character]
        voice_settings = VOICE_SETTINGS[character]
        out_path = output_dir / character / f"{slug}.wav"

        # Skip if already exists
        if out_path.exists():
            print(f"[{i}/{total}] SKIP (exists): {character}/{slug}.wav")
            success += 1
            continue

        print(f"[{i}/{total}] {character}/{slug}.wav: {text[:60]}...")

        if dry_run:
            # Just create parent dirs, don't call API
            out_path.parent.mkdir(parents=True, exist_ok=True)
            success += 1
            continue

        # Retry logic
        max_retries = 3
        for attempt in range(max_retries):
            try:
                audio = client.generate(voice_id, text, voice_settings)
                out_path.parent.mkdir(parents=True, exist_ok=True)
                out_path.write_bytes(audio)
                success += 1
                break
            except RateLimitError:
                wait = 2 ** attempt
                print(f"  Rate limited. Waiting {wait}s...")
                time.sleep(wait)
            except Exception as e:
                print(f"  ERROR: {e}")
                if attempt == max_retries - 1:
                    failed += 1
                time.sleep(1)

        # Be polite to the API
        time.sleep(rate_limit_delay)

    print()
    print(f"Done: {success} succeeded, {failed} failed out of {total} total.")


def main():
    parser = argparse.ArgumentParser(description="Generate bark audio via ElevenLabs")
    parser.add_argument("--api-key", required=True, help="ElevenLabs API key")
    parser.add_argument("--voice-quixote", required=True, help="Voice ID for Quixote")
    parser.add_argument("--voice-sancho", required=True, help="Voice ID for Sancho")
    parser.add_argument("--output-dir", default=str(OUTPUT_DIR), help="Output directory")
    parser.add_argument("--dry-run", action="store_true", help="Don't call API, just show what would be generated")
    parser.add_argument("--list-voices", action="store_true", help="List available voices and exit")
    parser.add_argument("--delay", type=float, default=0.25, help="Delay between API calls (seconds)")
    args = parser.parse_args()

    if args.list_voices:
        client = ElevenLabsClient(args.api_key)
        voices = client.list_voices()
        print("Available voices:")
        for v in voices:
            print(f"  {v['voice_id']}: {v['name']} ({v.get('category', 'unknown')})")
        return

    output_dir = Path(args.output_dir)
    generate_barks(
        api_key=args.api_key,
        voice_quixote=args.voice_quixote,
        voice_sancho=args.voice_sancho,
        output_dir=output_dir,
        dry_run=args.dry_run,
        rate_limit_delay=args.delay,
    )


if __name__ == "__main__":
    main()
