# Fiel al Libro

**A souls-like action RPG where the world runs on two simultaneous truths, and you play both the
mad knight and his sane squire.**

> *Don Quijote de la Mancha* · solo developer · stylized painterly 3D · PC (Steam) first ·
> Godot 4 · 6 languages at launch, 15 possible

---

## What's here

| File | What it is |
|---|---|
| **[`HANDOVER.md`](HANDOVER.md)** | **Start here.** Full orientation for anyone picking this up cold: what's built, the architecture, the hard-won Godot gotchas, and the IP situation. |
| **[`docs/NEXT_STEPS.md`](docs/NEXT_STEPS.md)** | The plan for the next 12 weeks, task by task, with acceptance criteria. |
| [`GDD.md`](GDD.md) | The game design. Two-truths system, characters, the *Lectura* investigation mechanic, combat, progression, the library of Spanish myths, bestiary, regions, the 4 DLCs, the credits song, art & audio direction, cultural-sensitivity and IP rules. *(Private — on the owner's machine, gitignored and kept out of git history.)* |
| [`TECH_STACK.md`](TECH_STACK.md) | Engine choice and why, engine configuration, project architecture, asset pipeline, performance budgets, save system, testing/CI, Steam, and the **full i18n pipeline**. |
| [`ROADMAP.md`](ROADMAP.md) | 12-week vertical slice, 30-month plan, scope-cut tiers, weekly rituals, risk register. |
| [`TODO.md`](TODO.md) | The live task list. |
| [`locale/`](locale/) | Working sample translation files: `messages.pot` (template), `en.po`, `es.po`, `fr.po`. |
| [`assets/manifiesto/`](assets/manifiesto/) | Sample "Book layer" content structure — how a real 1605 fragment is stored, sourced, and modernized per language. |
| [`tools/`](tools/) | `setup.ps1` (one-command machine setup) and `godot.ps1` (finds the Godot binary and forwards args). |

---

## The idea in 60 seconds

Every object in the world has **two states**:

- **Book Truth** — what the 1605 novel says. Windmills are giants. Dulcinea is an enchantress.
- **Reality Truth** — what actually happened. Windmills are windmills. Dulcinea is a farm girl.

Don Quixote sees Book Truth. Sancho sees Reality Truth. **You play both, and you switch between
them freely.** The game is about a mind that spends too long in either truth and stops being able
to tell them apart.

That single decision generates everything else:

- **Investigating visual references** = spotting anamorphoses that prove which truth you're in.
- **Combat** = Quixote fights huge and can't harm innocents; Sancho is weak but can strip the
  "book skin" off an enemy and reveal its real form.
- **Collectible books** = a literal bookshelf of Spanish myths (the *Cid*, *Don Pelayo*, *La
  Celestina*) whose passives teach you different ways of seeing. Your loadout is your library.
- **DLC 3** = *La Locura se Contagia*. Sancho cures Quixote's madness one cure at a time, and each
  cure permanently removes one of his abilities — while Sancho slowly starts seeing windmills as
  giants.

---

## The five decisions that shape everything

| Decision | Choice | Why |
|---|---|---|
| **Engine** | **Godot 4.x** | Zero cost, 1 GB install, runs on your laptop, fast iteration, MIT, and the stylized painterly look is the one category where UE5's headline features matter least. |
| **Genre lane** | **Dark Souls, not Skyrim** | A seamless continent is a team-scale problem. You get Skyrim's *sense of scale* via verticality, vistas, layered fog and fast-travel instead. |
| **Single-player** | **Swap between Q and S freely**; the other is a full AI companion | Solves the co-op design in single player, and makes co-op a *networking* problem later rather than a redesign. |
| **Progression** | **Perception, not damage numbers** | Level-ups unlock new things you can *notice*. Progression is the anti-grind argument. |
| **Localization** | **Two string layers** | The 1605 Spanish original is *content* (identical in every build); a modernized rendering is localized. The game stays "faithful to the book" in any language. |

---

## The seven locked decisions (D1–D7)

Settled and binding — see [`GDD.md` §21](GDD.md) for the reasoning behind each.

| # | Decision | Consequence in one line |
|---|---|---|
| **D1** | The subject is the **madness**; the book is the frame | No "wacky Spanish comedy" tone — the comedy lives in the barks, never in the frame. |
| **D2** | The truth layer is **global** — one world, two readings | One shader uniform, one save field, and co-op stays possible. |
| **D3** | **Swap** between characters; the other is a full AI companion | `CharacterPawn` is the only way to touch a character. The switch is a verb, not a menu. |
| **D4** | Yes, you can **attack innocents** — it costs **Humanity** | The world feels dangerous and the player feels responsible. |
| **D5** | The Curious Impertinent is a **player-staged simulation** (*El Ensayo*) | A new case type: the player builds the betrayal, then lives in it. See [`GDD.md` §6.5](GDD.md). |
| **D6** | The name is **"Fiel al Libro"**; the hook goes in the metadata | Spanish title, English short description, searchable tags. Trademark check pending. |
| **D7** | **48 fragments** of the 1605 text in the base game | 288 literary translations across 6 languages, starting at month 12. See [`GDD.md` §20.1](GDD.md). |

---

## Getting started

```bash
git clone https://github.com/mariodod/fiel-al-libro.git
cd fiel-al-libro
powershell -ExecutionPolicy Bypass -File tools\setup.ps1
```

That checks git/LFS/Godot, imports the project, runs the test suite, and prints the four things
that still need a human. Then:

```bash
tools\play.cmd   # play the grey-box
```

> **Use `tools\play.cmd`, not `.\tools\godot.ps1 <scene>`, to play.** Windows decides what
> to do with a `.ps1` and a `.tscn` by file association, and on some machines that means
> the scene gets handed to a text editor or a notes app instead of to Godot. A `.cmd` is
> executed natively by `cmd.exe`, with no association and no execution policy in the way.
> `play.cmd` takes a scene as an argument, so `tools\play.cmd res://src/world/main.tscn`
> works too.

**The grey-box scene** is the vertical slice's week 1–2 build: a windmill that is a giant
in the Book, a rock that is a book in the Book, and two characters reading the same world
differently. Walk around, press **TAB** to swap Quixote and Sancho, press **T** to flip the
world between Reality and Book, **V** for Sancho's second sight, **L** to push Quixote's
Locura from Lucid to Lost. Ugly on purpose — it proves the two core systems work.

**Tools in this repo** (all run headless, no extra dependencies):

| Command | What it does |
|---|---|
| `.\tools\godot.ps1 --headless res://tests/test_runner.tscn` | Runs the test suite. Exit 0 = green. |
| `.\tools\godot.ps1 --headless --script res://src/tools/setup_input_map.gd` | Writes the input map into `project.godot`. |
| `.\tools\godot.ps1 --headless --script res://src/tools/setup_translations.gd` | Registers `locale/*.po` with the engine. **Run after adding a language** — without it every `tr()` silently returns the raw key. |
| `.\tools\godot.ps1 --headless --script res://src/tools/sync_locales.gd` | Brings every `locale/*.po` in line with `messages.pot`; reports orphans and duplicates. |
| `.\tools\godot.ps1 --headless --export-release "Windows Desktop" build/FielAlLibro.exe` | Builds. Needs export templates (Editor → Manage Export Templates). |

> `tools/godot.ps1` exists because winget may not put Godot on PATH (it needs admin rights to
> create the alias). Use it instead of calling `godot` directly.

---

## Start here

1. Read [`GDD.md` §4 (the two-truths system)](GDD.md) and [`GDD.md` §6.5 (the Ensayo)](GDD.md).
2. Build the 12-week vertical slice in [`ROADMAP.md` §2](ROADMAP.md) — the windmill boss, three
   anamorphoses, one Verdict, one book, the Manuscript UI, the commissioned song.
3. **Ship it to itch.io as a free demo in week 12.** If the mechanic isn't fun, you'll know in month
   3 instead of month 24.

---

## Status

| | |
|---|---|
| Design | v0.2 — first draft complete, **D1–D7 locked** |
| Tech plan | v0.1 |
| Roadmap | v0.1 |
| Code | none yet |
| Prototype | not started |
| Next milestone | Week 1–2 tooling (see `ROADMAP.md` §5) |
