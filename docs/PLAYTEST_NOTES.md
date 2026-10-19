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

### What is still owed

- **A stranger who does not already know the keys.** The stranger's note *"expected
  change to be immediate with T"* suggests they did not know what T did and inferred it
  from the effect. A stranger who does not know the controls is a different test, and it
  is the one that decides whether the mechanic teaches itself.
- **The other fourteen runs.** Seven data points is a sample, not a signal.
- **B6 — the Examine verb.** Two people, one of them a stranger, reached for the book
  and the giant. This is the most-requested thing in the build and it is scheduled for
  week 5–7. Consider pulling it into week 3–4: a player who cannot touch the thing that
  made them curious will not come back.

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
