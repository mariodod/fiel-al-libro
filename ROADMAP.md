# FIEL AL LIBRO — Roadmap

> A 3-year plan for one solo developer, with a shippable vertical slice in 12 weeks.
> Every phase ends with something **public** — a playable build, a demo, a post.

---

## 1. The honest scope

The full vision (5 regions, 24 enemies, 15 books, 3–4 DLCs, 2-player co-op, 15 languages) is a
**4–6 year project for 3–5 people**. For one person, it is a 3-year project *if* you cut co-op and
sharply reduce the base game.

**This plan assumes:** no co-op at launch, 6 languages at launch, base game ~8–10 hours, 3 DLCs
post-launch (DLC 1 and 2 as the reliable earners, DLC 3 as the artistic statement).

**Target launch: month 30 from now.**

---

## 2. The Vertical Slice (weeks 1–12) — *the most important 12 weeks of the project*

The slice answers exactly one question: **is the two-truths mechanic fun?**

If it isn't, you will find out in month 3 instead of month 24. That is the entire purpose of this
phase, and everything else is secondary.

### Slice content

| Element | Scope |
|---|---|
| **Location** | The road to the inn of Villanueva: a wheat plain, a dry riverbed, the inn, a windmill. One contiguous 10-minute area. |
| **Characters** | Quixote (full kit) and Sancho (full kit). AI companion for the other one. |
| **Enemies** | 4: a "Reality" thug, a "Book" giant (the same enemy, two forms), a flock of sheep, a windmill-sail. |
| **Boss (Venture)** | **The Windmills.** A "boss" that is four sails. Reality form: you fight a mill's rotating gear-and-stone. Book form: it is a giant that fights with the wind. Sancho's `Desvelar` swaps it. |
| **Investigation** | 3 anamorphoses, all viewable from a specific vantage point. One is required for the boss (it reveals the boss's weak point), two are optional. |
| **Verdict** | One moment: Quixote reenacts the scene from the novel at the windmill and the world shifts layer. It changes the boss. |
| **Locura** | Implemented, with 2 thresholds and visible effects. |
| **Posada** | One: checkpoint, the shelf, 2 NPCs, the musician. |
| **Books** | 1 collectible: *La Leyenda del Tío Andalus*. One passive. |
| **UI** | The Manuscript shell: title, HUD, dialogue, the shelf, the codex, the pause menu. |
| **Music** | The credits song, commissioned, in full, plus 1 region variant. |
| **Save** | Working, 1 slot, autosave at the Posada. |
| **Languages** | ES + EN only. **But the PO pipeline must already work.** |
| **Co-op** | **None.** The `CharacterPawn` interface must already allow it. |

### Slice success criteria (be honest, write them down now)

- [ ] A stranger plays for 10 minutes without you explaining anything.
- [ ] At least one player says *"wait, the world just changed?"* unprompted.
- [ ] At least one player looks for the anamorphoses **without a marker**.
- [ ] The windmill boss is fought in **both** forms and they're genuinely different.
- [ ] The AI companion is funny enough that players miss the "real" co-op.
- [ ] 30 fps on a 5-year-old laptop.

### Slice deliverables

- [ ] Free itch.io demo, public
- [ ] Steam page created, capsule art, trailer
- [ ] Discord / community started
- [ ] A written post-mortem

---

## 3. Phase plan

### Phase 0 — Foundation · weeks 1–4
Setup, tooling, the truth-layer shader, the data-driven architecture, the save system, the
localization pipeline, the character-pawn interface.
**Deliverable:** a grey-box scene where you can walk around, switch characters, and see the world
flip between Reality and Book. Ugly is fine.

### Phase 1 — Vertical Slice · weeks 5–12
See above.
**Deliverable:** a public demo.

### Phase 2 — Pre-Production · months 4–6
- Lock the full design. Write the chapter list. Write the script for the base game (this is a
  *writing* project — do it on paper before you build it).
- **Select and modernize the 48 Manifiesto fragments (D7).** The Spanish modernizations are done
  here, in full, by someone who loves the novel. This is the highest-value writing task in the
  project and it cannot be delegated to a machine.
- Write the **Ensayo** script (D5, `GDD.md` §6.5) — all 6 outcomes, all intervention sets. It is
  the chapter that proves the thesis, so it gets written *early* even though it is built late.
- Build the 15 environment kits and the 4 hero rigs to production quality.
- Commission the credits song. Record barks.
- **Do a solo playtest every 2 weeks. Write down every frustration.**
- **Milestone:** a design document for the whole base game, signed off by you.

### Phase 3 — Production · months 7–18
- Regions I–V, 13 chapters, 8 Ventures, the full enemy roster.
- The 15 books and the Manifiesto reader.
- **The Ensayo** (Region IV, ch. 11–12) — the last system built, the first thing cut.
- The endings and the manuscript prologue.
- Localization to 6 languages, starting at month 12 (translate as you build, never in a sprint at
  the end). The 288 Manifiesto modernizations are the long pole — spread them across months 12–18.
- **Milestone:** "alpha" — all content reachable, all systems in, ugly but complete.

### Phase 4 — Beta · months 19–24
- Polish, performance, balancing, bug fixing, localization QA, the "signed copy" of the Manifiesto.
- Steam page live, demo out, wishlist campaign.
- **Milestone:** "beta" — feature complete, publicly playable.

### Phase 5 — Release · months 25–30
- Content lock, final QA, console... no, PC only. Steam release.
- 2 weeks of emergency patch buffer.
- **Ship.** Then sleep for a week.

### Phase 6 — DLCs · months 31–48
- **DLC 1** (El Segundo Libro) — month 36
- **DLC 2** (Las Historias de los Libros) — month 42
- **DLC 3** (La Locura se Contagia) — month 48 *(only if the base game earned it)*
- **DLC 4** (El Cautivo) — stretch

---

## 4. Scope tiers — what gets cut, in what order

Keep this list. When you're behind, cut **from the bottom**. Never cut from the top without a
very good reason.

**Never cut (Tier 1 — the game):**
1. The two-truths system and the Verdict
2. Quixote and Sancho, both playable, with distinct kits
3. The `Lectura` investigation mechanic
4. The windmill Venture (or an equivalent)
5. The Manuscript UI
6. The Locura meter
7. The Posada hub and the shelf

**Cut late (Tier 2 — expensive to rebuild):**
8. The mounts (Rocinante, Dapple)
9. The Manifiesto facsimile reader
10. The endings (keep 1, not 3)
11. Regions IV and V (shrink the base game to 3 regions)

**Cut early (Tier 3 — nice, not essential):**
12. The 15 books → 6 books
13. The credit song's full arrangement → a single guitar + voice
14. The 6 languages → 3 languages (es, en, fr)
15. The New Game+ / "Fiel al Libro+" mode
16. **The Ensayo** (`GDD.md` §6.5) — the player-staged simulation and its 4 non-default outcomes.
    Cut it as a *whole chapter*, not as a system; the rest of the game runs without it.

**Cut immediately (Tier 4 — the first things to go when you're drowning):**
17. The co-op (already out of the base plan)
18. The dialogue-heavy side quests
19. The Scholar's Notes / extra codex commentary
20. The Steam Workshop support
21. The "Colofón" between-chapter interstitials (keep the fragments, drop the connective prose)

---

## 5. The first 90 days — a concrete checklist

### Weeks 1–2: Tooling
- [ ] Create the GitHub repo, .gitignore, LFS config
- [ ] Install Godot 4.x stable, Blender 5.2 LTS, Git LFS, Audacity
- [ ] Set up the folder structure from `TECH_STACK.md` §3.1
- [ ] GitHub Actions: headless import + export to Windows
- [ ] Write the Blender → Godot import preset guide; verify on a clean clone
- [ ] Set up monthly cloud backup
- [ ] **Start the Steam Direct $100 fee application** (takes weeks to be approved)
- [ ] **Trademark check on "Fiel al Libro"** (EU + US, classes 9 & 41) and check for existing games
      with the same name — *D6, `GDD.md` §21*. Blocking for the store page.
- [ ] Write the game's one-page pitch and put it in the repo root

### Weeks 3–4: The engine's spine
- [ ] `EventBus`, `GameState`, `Locura`, `TruthLayer` autoloads + unit tests
- [ ] The truth-layer shader: 3 looks, one uniform, tested on primitives
- [ ] `CharacterPawn` interface + a capsule dummy implementing it
- [ ] Character switch (TAB) with a dummy swap
- [ ] Third-person camera + a basic controller
- [ ] PO pipeline: extractor script, `messages.pot`, es/en/fr, one dialogue line
- [ ] Save system: atomic write, version field, 1 slot
- [ ] **Commit to the repo daily.** You will need the history.

### Weeks 5–8: The slice's systems
- [ ] Combat: light/heavy/dodge/block, stamina, poise, hit reactions
- [ ] 4 enemy archetypes (rig + AI + the two forms)
- [ ] `Desvelar` (Sancho's reveal) — the form-swap VFX
- [ ] `Lectura` mode: the screen-space highlight, one anamorphosis, the examine interaction
- [ ] The Posada: checkpoint, the shelf, 2 NPCs, the musician
- [ ] Rocinante (one mount) — riding + dismounting
- [ ] The Verdict system: one scripted truth-shift

### Weeks 9–12: The slice's content
- [ ] The windmill Venture, both forms
- [ ] 3 anamorphoses placed
- [ ] The Manuscript UI shell (title, HUD, dialogue, shelf, codex)
- [ ] The windmill plain + inn + windmill environment kit
- [ ] The first book (*El Tío Andalus*) and the shelf loadout
- [ ] The commissioned credits song
- [ ] Polish pass, performance pass on a min-spec laptop
- [ ] **itch.io demo release**
- [ ] **The post-mortem**

---

## 6. Weekly ritual (a solo dev's substitute for a team)

| When | What |
|---|---|
| **Monday** | Set 3 goals for the week. No more. Write them in the repo's `TODO.md`. |
| **Daily** | Commit at least once. Screenshot to `artifacts/` (you will want the history). |
| **Friday** | Play the build for 30 minutes as a *player*, not a developer. Write 5 bullet points of what felt bad. |
| **Every 2 weeks** | A 45-minute session with 1–2 other people who haven't seen the game. Record it. Watch it later. |
| **Monthly** | Back up + review the roadmap + decide what to cut. |
| **Quarterly** | Re-read the GDD. Ask "is this still the game I want to make?" If no — pivot now, not at month 30. |

---

## 7. Risk register

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| 1 | The two-truths mechanic isn't fun | Medium | **Fatal** | Vertical slice by week 12. Kill or pivot by week 13. |
| 2 | Scope explosion | **High** | High | Tiered cut list. Write the chapter list before building. |
| 3 | Burnout | **High** | High | Ship the demo at month 3. Take breaks. One project at a time. |
| 4 | The project is lost (disk/accident) | Low | **Fatal** | 3-2-1 backups, automated. |
| 5 | Art quality isn't good enough | Medium | High | Invest in ONE art reference, one shader, one palette. Restraint beats ambition. |
| 6 | The Spanish-speaking community rejects the tone | Medium | High | Two sensitivity readers from month 2. Show them the slice. |
| 7 | Localization eats the schedule | Medium | Medium | Translate continuously from month 12, not in a final sprint. |
| 8 | 3D tooling in Godot slows me down | Medium | Medium | Simplify the camera and animations. Consider a 2.5D pivot. |
| 9 | Co-op gets promised and can't be delivered | Medium | Medium | Publicly say "co-op is a stretch goal" until the slice proves the architecture. |
| 10 | The novel is 1,300 pages and I try to adapt all of it | **High** | High | 13 chapters. The *Manifiesto* quotes the rest. Adapt fragments, not the whole book. |
| 11 | Financial: the project runs out of money | Medium | High | Zero-cost pipeline. Never buy assets before the slice. Commission only what's essential (the song). |
| 12 | Legal: a copyrighted adaptation creeps in | Low | High | IP checklist in `GDD.md` §19. Verify every asset's licence. |

---

## 8. The three things that will make or break this

1. **Ship the demo in 12 weeks.** A finished, ugly, public 10-minute demo beats a beautiful private
   one. It converts to wishlists and it keeps you honest.
2. **One shader, one palette, one reference artist.** "Stylized painterly" is a *discipline*, not a
   mood board. Constrain yourself to Goya + Okami + a single ochre palette and it will look
   coherent. Ambition here is how a solo dev ends up with 40 half-done asset styles.
3. **Write the game before you build it.** A souls-like with a bad script and good systems is
   forgettable. A souls-like with a great script and prototype systems is a game. The writing is
   cheap right now and expensive later — do it in months 4–6 while the engine is still warm.
