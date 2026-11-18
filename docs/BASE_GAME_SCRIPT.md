# BASE GAME — 13-chapter script, on paper

> Written before more build work, as `docs/NEXT_STEPS.md` §3.1 requires.
> This is the **writing pass**: beats, not code. GDD.md §11–12 is the authority;
> this document turns its region table into a chapter-by-chapter spine.
>
> Status: **draft for the owner's pass**. The novel's wording stays in the
> Manifiesto fragments; this document never quotes it.

---

## 1. The shape of a chapter

Every chapter is 10–15 minutes and contains **one mandatory Venture, one
optional case (2–4 anamorphoses), and one Posada** (GDD.md §11.3).

- **Posada in.** Checkpoint, shelf, innkeeper, musician. The chapter is named
  on the manuscript here.
- **Road.** The optional case: a small observation that rewards looking
  without a marker. It teaches the chapter's truth question before the fight.
- **Venture.** The mandatory set-piece. It has a Book form and a Reality form;
  the player can resolve it by force or by truth. Resolution by truth grants a
  Manifiesto fragment.
- **Colophon out.** A page of the author's voice. In Book truth it agrees with
  the player; in Reality truth it corrects them; occasionally it is *wrong on
  purpose*, which is the clue that the world has shifted.

The two chapters of Region IV are the exception: the *Ensayo* (D5). No fight,
no anamorphosis hunt — a Setup screen, 4–6 social rounds, and a consequence.
The Posada still bookends them. Its full script is `assets/writing/ensayo.md`.

Between chapters: a 2.0 s "ride" over the credits-song melody. No seamless
world; vistas, verticality and long sight-lines do the work (§11.4).

---

## 2. The spine at a glance

| # | Region | Novel source | Mandatory Venture | The question it asks |
|---|---|---|---|---|
| 1 | I · Camino | I.7–8, I.4 | The Windmills | Is a giant what you call it, or what it is? |
| 2 | I · Camino | I.8–10 | The Basque | Who gets to decide what a promise is worth? |
| 3 | I · Camino | I.11–14 | The Canting Sea / Galley Slaves | Does freedom mean the same thing to the freed and the free? |
| 4 | II · Sierra Morena | I.16–17 | The Encinados | Can a beating be read as a spell? |
| 5 | II · Sierra Morena | I.22–23 | Montesinos | Is a vision true because it was seen? |
| 6 | II · Sierra Morena | I.29, I.43 | The Bridge / the Flock | Is the dangerous thing the one that charges? |
| 7 | III · El Toboso | I.23–25, I.31 | Enchanted Dulcinea | Can a name make a person? |
| 8 | III · El Toboso | I.37, I.45–46 | The Celestina threads | Is a story true because it was told twice? |
| 9 | IV · Los Riscos | I.50 | *Ensayo* — Setup (no Venture) | Is a test of trust fair when you built it? |
| 10 | IV · Los Riscos | I.50 | *Ensayo* — Resolution (no Venture) | Who is responsible for what you insisted was true? |
| 11 | V · Castillo | I.25–26 | The Knight of the Mirrors | Is an imitation a different thing? |
| 12 | V · Castillo | I.26–27 | The Magician | Does knowing the trick stop it working? |
| 13 | V · Castillo | I.29–30, I.36 | The Duke | Is a joke still a joke when only one party is laughing? |

**Nine Ventures** in the table; GDD §11.2 budgets ~8. The two Ensayo chapters
have none, which is the intended exception. If the schedule tightens, the
Canting Sea and the Celestina threads are the first chapters to compress into
cases (ROADMAP §4 cut tiers), bringing the count to the budgeted eight.

---

## 3. Chapters

### 1 — The Windmills
**Region I · I.7–8 · Venture: the Windmills.**
The proof of the premise and the tutorial. The road case is the rock: examine
it and it is heavier than a stone that size should be. The Venture is the mill
that is a giant; `T` turns the world over and the fight changes with it.
Resolve by truth to claim `bk.ch01.molinos.01`. **Colophon:** agrees in Book,
corrects in Reality. **Exit:** `BooksCollected` +1; region I found.

### 2 — The Basque
**Region I · I.8–10 · Venture: the Basque.**
A promised payment, a merchant who will not honour it, and a blow that lands
differently depending on who is reading the bargain. The optional case is the
inn's ledger: two columns that disagree about what was agreed. The Venture
teaches that a truth resolution is a *choice*, not a reward for winning.
**Colophon:** the first one that is deliberately wrong in Reality truth.

