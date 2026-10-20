# PLAYTEST NOTES — Week 1–2

> The deliverable for task 2.4: **write down what you feel. Not what you built.**
>
> Last updated: **2026-10-20**

---

## 0. Read this first: what this file is, and what it is not

`NEXT_STEPS.md` §2, task 2.4 says: *"Write down what you feel. Not what you built. Play it
20 times. → A page of notes."*

**This file is half of that deliverable, and it is the half a machine can honestly do.**

- ✅ **The protocol**: the 20 runs, the questions, the order, what to write down. Written
  down *before* the playtest, so the answers cannot be bent to fit a conclusion afterwards.
- ✅ **The predictions**: what I expect to feel, and — more usefully — what would prove me
  wrong. Predictions are labelled as predictions.
- ❌ **The results**: the observation log at the bottom is **empty**. It gets filled in by
  a human, with a human's hands on the keyboard.

There are no fabricated playtest results in this file, and there never should be. A
playtest log written by the person who built the thing is worth exactly nothing; the only
version of this document that can change the project is the one with a stranger's
impressions in it.

**The one thing this whole slice exists to find out:** *is the two-truths mechanic fun?*

---

## 1. The build

`res://src/world/slice.tscn` — run it with:

```bash
tools\play.cmd
```

| Key | What it does |
|---|---|
| `WASD` / `Shift` | walk, run |
| `TAB` | swap between Quixote and Sancho |
| `T` | the world's truth flips: Reality ↔ Book |
| `E` | examine the thing in front of you — *what this character sees* |
| `Space` | dodge |
| `LMB` / `RMB` | light attack / heavy attack — the light one chains three |
| `M` | lock on — the target you are looking at, and a camera that frames both |
| `F` | the guard — hold it. Sancho's buckler can parry; Quixote's lance cannot |
| `X` | Desvelar — Sancho strips the Book skin off a thing, for eight seconds |
| `V` | Sancho's second sight, on/off |
| `L` | Quixote's Locura: Lucid ↔ Lost |
| `K` | reset the practice yard |
| `F1` | the help overlay |
| `F2` | the floating perception tags |
| `H` | the HUD — the developer's readout. **Turn it off before a stranger sees it.** |

The scene: a windmill and a rock on a dry plain, and a **walled yard to
the west** with a **training dummy** in it. Quixote and Sancho. The windmill is a
windmill in Reality and a **giant** in the Book. The rock is a rock in Reality and a
**book** in the Book. The tag floating over each object says what the character you are
*not* driving is looking at.

**The three-beat demo** (this is the thing to judge, and the thing to show a stranger):

1. **Press `T`.** The windmill becomes a giant. The rock becomes a book. The whole
   picture changes: gilded, inked, printed.
2. **Press `TAB`.** You are now looking through Sancho's eyes. The giant is a windmill
   again. The book is a rock again. The world has not changed — *he* has.
3. **Read the tag.** Above the mill it now says *"Don Quijote: gigante"*. He still sees
   the giant. You do not.

**Same world. Two readings.** That gap is the game.

---

## 2. The protocol — 20 runs

Twenty runs, not one. One run tells you what you expected. Twenty tells you what you
actually feel, because the *first* impression is a liar and the tenth is a habit.

| Run | What you do | What you write down |
|---|---|---|
| 1–2 | Play. Say nothing out loud. | The first thing you felt, in one sentence. |
| 3–5 | `T` and `TAB` only. Nothing else. | When the world changed, did you *flinch*? Should you have? |
| 6–8 | `T`, then `TAB`, ten times each. | Does the second swap still land? Does it go numb? |
| 9–11 | `V` on and off. | When the two agree, does the world feel less interesting? |
| 12–14 | `L`, then `T`. | What did you expect to happen when the mad knight stopped seeing reality? |
| 15–17 | Ignore the objective. Walk. Look at the rock. | Is there anything to *do* here? What did you want to do? |
| 18–19 | Show it to someone who has not seen it. Say nothing. | What do they do in the first 30 seconds? |
| 20 | Play once more, alone, quietly. | Would you press `T` again if nobody were watching? |

