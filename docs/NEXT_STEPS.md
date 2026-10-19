# NEXT STEPS — Fiel al Libro

> The plan for the next 12 weeks, and the admin work that has to happen around it.
> Assume you have read `HANDOVER.md` first.
>
> Last updated: **2026-10-19**

---

## 0. The one question this project has to answer

> **Is the two-truths mechanic fun?**

Everything in Phase 1 exists to answer that. If the answer is no, you find out in **week 12**,
not in month 24. Do not build the whole game before testing it.

A secondary question, also answered by the slice:

> **Is the combat fun, and can a player read the world without a marker?**

---

## 1. Before you write any game code

These are cheap, they are not game work, and they have long lead times. Do them in parallel with
everything below.

| # | Task | Why it is urgent | Est. |
|---|---|---|---|
| 1.1 | **Set up the monthly cloud backup** | 3-2-1: GitHub + local external drive + a monthly archive to cloud (Blobs / Backblaze B2 / Google Drive). The GDD and the clearance memo are **not** in git — they are irreplaceable. | 20 min |
| 1.2 | **Apply for Steam Direct** ($100) | Approval takes weeks. You cannot create the store page without it. | 30 min |
| 1.3 | **Manual trademark searches** | Checklist in `docs/IP_CLEARANCE.md` §4: TMview (EUIPO + Spain), OEPM, USPTO, WIPO, plus common-law (LinkedIn, Instagram, YouTube), the company register, and domain availability. | 1–2 h |
| 1.4 | **Register `fielallibro.es` / `.com`** | Before anything else claims it. | 10 min |
| 1.5 | **File the EUIPO composite mark** | `FIEL AL LIBRO: LA LOCURA Y LA VERDAD`, classes 9 + 41, ~€1,150. Intent-to-use is fine. The 3-month opposition period starts the day you file. | 45 min |
| 1.6 | **Read the novel end to end and pick 16 Manifiesto fragments** | This is the highest-value writing task in the project and it cannot be delegated to a machine. See `GDD.md` §20.1. | 4 h |
| 1.7 | **Play "Hidalgo" and "Dark Bound"** | The closest thematic neighbours. Play them before you lock the slice's positioning. | 2 h |
| 1.8 | **Read the whole novel's Part I** | You are writing a game about it. Reading summaries is not enough. | 8 h |

> **1.1 is not optional and not a nice-to-have.** Two of the project's most important documents
> exist on exactly one machine.

---

## 2. Phase 1 — the vertical slice (weeks 1–12)

### Week 1–2 — Feel the mechanic

The cheapest possible test of the core idea, before any rig exists.

| # | Task | Done when | Status |
|---|---|---|---|
| 2.1 | Two primitives in the grey box: a **windmill** and a **rock**. Same object, two states. | You can see both. | ✅ `src/world/slice.tscn` |
| 2.2 | A "truth" toggle that swaps the whole scene's look: the windmill becomes a giant; the rock becomes a book. | The screenshot is unmistakable. | ✅ `T` toggles it; `artifacts/slice_book.png` |
| 2.3 | The same toggle in a single world with **two characters**: Quixote reads one state, Sancho the other, and you can see what each is looking at. | You understand the co-op premise without being told. | ✅ `TAB` swaps; the picture changes because *you* changed |
| 2.4 | **Write down what you feel.** Not what you built. Play it 20 times. | A page of notes. | 🟡 protocol written, **the 20 runs are not done** |

**Stop here if it isn't working.** Change the premise now. Everything downstream is cheaper.

> **The build:** `res://src/world/slice.tscn` — `.\tools\godot.ps1 res://src/world/slice.tscn`.
> `T` flips the world's truth, `TAB` swaps characters, `V` gives Sancho the second sight,
> `L` pushes Quixote's Locura from Lucid to Lost. The tag floating over each object says
> what the character you are *not* driving is looking at.
>
> **The reading rule** lives in `src/systems/perception.gd`: the world has one truth, and
> each character makes two things of it. Quixote is made of the Book, Sancho of Reality;
> a character who cannot perceive the world's current truth falls back on the truth they
> are made of. That is the whole mechanic in one function.
>
> **2.4 is not done.** The protocol and the predictions are written
> (`docs/PLAYTEST_NOTES.md`); the observation log is empty and it can only be filled in
> by a human with a keyboard. **Do not build another primitive until it has entries.**


### Week 3–4 — Combat, and the two characters

| # | Task | Done when |
|---|---|---|
| 2.5 | `PlayerController`: walk, run, dodge, lock-on, a soft camera | Feels like a souls-like camera, not a platformer |
| 2.6 | Combat: light combo, heavy, dodge, block/parry, stamina, poise, hit reactions | A 60-second exchange with a dummy is fun |
| 2.7 | **Quixote rig** — silhouette, lance, 8 animations (idle, run, roll, 3× light, heavy, block, hit) | He reads as a *mad nobleman*, not a knight in costume |
| 2.8 | **Sancho rig** — a *different* silhouette, sack + flail, his own 8 animations | You could tell them apart with the sound off |
| 2.9 | `Desvelar` — Sancho strips the Book skin off a target and reveals its Reality form | It is the best-feeling verb in the game |
| 2.10 | The asymmetry rules: Quixote cannot harm innocents without a Humanity cost; Sancho cannot meaningfully damage | Both rules create a reason to swap mid-fight |

> **2.7 and 2.8 are the two most under-rated tasks here.** Distinct animation sets sell the
> asymmetry better than any mechanic. A reskinned Quixote makes the whole idea collapse.

### Week 5–7 — The Venture, and reading the world

