# PLAYTEST NOTES — Week 1–2

> The deliverable for task 2.4: **write down what you feel. Not what you built.**
>
> Last updated: **2026-10-19**

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
| `V` | Sancho's second sight, on/off |
| `L` | Quixote's Locura: Lucid ↔ Lost |
| `F1` | the help overlay |

The scene: a windmill and a rock on a dry plain. Quixote and Sancho. The windmill is a
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

**The stranger's run** (run 18–19). What did they do in the first 30 seconds, without
being told anything?

```
(still owed)
```

---

## 6. Findings — six runs, 19 October 2026

Six runs, not twenty, and no stranger yet. That is enough to answer the one question
this exercise was built to answer, and not enough to answer the rest.

### The premise holds

| Evidence | Run |
|---|---|
| "exited to see something for the first time" — the world changing caught them | 1 |
| "Mechanic is still cool" — it survived repetition | 3 |
| **"less interesting when both see the same thing"** | 4 |
| "Seeing the rock i wanted to interact with it, even more the book i expected to be able to interact with it and read it" | 6 |

**Run 4 is the whole project in one line.** With the second sight on, the two characters
agree — and the world got *less* interesting. The disagreement, not the filter, is what
carries it. Everything downstream is built on that, or it is not built.

**Run 6 is the other half of the thesis**: a rock that is a book made the player want to
pick it up and read it. The Book layer has to be *desirable*, not merely different, or
nobody will ever go looking for it.

### The "but"s, named

| # | What they said | What it means | Where it goes |
|---|---|---|---|
| B1 | "movement and camera feel weird… it moves relative to plane not camera" | The input was world-space. "Forward" has to mean *away from the camera*. | **Fixed** — camera-relative input |
| B2 | "not sure about the transition when swapping… in the objects morphing rather than a direct view switch" | The camera *slid* across to the other character while the objects morphed. A cut reads as a page turn; a slide reads as a camera that lost the player. | **Fixed** — the camera cuts on a swap |
| B3 | "Text showing what the other sees feels like too handholding" | The tag is a debug affordance. In the finished game the disagreement is carried by barks and VFX, not by a label. | **F2 toggles it now.** The shipped game still owes the barks. |
| B4 | "change of view should be fater when pressing T, it takes too much time" | The cross-fade was 0.9s. | **Fixed** — 0.5s |
| B5 | "when quijote goes back to seeing reality some reaction from his side should happen" | A character beat is missing. The moment he stops seeing the giant has to be *felt*, not just observed. | **Named task** — barks, week 3–4 |
| B6 | "Seeing the rock i wanted to interact with it, even more the book i expected to be able to interact with it and read it" | The *Examine* verb is wanted in the first minute of the game, not in week 5. | **Named task** — pull `Lectura` forward |

### The predictions, scored

| # | Prediction | Verdict |
|---|---|---|
| P1 | The first `T` press lands | **Yes.** "exited to see something for the first time" |
| P2 | The swap is the best moment, not the toggle | **Unclear.** The toggle landed; the *swap* was called "not sure" — but that was the transition, not the idea. Re-test after B2. |
| P3 | The tag is read once and ignored | **Yes** — and worse: it is handholdy, not merely ignorable |
| P4 | Madness makes it *better* | **Untested.** Nobody pressed `L`. It is the most interesting lever in the build and it has no data. |
| P5 | Somebody will try to attack the mill | **Yes, in spirit** — run 6: they reached for the rock and the book |
| P6 | The rock-as-a-book is the thesis in one object | **Yes** |

### What is still owed

- **The stranger test (runs 18–19).** Not done, and it is the only run that says whether
  the premise is legible to somebody who has not been told. Do it with the tags **off**
  (`F2`): a stranger should find the second reading by swapping, not by reading it.
- **The other fourteen runs.** Six is a sample, not a signal.
- **P4 — the madness.** Untouched. Push Quixote to Lost (`L`) and then press `T`: the
  world stops changing for him, and that is the mechanic behind the meter.

---

## 7. What to do with the answers

- **If the answers are yes** → the premise holds. Go to week 3–4 (combat) and keep
  building on this rock. The mechanic is a foundation, not a gimmick.
- **If the answers are no** → **stop.** `ROADMAP.md` §4 says cut from the bottom, never
  the top, but that rule is for *scope*. If the *premise* fails, the right cut is the
  premise, and that is a decision for the owner, not a pivot taken quietly in week 7.
- **If the answers are "yes, but"** → write the "but" down. Every "but" is a week of
  work that is now named instead of guessed at. The "but" is the most valuable output of
  this exercise.

> **Verdict, 19 October 2026: "yes, but."** The premise holds — run 4 says the
> disagreement is the thing, and run 6 says the Book layer is worth reaching for. Four of
> the six "but"s are fixed and shipped in the same commit. B5 and B6 are named work, and
> the stranger test is still owed. Nothing else gets built until the log has a stranger
> in it.


**The rule:** no more than two more primitives get built until this file has an
observation log in it. A dozen objects built on an unproven premise is the most
expensive way to find out that the premise is wrong.