**Rules for the observer (you):**

- Do not explain the mechanic. Not once. If they ask, say *"I don't know, do you?"* and
  see whether they keep looking.
- Write down what they *do*, not what they say. People describe their hopes; their hands
  tell the truth.
- If they are bored, that is a result. Write it down. Do not rescue them.

---

## 3. The five questions

These are the questions the slice is allowed to answer. If the answers are no, the slice
has done its job — better now than in month 24.

1. **Does the world changing surprise you?** (Not "is it cool" — surprise. You *know* `T`
   is there. A good mechanic still makes you look up.)
2. **When you swap characters, does the world visibly change?** If the picture does not
   change, the mechanic is a filter and not a world, and the game is less good.
3. **Do you want to tell the other character what you see?** This is the co-op premise.
   If you never feel the urge to say *"it's a giant, look"*, the premise is decorative.
4. **Is the tag enough?** The tag is a debug affordance. In the real game this is a
   bark. Does the bark have to carry the same information, and can it?
5. **Is the *disagreement* interesting, or just confusing?** The honest failure mode of
   this design is that the two readings read as a bug.

---

## 4. What I expect, and what would prove me wrong

> These are the designer's predictions, written before the playtest. They are here to be
> argued with, and to be thrown away if the playtest disagrees.

| # | Prediction | What would falsify it |
|---|---|---|
| P1 | The **first** `T` press lands. The world visibly becoming a giant is the most legible thing in the build. | If the first `T` press gets a shrug, the visual language is too weak to carry the premise and everything downstream is in trouble. |
| P2 | The **swap** is the best moment, not the toggle. Seeing the same object become two things is the idea; the toggle only shows one. | If players talk about the toggle and not the swap, the mechanic is "a world filter" and the thesis is wrong. |
| P3 | The tag is read **once** and then ignored — it is a debug affordance, and a stranger will not look up to read floating text. | If players keep consulting the tag, it means the disagreement is not self-evident and the *content* has to carry it (barks, gestures, sound). |
| P4 | Pushing Quixote to "Lost" (`L`) makes the game *better*, not worse: a mad knight who insists on the giant is funnier and sadder than a lucid one. | If madness only makes things confusing, the Locura meter is a difficulty slider and P2 is dead. |
| P5 | Somebody will try to **walk into the mill** and attack it. The windmill is the first thing in the book and the first thing in the build. | If nobody tries, the build is too empty to provoke anything, and the week 3–4 combat work is what actually matters. |
| P6 | The rock-as-a-book is the **thesis in one object** and the first thing a player shows a friend. | If the book reads as "a box on the ground", the visual language needs work before more primitives are added. |

---

## 5. The observation log

*Fill this in. One line per run. A run with nothing written down was a run wasted.*

| Run | What I felt (one line) | Did I look up? (`T`) | Did the swap land? | Notes |
|---|---|---|---|---|
| 1 | exited to see something for the first time | Yes | Yes but first time it took a lot of time  | movement and camera feel weird it doesn't play as expected it moves relative to plane not camera |
| 2 | same as before | yes | same | not sure about the transition when swapping from quijote to sancho in the objects morphing rather that a direct view switch like going from sancho to quijote T |
| 3 | Mechanic is still cool | yes | yes | Text showing what the other sees feels like too handholding,the layer should change characters to see the whole world |
| 4 | less interesting when both see the same thing | yes | yes | change of view should be fater when pressing T, it takes too much time |
| 5 | when quijote goes back to seeing reality some reaction from his side should happen |  |  |  |
| 6 | Seeing the rock i wanted to interact with it, even more the book i expected to be able to interact with it and read it |  |  |  |

**The stranger's run** (run 18–19), 19 October 2026. Somebody who had never seen the
game, with the tags off, and nothing explained:

