# TODO — Fiel al Libro

> Three goals per week. No more. Update this file on Monday.
> See `ROADMAP.md` §6 for the weekly ritual.

## Now (Phase 1, weeks 1–2 — does the premise hold?)

- [x] **Week 1–2 grey box** — `res://src/world/slice.tscn`. A windmill that is a giant, a
      rock that is a book, one truth toggle, and two characters reading the same world
      differently. TAB swaps; the world visibly changes because *you* changed.
- [x] The reading rule, pinned down in code and in tests: `src/systems/perception.gd`
- [x] The truth-layer shader actually renders (it had never rendered — see HANDOVER §7.7)
- [ ] **Play it 20 times and fill in `docs/PLAYTEST_NOTES.md`.** The build is the easy
      part. This is the task.
- [ ] **Show it to two people who have not seen it. Record it. Watch it later.**
- [ ] Write down the "but" — every "but" they come back with is a named week of work.

> **The rule:** no more than two more primitives get built until the observation log in
> `docs/PLAYTEST_NOTES.md` has entries in it.

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
