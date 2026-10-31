# NEXT STEPS — Fiel al Libro

> The plan for the next 12 weeks, and the admin work that has to happen around it.
> Assume you have read `HANDOVER.md` first.
>
> Last updated: **2026-10-24**

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
| 1.1 | **Set up automated cloud backup** | The GDD and the clearance memo are **not** in git — they are irreplaceable. A single disk failure loses them. | 20 min |
| 1.2 | **Read the novel end to end and pick 16 Manifiesto fragments** | This is the highest-value writing task in the project and it cannot be delegated to a machine. See `GDD.md` §20.1. | 4 h |

---

## 2. Phase 1 — the vertical slice (weeks 1–12)

### Week 1–2 — Feel the mechanic

The cheapest possible test of the core idea, before any rig exists.

| # | Task | Done when | Status |
|---|---|---|---|
| 2.1 | Two primitives in the grey box: a **windmill** and a **rock**. Same object, two states. | You can see both. | ✅ `src/world/slice.tscn` |
| 2.2 | A "truth" toggle that swaps the whole scene's look: the windmill becomes a giant; the rock becomes a book. | The screenshot is unmistakable. | ✅ `T` toggles it; `artifacts/slice_book.png` |
| 2.3 | The same toggle in a single world with **two characters**: Quixote reads one state, Sancho the other, and you can see what each is looking at. | You understand the co-op premise without being told. | ✅ `TAB` swaps; the picture changes because *you* changed |
| 2.4 | **Write down what you feel.** Not what you built. Play it 20 times. | A page of notes. | 🟡 7 runs; the "yes, but" verdict is written, the twenty are not |

**Stop here if it isn't working.** Change the premise now. Everything downstream is cheaper.

> **The build:** `res://src/world/slice.tscn` — `tools\play.cmd`.
> `T` flips the world's truth (**and a page of the 1605 original turns across the
> screen**), `TAB` swaps characters, `V` gives Sancho the second sight, `L` pushes
> Quixote's Locura from Lucid to Lost. The tag floating over each object says what the
> character you are *not* driving is looking at (`F2` hides it).
>
> **The reading rule** lives in `src/systems/perception.gd`: the world has one truth, and
> each character makes two things of it. Quixote is made of the Book, Sancho of Reality;
> a character who cannot perceive the world's current truth falls back on the truth they
> are made of. That is the whole mechanic in one function.
>
> **The playtest happened.** Six runs by the owner and one by a stranger; the premise
> holds (run 4: *"less interesting when both see the same thing"*). Six of the eight
> "but"s are fixed; B5 and B6 are named work. Full write-up: `docs/PLAYTEST_NOTES.md` §6.
> **Weeks 1–2 are done. Week 3–4 is next — but the Examine verb (B6) comes first**, because
> two people, one of them a stranger, asked to touch the thing that surprised them.
>
> **And then the playtest happened again, on 20 October 2026**, with two more notes:
> the Examine panel was giving the whole mechanic away (B9 — it now prints one
> character's perception and the one detail that does not add up), and the dodge had
> nothing to dodge (B10 — there is now a training dummy in a walled yard). Full
> write-up: `docs/PLAYTEST_NOTES.md` §7.


### Week 3–4 — Combat, and the two characters

| # | Task | Done when |
|---|---|---|
| 2.5 | `PlayerController`: walk, run, dodge, lock-on, a soft camera | Feels like a souls-like camera, not a platformer — ✅ walk, run, a soft camera, the **dodge** and the **lock-on** are in: `M` picks the target you are looking at, the character turns towards it and walks around it, and the camera frames both |
| 2.6 | Combat: light combo, heavy, dodge, block/parry, stamina, poise, hit reactions | A 60-second exchange with a dummy is fun — ✅ the dodge, the stamina pool, the light and heavy swings, the **lock-on**, the **chain of three**, the **guard**, the **parry** and the **poise** are in; the **animations** are not |
| 2.7 | **Quixote rig** — silhouette, lance, 8 animations (idle, run, roll, 3× light, heavy, block, hit) | He reads as a *mad nobleman*, not a knight in costume — ✅ the **rig and 14 clips** are in, built headless and wired to the game's own states. The *poses* are grey-box: the next pass is the art direction |
| 2.8 | **Sancho rig** — a *different* silhouette, sack + flail, his own 8 animations | You could tell them apart with the sound off — ✅ the **rig and 15 clips** are in, and they share no action with Quixote's |
| 2.9 | `Desvelar` — Sancho strips the Book skin off a target and reveals its Reality form | It is the best-feeling verb in the game — ✅ the **verb** works (`X`, eight seconds, for both characters); the **VFX** are still plain |
| 2.10 | The asymmetry rules: Quixote cannot harm innocents without a Humanity cost; Sancho cannot meaningfully damage | Both rules create a reason to swap mid-fight — ✅ both are in, and the **yard** shows them: a straw man for the innocent, and a dummy that only Quixote can break |
| 2.6b | **A training dummy** — something to fight, something to lock onto, something to hit | ✅ **Built.** A telegraphed swing, a health bar, a yard with walls around it, and `K` to put it back on its feet. `src/world/training_dummy.gd`, `tests/test_training_dummy.gd` |

> **2.7 and 2.8 are the two most under-rated tasks here.** Distinct animation sets sell the
> asymmetry better than any mechanic. A reskinned Quixote makes the whole idea collapse.
>
> **2.6b is a hole in the list, not a new idea.** 2.6 says the combat is done when *"a
> 60-second exchange with a dummy is fun"*, and 2.5 wants a lock-on — but there is no
> dummy in the plan and no enemy until 2.11. Without something to fight, 2.5's lock-on and
> 2.6's hit reactions cannot be built or seen. A dummy is the cheapest thing that makes
> both of them real.
>
> **It was built because the second playtest asked for it**: *"For the dodge it is
> difficult to assess if it's fine at this stage without any enemies or space
> limitations."* A dodge on an empty plain is a dash — you cannot tell a good one from a
> bad one. See `docs/PLAYTEST_NOTES.md` §7, B10.

### Week 5–7 — The Venture, and reading the world

| # | Task | Done when |
|---|---|---|
| 2.11 | **The windmill Venture** - a boss with a Book form and a Reality form, different movesets, different rewards | Fighting it in each form is a different fight - ✅ **built.** The Venture of Montiel stands in the era to the south: the **mill** (it does not walk, its sails deny the ground, it topples) and the **giant** (it walks, it reaches further than your roll). The knight's `T` turns the world over and the boss changes with it; the squire's `X` strips the Book skin and puts it back into its Reality form for eight seconds, which stops the swing it was in the middle of. ✅ **Truth resolution:** killing the Venture in Book truth resolves as TRUTH instead of FORCED and grants a Manifiesto fragment (`bk.ch01.molinos.01`, the windmill passage from chapter I.7-8). ✅ |
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