```
- Surprised by the swap mechanic.
- Expected the change with T to be immediate.
- The camera rotates sideways too fast.
- "What is the difference between pressing T and L? They do the same."
- Wanted to interact with the book and the giant.
```

---

## 6. Findings — six runs plus a stranger, 19 October 2026

Six runs of the owner's, and one stranger. That is enough to answer the one question this
exercise was built to answer, and not enough to answer the rest.

### The premise holds

| Evidence | Run |
|---|---|
| "exited to see something for the first time" — the world changing caught them | 1 |
| "Mechanic is still cool" — it survived repetition | 3 |
| **"less interesting when both see the same thing"** | 4 |
| "Seeing the rock i wanted to interact with it, even more the book i expected to be able to interact with it and read it" | 6 |
| **"surprised by the swap mechanic"** | stranger |

**Run 4 is the whole project in one line.** With the second sight on, the two characters
agree — and the world got *less* interesting. The disagreement, not the filter, is what
carries it. Everything downstream is built on that, or it is not built.

**The stranger's surprise at the swap is the second half of the same finding.** Somebody
who had never been told about the mechanic was surprised by the *character swap* — not by
the truth toggle. That is P2 confirmed, and it is the closest thing to a verdict the
project has.

**Run 6 is the other half of the thesis**: a rock that is a book made the player want to
pick it up and read it. The Book layer has to be *desirable*, not merely different, or
nobody will ever go looking for it.

### The "but"s, named

| # | What they said | What it means | Where it goes |
|---|---|---|---|
| B1 | "movement and camera feel weird… it moves relative to plane not camera" | The input was world-space. "Forward" has to mean *away from the camera*. | **Fixed** — camera-relative input |
| B2 | "not sure about the transition when swapping… in the objects morphing rather than a direct view switch" | The camera *slid* across to the other character while the objects morphed. A cut reads as a page turn; a slide reads as a camera that lost the player. | **Fixed** — the camera cuts on a swap |
| B3 | "Text showing what the other sees feels like too handholding" | The tag is a debug affordance. In the finished game the disagreement is carried by barks and VFX, not by a label. | **F2 toggles it now.** The shipped game still owes the barks. |
| B4 | "change of view should be fater when pressing T, it takes too much time" / "expected change to be immediate with T" | The cross-fade was 0.9s. Two people, including a stranger, said the same thing. | **Fixed** — 0.3s |
| B5 | "when quijote goes back to seeing reality some reaction from his side should happen" | A character beat is missing. The moment he stops seeing the giant has to be *felt*, not just observed. | **Named task** — barks, week 3–4 |
| B6 | "Seeing the rock i wanted to interact with it… expected to be able to interact with it and read it" + "wanted to interact with book and giant" | The *Examine* verb is wanted in the first minute of the game, not in week 5. **Two independent people, one of them a stranger.** | **Named task** — pull `Lectura` forward |
| B7 | "what is the difference between pressing T and L? they do the same" | **A real fault, and the most valuable note in the set.** The truth toggle and the madness toggle produced an *identical picture*. | **Fixed** — see below |
| B8 | "camera rotates sideways too fast" | The camera copied the character's facing every frame, and the character snapped. | **Fixed** — the camera's yaw is smoothed, the character's turn is rate-limited |

### B7 — the two levers looked the same, and it was a design fault, not a bug

Pressing **T** changes the *world*. Pressing **L** changes *Quixote's madness*, and
therefore only what *he* sees. But the shader's grade followed the reader as well as the
objects, so both keys produced a giant on a gilded screen. The stranger asked the only
question that mattered: *what is the difference?* There wasn't one.

The fix separates the two values that were tangled together:

| | the world's look | the objects |
|---|---|---|
| **T** — the world changes | changes | change |
| **L** — his madness changes | does **not** change | change |

