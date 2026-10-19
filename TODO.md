# TODO — Fiel al Libro

> Three goals per week. No more. Update this file on Monday.
> See `ROADMAP.md` §6 for the weekly ritual.

## Now (Phase 0 — Foundation)

- [x] Godot 4.7 project opens and runs the grey-box scene
- [x] Input map written into `project.godot` (`src/tools/setup_input_map.gd`)
- [x] Autoload spine: EventBus, GameState, TruthLayer, Locura, Loc, Memoria, Biblioteca, Manuscrito, AudioDirector
- [x] Data-driven `Resource` classes: Character, Enemy, Form, Ability, Book, Chapter, Venture
- [x] Truth-layer shader (the whole art direction in one uniform)
- [x] `CharacterPawn` + `PlayerController` + `CompanionAI` — the D3 architecture
- [x] Save system with atomic writes and version migration
- [x] PO pipeline + `sync_locales.gd` + `setup_translations.gd` + locale key-parity test
- [x] Test harness and 8 suites, 109 assertions, all green
- [x] CI: import check → tests → Windows + Linux exports
- [x] Git + Git LFS, public GitHub repo, CI green
- [x] Godot export templates installed locally; Windows + Linux builds produced
- [ ] **Set up the monthly cloud backup** (Blobs / Backblaze B2 / Google Drive) — *you are one disk failure from losing two years*
- [ ] Apply the Steam Direct $100 application
- [ ] **Trademark check on "Fiel al Libro"** (EU + US, classes 9 & 41) — blocking for the store page (D6)
- [ ] Read the novel end to end and pick the first 16 Manifiesto fragments (D7)

## Next (Phase 1 — Vertical Slice, weeks 5–12)

- [ ] Combat: light / heavy / dodge / block, stamina, poise, hit reactions
- [ ] 4 enemy archetypes, each with a Book form and a Reality form
- [ ] Sancho's `Desvelar` — the form-swap VFX. This is the best verb in the game; make it feel good
- [ ] `Lectura` mode: the screen-space highlight and one anamorphosis you must view from a spot
- [ ] The Posada: checkpoint, the shelf, 2 NPCs, the musician
- [ ] Rocinante: riding and dismounting
- [ ] The Verdict system: one scripted truth-shift
- [ ] The windmill Venture, in both forms
- [ ] The Manuscript UI shell: title, HUD, dialogue, shelf, codex
- [ ] 15 environment kits (or at least the 4 the slice needs)
- [ ] The commissioned credits song
- [ ] **Ship the itch.io demo**

## Later

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