| # | Task | Done when |
|---|---|---|
| 2.11 | **The windmill Venture** — a boss with a Book form and a Reality form, different movesets, different rewards | Fighting it in each form is a different fight |
| 2.12 | `Lectura` mode — the screen desaturates, time slows, a page vignette frames the view | It feels like a different mode of attention, not a filter |
| 2.13 | **Three anamorphoses**, each viewable only from a specific vantage point | A player finds one **without a marker**. If they need a marker, the mechanic is broken. |
| 2.14 | `Desvelar` swaps the boss form mid-fight, and the swap is a skill test | A player learns to wait for the window |
| 2.15 | **One Verdict** — Quixote reenacts the scene from the book and the world changes layer | The room changes. Something is different afterwards. |
| 2.16 | The Posada: checkpoint, the shelf, two NPCs, the musician | You want to go back to it |

### Week 8–9 — The shelf and the book

| # | Task | Done when |
|---|---|---|
| 2.17 | The shelf UI — a literal shelf, spine-out, pan along it | It is the prettiest screen in the game |
| 2.18 | `Biblioteca` wired to real data: collect, equip, evict, passives resolve | 5 books, 5 different builds |
| 2.19 | **One book**: *La Leyenda del Tío Andalus* — passive, codex entry, cover | It feels like a find, not a pickup |
| 2.20 | The Manuscript UI shell: title, HUD, dialogue, shelf, codex, pause | Everything is the same book, in-world |

### Week 10–12 — Polish, prove, ship the demo

| # | Task | Done when |
|---|---|---|
| 2.21 | 4 environment kits minimum (field, inn, road, mill) — low-poly, hand-painted, one shader family | It looks like Goya, not like a blockout |
| 2.22 | **Commission the credits song** — "Romance del Caballero y el Escudero", two verses, one per character, ~$200–800 | The melody becomes the thing you hum |
| 2.23 | Performance pass on a **min-spec laptop** | 60 fps at 1080p on a 5-year-old machine |
| 2.24 | Balance pass: is the windmill fight fair on the 3rd attempt? | It is |
| 2.25 | **Ship the demo to itch.io.** Free, public, with a Steam page and a trailer. | Someone you don't know plays it for 10 minutes |

### The slice's success criteria (write them down now, judge honestly at week 12)

- [ ] A stranger plays for 10 minutes without you explaining anything
- [ ] A player says *"wait, the world just changed?"* unprompted
- [ ] A player looks for the anamorphoses **without a marker**
- [ ] The boss is fought in both forms and they are genuinely different
- [ ] The AI companion is funny enough that players miss the real co-op
- [ ] 30 fps on a 5-year-old laptop
- [ ] The itch.io demo has at least one comment that is not from you

---

## 3. After the slice (months 4–6)

Only if the slice passed. Full plan in `ROADMAP.md`.

| # | Task | Notes |
|---|---|---|
| 3.1 | Write the base game's script — **all 13 chapters, on paper** | This is a *writing* project. Do it before you build it. |
| 3.2 | Write the *Ensayo* script (all 6 outcomes) | Early to write, late to build. See `GDD.md` §6.5. |
| 3.3 | Modernize the 48 Manifiesto fragments in Spanish | The long pole. 288 translations across 6 languages. |
| 3.4 | Build the 15 environment kits; produce the 4 hero rigs to quality | The expensive part. |
| 3.5 | Record barks | No full VO. Text-driven with barks. |
| 3.6 | Localize continuously from here, not in a final sprint | |
| 3.7 | Steam page live, capsule art, trailer, wishlist campaign | Target 3,000 wishlists before 1.0 |

---

## 4. Cut list — what dies first if you are behind

Full tiers in `ROADMAP.md` §4. In order:

1. Co-op (already out of the base plan)
2. Dialogue-heavy side quests
3. Scholar's Notes / extra codex commentary
4. Steam Workshop support
5. The "Colofón" between-chapter interstitials
6. The *Ensayo* — **as a whole chapter**, not as a system
7. Six languages → three (es, en, fr)
8. 15 books → 6
9. The credits song's full arrangement → one guitar and a voice

**Never cut:** the two-truths system · both characters · the *Lectura* mechanic · the windmill
Venture · the Manuscript UI · the Locura meter · the Posada and the shelf.

---

## 5. Weekly ritual (a solo dev's substitute for a team)

| When | What |
|---|---|
| **Monday** | Set 3 goals in `TODO.md`. No more. |
| **Daily** | Commit at least once. Screenshot to `artifacts/`. |
| **Friday** | Play the build for 30 minutes as a *player*, not a developer. Write 5 bullet points of what felt bad. |
| **Every 2 weeks** | 45 minutes with 1–2 people who have not seen the game. Record it. Watch it later. |
| **Monthly** | Back up. Review the roadmap. Decide what to cut. |
| **Quarterly** | Re-read the GDD. Ask *"is this still the game I want to make?"* If no — pivot now, not at month 30. |

---

## 6. Open decisions carried into Phase 1

These are answered in the GDD (D1–D7) but they have practical consequences in the slice:

| Question | Decided | Consequence in the slice |
|---|---|---|
| Is the base game's subject the madness or the book? | **The madness** | No "wacky Spanish comedy" tone. Comedy lives in the barks. |
| Is the truth layer global or per-player? | **Global** | One shader uniform, one save field. |
| Swap or simultaneous control? | **Swap** | The AI companion is a real character, not a dummy. Budget time for it. |
| Can you attack innocents? | **Yes**, costs Humanity | Implement the Humanity counter in the slice — it feeds the ending logic. |
| Is the Curious Impertinent a staged simulation? | **Yes** | Not in the slice. Write the script in Phase 2 so it is ready when the slot opens. |
| The name? | **"Fiel al Libro"** | File the composite mark. See `HANDOVER.md` §8. |
| How much 1605 text? | **48 fragments** | Selection and Spanish modernisation are a Phase 2 task. Start reading now (1.6). |