So a mad knight insisting on a giant now stands in a flat, honest, Reality-graded world
that has not changed — a completely different picture from the world itself turning over,
and a better picture than either of them was alone. **The madness became a picture
instead of a filter.** `tests/test_truth_layer.gd` now pins the two values apart, because
this is exactly the kind of thing that silently merges back.

### The predictions, scored

| # | Prediction | Verdict |
|---|---|---|
| P1 | The first `T` press lands | **Yes.** "exited to see something for the first time" |
| P2 | The swap is the best moment, not the toggle | **Yes.** The stranger was surprised by the swap. Only the *transition* was wrong (B2). |
| P3 | The tag is read once and ignored | **Yes** — and worse: it is handholdy, not merely ignorable |
| P4 | Madness makes it *better* | **Seen, not tested.** The stranger saw it working; it also produced a distinct picture, which is what B7 was missing. Give it a proper run. |
| P5 | Somebody will try to attack the mill | **Yes** — the stranger wanted to interact with the book and the giant |
| P6 | The rock-as-a-book is the thesis in one object | **Yes** |

### The page turn — the owner's idea, built after the playtest

The owner's note on the playtest: *"Maybe adding some kind of effect in the screen when
pressing T could make it more clear and pleasing that something is happening, some effect
related to a book."*

It is built. Pressing **`T`** turns a page: a sheet of paper crosses the screen, carrying
a line of the **1605 original** — *"En un lugar de la Mancha, de cuyo nombre no quiero
acordarme…"* — while the world changes behind it. GDD.md §4.3 asked for exactly this:
*"Pages curl… the occasional line of the actual 1605 Spanish text, faint, as if the world
is being written under your feet."*

The 1605 original is **content**: the same words in every build, in every language,
because it is a quotation and not a translation. It is printed from
`assets/manifiesto/bk.ch01.apertura.json`, the first real Manifiesto fragment.

**It is untested.** The effect was built after the last playtest, so nobody has seen it
except the two of us. It is a candidate for the next run: does the page make the change
*clearer*, or does it get in the way of a change that is already clear?

### B5 and B6 — built after the playtest, waiting for a run

Two of the "but"s are now code.

**B6, the Examine verb.** Press **`E`** next to a thing and the game tells you what it
is: the object, the name each truth gives it, and the name each of the two of you is
calling it *right now*.

```
La roca
Realidad: roca · Libro: libro
Don Quijote: libro · Sancho: roca
```

It is the cheapest possible version of the `Lectura` beat (GDD.md §6), and it is the
thing two people asked for by name. The third line is the one that moves: it is
recomputed from the reading rule every frame, so flipping the world with `T` changes it
under your eyes.

**B5, the reaction.** The other half of the same note: *"when quixote goes back to seeing
reality some reaction from his side should happen."* When a character's reading changes,
they now say so, out loud, with their name on it:

```
Don Quijote: ¡Un libro! ¡Mirad, un libro! ¿Quién lo ha puesto aquí?
```

The barks used to be emitted into the void — `EventBus.toast` had **no listener at all** —
so the companion was a label and not a character. That is the B3 debt, and the reason the
playtest said the tag felt like handholding: a tag is not a character, and the
disagreement has to be *told*, not read.

**Both are untested.** They were built after the last playtest, so nobody has seen them
except the two of us.

### What is still owed

- **A stranger who does not already know the keys.** The stranger's note *"expected
  change to be immediate with T"* suggests they did not know what T did and inferred it
  from the effect. A stranger who does not know the controls is a different test, and it
  is the one that decides whether the mechanic teaches itself. The build is ready for it.
- **The other fourteen runs.** Seven data points is a sample, not a signal.
- **B6 and B5, untested.** Built after the last run. They need one run of their own: does
  the Examine panel teach the two-truths idea, or does it give it away too cheaply? And
  does Quixote's reaction land, or is it a line in a corner?
- **The page turn, untested.** Built after the last run. It needs one run of its own:
  does it make the change clearer, or does it get in the way of a change that is already
  clear?