### 3 — The Canting Sea
**Region I · I.11–14 · Venture: the Galley Slaves / the Canting Sea.**
He frees the slaves; they stone him. The chapter's question is whose freedom
is being spoken of. The case is a roadside fragment (`bk.ch14.galeotes`); the
optional anamorphosis is the chain that is not fastened. **Cut first** if the
budget tightens: fold into chapter 2 as an extra case.

### 4 — The Encinados
**Region II · I.16–17 · Venture: the Encinados.**
A beating read as an enchantment. The road case teaches the Sierra's register:
dry mountain, bandits, and a cave that smells of incense. The Venture's two
forms are a gang of bandits and a company of enchanted knights; Sancho's
`Desvelar` is the answer to the wrong question but the right verb.

### 5 — Montesinos
**Region II · I.22–23 · Venture: the Cave of Montesinos.**
The only Venture where the truth resolution is a *vision*, not a kill. He
comes out of the cave having seen things; the world cannot confirm or deny
them. The case is the height of the cave mouth, only visible from the ridge.
**Colophon:** in Book truth, the author swears he saw it too.

### 6 — The Bridge / the Flock
**Region II · I.29, I.43 · Venture: the Bridge.**
The charged thing turns out to be sheep. The chapter pays off the reading rule
taught in chapter 1: the danger was never in the object, it was in the label.
The optional case is a flock-counting anamorphosis visible only in Lectura.
**Cut second** if needed: fold into chapter 4.

### 7 — Enchanted Dulcinea
**Region III · I.23–25, I.31 · Venture: Dulcinea.**
A name invented for a peasant girl becomes a lady who cannot be approached.
The Venture is fought at a distance; closing the gap is the failure state.
The case is the village well: two reflections that disagree about who is
looking. **Colophon:** corrects the player in Book truth for the first time —
the world is no longer reliably on their side.

### 8 — The Celestina threads
**Region III · I.37, I.45–46 · Venture: the threads.**
A story repeated until it is believed. The Venture has no health in Reality
truth: it cannot be killed, only disbelieved. The case is a letter with two
postmarks. **Cut first** alongside chapter 3 if the schedule tightens.

### 9 — The Ensayo: Setup
**Region IV · I.50 · No Venture.**
The Setup screen: tested, examiner, secret, who is told. The player builds the
test. Full slider options and constraints in `assets/writing/ensayo.md`. The
Posada bookends it. **Exit:** the setup is written into the manuscript.

### 10 — The Ensayo: Resolution
**Region IV · I.50 · No Venture.**
4–6 social rounds, then one of six outcomes: TEST_HELD, TEST_BROKEN,
EXAMINER_BROKEN, NOTHING_HAPPENS, PLAYER_CAUGHT, REFUSED. The four that hurt
are the ones the player constructed. PLAYER_CAUGHT unlocks *El Manuscrito*.
All six narrations are in `assets/ensayo/ensayo_script.json`.

### 11 — The Knight of the Mirrors
**Region V · I.25–26 · Venture: the Mirrors.**
An imitation that fights like you. The Book form copies your equipped loadout
and *your UI* — the one boss whose moveset is the player's. The case is a
corridor of false doors. **Colophon:** in Reality truth, the author asks who
taught the mirror to swing.

### 12 — The Magician
**Region V · I.26–27 · Venture: the Magician.**
Knowing the trick does not stop it working. The Venture's tells are visible in
Reality truth and invisible in Book truth — the inverse of every other fight.
The case is a prop that casts a real shadow.

### 13 — The Duke
**Region V · I.29–30, I.36 · Venture: the Duke.**
The final Venture: a joke staged as a court, where only one party is laughing.
Every truth resolution in the game feeds its Verdict. The case is the castle
theatre's empty seats. **Colophon:** the author closes the book and addresses
"you, reader" one last time. **Exit:** endings computed from `BooksCollected`,
both Locura meters, `Humanity`, `Verdicts` and `TheSecondBook` (GDD §12.2).

---

## 4. What this script forbids

- No adapting the plot beat by beat. Thirteen chapters *worth* of story, 48
  quoted passages — not 1,300 pages compressed (GDD D7).
- No Venture without two forms and two different fights.
- No Posada-less chapter, and no chapter without a colophon.
- No writing the novel's wording here. That lives in `assets/manifiesto/*.json`
  and stays verbatim in every language.

## 5. Still owed on this document

- [ ] Owner's pass against the 1605 edition for the novel-source column.
- [ ] Colophon copy for all 13 chapters (currently described by *voice*, not
      written — they are content, like the fragments).
- [ ] Region-passage wording: `docs/map/WORLD_MAP.md` marks it as drafted.
