# TODO — Fiel al Libro

> Three goals per week. No more. Update this file on Monday.
> See `ROADMAP.md` §6 for the weekly ritual.

## Now (Phase 1, weeks 1–2 — does the premise hold?)

- [x] **Week 1–2 grey box** — `res://src/world/slice.tscn`. A windmill that is a giant, a
      rock that is a book, one truth toggle, and two characters reading the same world
      differently. TAB swaps; the world visibly changes because *you* changed.
- [x] The reading rule, pinned down in code and in tests: `src/systems/perception.gd`
- [x] The truth-layer shader actually renders (it had never rendered — see HANDOVER §7.7)
- [x] **First playtest — six runs. The premise holds.** Run 4: *"less interesting when
      both see the same thing"*. The disagreement is the thing, not the filter.
      Full write-up: `docs/PLAYTEST_NOTES.md` §6.
- [x] **Four of the six "but"s fixed and shipped** (same commit): camera-relative
      movement, the camera cuts on a swap instead of sliding, the truth fade 0.9s → 0.5s,
      and the perception tags are now a toggle (`F2`) instead of permanent handholding.

### Still owed, and it is not code

- [ ] **The stranger test.** Runs 18–19 of the playtest, still empty. Tags **off** (`F2`).
      It is the only run that says whether the premise is legible to somebody who has
      not been told. Do this before anything else.
- [ ] **Press `L`.** Nobody has tested the madness. Push Quixote to Lost and then press
      `T`: the world stops changing for him. That is the mechanic behind the meter, and
      it is the most interesting lever in the build with no data on it.
- [ ] **The other fourteen runs.** Six is a sample, not a signal.

### Named work, straight out of the playtest

- [ ] **B5 — Quixote's reaction when he stops seeing the giant.** *"When quixote goes
      back to seeing reality some reaction from his side should happen."* A character
      beat, not a filter change. Barks, week 3–4.
- [ ] **B6 — the Examine verb, pulled forward.** *"Seeing the rock i wanted to interact
      with it, even more the book i expected to be able to interact with it and read
      it."* `Lectura` was week 5–7; the player wants it in the first minute. Either pull
      it forward or build the cheapest possible "examine and read one line" beat.
- [ ] **B3 — the shipped game owes the companion barks.** The tag carried the second
      reading; a label is not a character. The disagreement has to be *told*, not read.

> **The rule:** no more than two more primitives get built until the stranger's run is in
> the observation log in `docs/PLAYTEST_NOTES.md`.

## Still open (admin, not game work — these have long lead times)

- [ ] **Set up the monthly cloud backup** (Blobs / Backblaze B2 / Google Drive) — *you are one disk failure from losing two years*
- [ ] Apply the Steam Direct $100 application
- [ ] **Trademark: manual register searches** (TMview, OEPM, USPTO, WIPO) — 1–2 hours, checklist in `docs/IP_CLEARANCE.md` §4
- [ ] **Trademark: file the COMPOSITE mark** `FIEL AL LIBRO: LA LOCURA Y LA VERDAD` (EUIPO classes 9+41, ~€1,150, then USPTO ~$700). The bare phrase is descriptive and weak. Register `fielallibro.es`/`.com` first.
- [ ] **Play "Hidalgo" and "Dark Bound"** before locking the vertical slice — the closest thematic neighbours in the market
- [ ] Read the novel end to end and pick the first 16 Manifiesto fragments (D7)

## Next (Phase 1 — weeks 3–4, combat)

- [ ] `PlayerController`: walk, run, dodge, lock-on, a soft camera (2.5)
- [ ] Combat: light combo, heavy, dodge, block/parry, stamina, poise, hit reactions (2.6)
- [ ] **Quixote rig** — silhouette, lance, 8 animations (2.7)
- [ ] **Sancho rig** — a *different* silhouette, sack + flail (2.8)
- [ ] Sancho's `Desvelar` — the form-swap VFX (2.9)
- [ ] The asymmetry rules: Humanity cost, and Sancho's control kit (2.10)

## Later (Phase 1, weeks 5–12)

- [ ] The windmill Venture, in both forms (2.11)
- [ ] `Lectura` mode, and three anamorphoses (2.12, 2.13)
- [ ] One Verdict — the world changes layer (2.15)
- [ ] The Posada: checkpoint, the shelf, 2 NPCs, the musician (2.16)
- [ ] The shelf UI, `Biblioteca` wired to real data, and the first book (2.17–2.19)
- [ ] The Manuscript UI shell: title, HUD, dialogue, shelf, codex, pause (2.20)
- [ ] 4 environment kits, the credits song, the min-spec performance pass (2.21–2.23)
- [ ] **Ship the itch.io demo** (2.25)

## Later (after the slice)

- [ ] Region streaming and the chapter graph (`RegionGraph` in `GameState`)
- [ ] The full 15-book library with real passives
- [ ] The Manifiesto facsimile reader (real 1605 text + modern rendering)
- [ ] The 15 Spanish-myth books with correct public-domain passives
- [ ] The *Ensayo* (D5) — the player-staged simulation
- [ ] The endings and the manuscript prologue
- [ ] The 5 region kits beyond the slice
- [ ] Localization to 6 languages (288 Manifiesto modernizations — the long pole)
- [ ] Steam page, capsule art, trailer, wishlist campaign
- [ ] 2.5D pivot evaluation, if the 3D camera fights us

## Parked (decide later, don't forget)

- [ ] Co-op networking (the architecture is already co-op-ready)
- [ ] GodotSteam integration (achievements, cloud saves, rich presence)
- [ ] Steam Workshop for user-made anamorphosis locations
- [ ] The "Códigos" screen — in-game translation import
- [ ] In-game .po import from a file picker
- [ ] Mobile export (probably never — say so out loud and stop thinking about it)