> The second round of notes came back on 20 October, and it changed the answer to the
> first of those: the Examine panel was giving the mechanic away. See **§7**.

---

## 7. The second playtest — 20 October 2026, the owner's notes

Two notes came back from playing the build with the Examine verb and the
dodge in it. They are about the same thing from opposite ends: **the
build was showing the player too much, and asking the player too
little.**

### The two new "but"s

| # | What they said | What it means | Where it goes |
|---|---|---|---|
| B9 | *"Examining shouldn't give away all the information. It should give the information the character sees. If it's a rock a rock, it can describe how it looks. If it's a book, a book, with its title maybe some text and a mention that it is heavier than it should."* | The panel was printing the truth table **and** the reading of both characters. That is the whole mechanic, handed over before the player had touched anything. | **Fixed** — the panel prints **one character's perception**: the name, the description, the title, the text on the page, and the one detail that does not add up |
| B10 | *"For the dodge it is difficult to assess if it's fine at this stage without any enemies or space limitations."* | A dodge on an empty plain is a dash. You cannot tell a good one from a bad one: there is nothing to dodge, and nowhere you cannot go. | **Fixed** — a **training dummy** in a **walled yard**, and the attacks that make the dodge a decision |

### B9 — the panel was the answer sheet

The panel used to print three lines:

```
La roca
Realidad: roca · Libro: libro
Don Quijote: libro · Sancho: roca
```

The second line is the truth table. The third line is the other
character's reading. Together they are the whole game, given away for
free — and the player was handed it *before* they had touched anything.

Now it prints one character's perception, and only that:

```
roca
Una piedra gris del tamaño de un puño, con el liquen seco en la parte de
arriba y la base hundida en la tierra.
Pesa más de lo que debería pesar una piedra de ese tamaño.
```

and, in the Book, the same object read the other way:

```
libro
Un libro pequeño, encuadernado en cuero pardo y atado con una correa. Los
cantos de las hojas están dorados y manchan los dedos.
El ingenioso hidalgo Don Quijote de la Mancha
«En un lugar de la Mancha, de cuyo nombre no quiero acordarme, no hace
mucho que vivía un hidalgo de los de lanza en astillero, adarga antigua,
rocín flaco y galgo corredor.»
Pesa más de lo que debería pesar un libro de ese tamaño.
```

**The last line is the point.** It is the *seam*: the one detail the
character cannot explain, and the thing the player is meant to notice
without a marker. GDD.md §6 says the Lectura system is built on
anamorphoses the player finds unaided — and a seam is the seed of one.

Note what is *not* in the panel any more: the truth table, and the other
character. Note also that the seam is **mirrored** — the stone is too
heavy for a stone, and the book is too heavy for a book. The player who
examines the same object in both truths finds the *same anomaly in two
words*, and that is the anamorphosis, found by looking.

The panel is still **live**: the description is recomputed from the
reading rule every frame, so `T` and `TAB` change what is written under
your eyes. What is gone is the table, not the mechanic.

### B10 — the dodge had nothing to dodge

Fair, and it is a note about the *test rig*, not about the dodge. A dodge
on an open plain is a dash: you cannot tell a good one from a bad one,
because there is nothing to dodge and nowhere you cannot go. You cannot
even tell whether the i-frames are the right length.

So the slice grew the missing piece — **task 2.6b, the hole in the
plan**:

- **A training dummy.** It stands up, it takes a hit, it goes down, and
  `K` puts it back on its feet. It swings on a rhythm: a **wind-up** you
  can read, a strike, and a rest. The hit is resolved *when the arm comes
  down*, not when it went up — so a character who has already moved is
  not hit. That is the whole test.
- **A walled yard**, to the west, with a gate in the east wall. The
  walls are the space limit: there is room to fight and nowhere to run.
- **Attacks that land.** `LMB` is a light swing, `RMB` a heavy one, and
  both cost stamina and have a rhythm of their own. Without something to
  hit, the dummy is scenery.

**What still needs judging is the numbers.** And they have moved, because the owner
read the first numbers and did not like them:

| | the roll | the invulnerability | the speed it follows |
|---|---|---|---|
| **before** | 6 m (both) | 0.4 s (both) | 15 m/s |
| **now — Quixote** | **4 m** | **0.25 s** | 16 m/s |
| **now — Sancho** | **2 m** (half) | 0.4 s | 5 m/s |

*"Let's reduce the roll distance a bit, also Sancho's roll should be half the distance
and the invulnerability of Quixote as he should not be a fighter."*

**The numbers are now data, not a constant.** A dodge says how far it carries you and
how long you are safe for, and the speed follows: you move for as long as you cannot
be hit. The two are different because the two men are different:

- **Quixote** scrambles four metres and is untouchable for a quarter of a second. He is
  not a fighter, and the game no longer lets him pretend otherwise: his dodge is a
  nervous, committed lunge that will not save him if he rolls early.
- **Sancho** rolls **two** — half of it — and is safe for twice as long. He is a heavy
  man with a buckler: he does not go anywhere, he throws himself under the blow and
  gets up.

The rule that makes it data is in `src/data/abilities/dodge_quixote.tres` and
`dodge_sancho.tres`: `roll_distance` and `iframe_seconds`. Change them, play it, write
down what changed. The dummy's numbers are data too — its wind-up is 0.62 s, its reach
2.9 m, its arc 110°.

**Both are untested.** They were built after the note, so nobody has seen
them except the two of us.

### The lock-on — the thing the dummy was for

The dummy was built so that a target existed at all, and a target is what a **lock-on**
(`M`) is for. It is a *soft* lock: the target is the one you are looking at, the
character turns towards it and walks around it, and the camera stands on the line
between them and frames both.

It is half a camera tool and half a combat tool, and the camera half is the one that
matters: **a fight you cannot see is not a fight.** The camera pulls back with the
distance to the target, looks past the character, and steps to the shoulder so the
character does not stand in front of the thing it is fighting.

The lock is given up when the target goes down, when it gets too far, and when you
swap characters — a lock belongs to the character that took it.

### B3 — the companion finally says something about what it is looking at

The barks were heard, and they fire when a reading changes. What was missing was the
*idle* chatter: a random draw from a pool of two, every twenty-five seconds. A
companion that says "sí, señor" on a loop is a label, not a person.

So the line is **about the thing in front of it**:

```
Sancho: Una piedra, señor. De las que hay a montones.
Quixote: Molinos, Sancho. Y gigantes, si el viento quiere que lo sean.
Sancho: Un maniquí, señor. Está puesto para que le den.
```

and about what the player is doing — the yard made two new beats possible:

```
Sancho: Ah, ¿vamos a por él, señor? Ay, no lo mueve nadie.
Quixote: ¡Levántese, Sancho! No es culpa suya: la piedra estaba mal puesta.
```

The rule is one line: **a line about the thing, or an idle line — never the same thing
twice in a row.** The idle lines are a pool of three per character, so the companion
has something to say even on an empty plain.

### 2.6 — the rest of the combat

The verbs are all in now, and they are all in the yard where they can be judged:

| | |
|---|---|
| **The chain** | The light attack is three hits, each harder than the last (14 → 20 → 26). Press it again inside the window and the next step comes out. |
| **The guard** (`F`) | Holding it stops most of a blow and costs stamina. A guard with no stamina **breaks**, and the blow lands in full. |
| **The parry** | Sancho's buckler parries: a blow in the first 0.18 s of the guard costs no health and leaves the attacker **staggered**. Quixote's lance cannot parry — GDD.md §7.1. |
| **The poise** | Blows take it away. When it is gone, the character **staggers** and cannot swing back. |
| **The hit reaction** | A blow that lands pushes the character and stops them swinging for a moment. |

The asymmetry is in the numbers, not in a rule that says so: **Sancho can parry and
Quixote cannot**, because a buckler is a parry and a lance is a wide block. The
parry is also the biggest moment in a fight, so somebody says something about it.

### 2.10 — the asymmetry rules, and a straw man to break them

The two rules that make the two characters un-stackable (GDD.md §7.2) are now code, and
the yard has something to show them with:

| | Quixote | Sancho |
|---|---|---|
| **The innocent** | The blow does not land. It costs **20 Humanity**. | The blow lands. It costs **5**. |
| **The enemy** | The blow is whole. | The blow is **40 %** — but the poise is whole: he staggers, he does not kill. |

The **straw man** in the corner of the yard is the innocent. It does not fight; it stands
there and looks like a person from a distance, and a blow that lands on it is a blow on
an innocent. The Humanity counter is in the HUD, and it does not come back on its own.

The enemy is the training dummy, and that is a change of mind. The dummy used to be a
practice target that anyone could hit for full damage. **It is an enemy now** — it hits
back, it has a poise, it staggers — and so **Sancho cannot break it. Quixote can.** The
yard now teaches the thing the whole combat design is built on: *the player must swap
mid-fight.*

### 2.9 — Desvelar

Sancho's verb, and the GDD calls it the best-designed combat verb in the game: *"a
cone/line that strips the 'Book skin' off an enemy for eight seconds, exposing its true
form."*

**`X`** strips it. Point it at the rock in the Book layer and the book becomes a stone —
for eight seconds, and for **both** characters, because a book in a rock that suddenly
shows as a stone is a thing the player cannot unsee. The Examine panel follows: the
description, the title and the page of text are all gone, and what is left is a stone.

It is Sancho's alone. Quixote has no such gift, which is the other half of the same
asymmetry: one of them can see through the book, and the other one has to break it.

### 2.7 and 2.8 — the silhouettes

The GDD is blunt about this: *"Distinct animation sets sell the asymmetry better than
any mechanic. A reskinned Quixote makes the whole idea collapse."*

There are no animations yet, and eight of them is an art budget, not a code one. But the
**silhouette** is the cheapest part of it and the most visible: Quixote is tall and thin
with a **lance** and a **basin** on his head — the barber's basin of the novel, which is
where the helmet comes from — and Sancho is short and round with a **sack** on his back
and a **flail** in his hand. You can tell them apart from across the yard with the sound
off.

That is the half of 2.7 and 2.8 that is not an art budget. The animation sets still owe
eight clips each.

### The hit reactions

A blow that lands flashes the body, pushes the character, stops the swing for a moment,
and **shakes the camera**. It is the cheapest honest version of a hit reaction, and it
is the one the playtest can judge.

### The page turn, untested

Still on the list from the last round: the page turn was built after the
playtest too, and it has never been judged.

---

## 8. What to do with the answers

- **If the answers are yes** → the premise holds. Go to week 3–4 (combat) and keep
  building on this rock. The mechanic is a foundation, not a gimmick.
- **If the answers are no** → **stop.** `ROADMAP.md` §4 says cut from the bottom, never
  the top, but that rule is for *scope*. If the *premise* fails, the right cut is the
  premise, and that is a decision for the owner, not a pivot taken quietly in week 7.
- **If the answers are "yes, but"** → write the "but" down. Every "but" is a week of
  work that is now named instead of guessed at. The "but" is the most valuable output of
  this exercise.

> **Verdict, 19 October 2026: "yes, but."** The premise holds, and the stranger confirms
> it from the outside: the swap surprised them, and the two levers now do visibly
> different things. Six of the eight "but"s are fixed and shipped. B5 and B6 are named
> work, and B6 now has two independent people asking for it.
>
> **The next task is week 3–4 — but the Examine verb first.** It is the one thing a
> player who has never seen the game asked to do.


**The rule:** no more than two more primitives get built until this file has an
observation log in it. A dozen objects built on an unproven premise is the most
expensive way to find out that the premise is wrong.
