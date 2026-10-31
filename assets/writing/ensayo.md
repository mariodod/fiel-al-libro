# The Ensayo — Player-Staged Case Script

> Region IV · Chapters 9–10 · The Curious Impertinent (Don Quixote I.50)
> Locked by D5 · Written before build (ROADMAP.md Phase 2)

> **The player does not read about this. The player stages it.**

## Overview

The Ensayo is the thematic centre of the game. Where every other case asks the player to *read* the world, the Ensayo asks the player to *build* a world and then live in it. The four outcomes that hurt are all ones the player constructed — the game's thesis expressed as mechanic: *you are responsible for what you insisted was true.*

## Phase 1 — The Setup (free, no timer, no fail state)

The player is given a test with three sliders and one question:

```
THE TEST
  A knight must prove that he can be trusted with a secret.
  He does not know that another knight has been sent to take it from him.

  [ Who plays the tested?    ]  Quixote  |  Sancho
  [ Who plays the examiner?  ]  Quixote  |  Sancho
  [ What is the secret?      ]  the wife's name  |  the treasure  |  the truth
  [ Who is told the truth?   ]  the tested  |  the examiner  |  neither
```

### Slider options

| Slider | Option A | Option B | Option C |
|--------|----------|----------|----------|
| Tested | Quixote | Sancho | — |
| Examiner | Quixote | Sancho | — |
| Secret | the wife's name | the treasure | the truth |
| Told truth to | the tested | the examiner | neither |

Each choice is *legal*. The player can stage a cruel test, a kind test, a stupid test. The game does not judge the setup — it records it in the Manifiesto and judges only the outcome.

### Setup constraints

- Tested and Examiner cannot be the same character (both Quixote or both Sancho is invalid).
- If Quixote is the Tested, his Locura affects how he behaves under pressure.
- If Sancho is the Examiner, his second sight affects what he can observe.

## Phase 2 — The Simulation (4–6 social rounds)

Each round:

1. **The AI character acts on its motive.** The non-player character (the one not controlled by the player) acts on motive, not script:
   - *Curiosity* — seeks the secret
   - *Jealousy* — wants to displace the other character
   - *Love* — wants to protect the tested
   - *Need to be important* — wants to be the one who knows
   - *Need to be right* — wants to prove their theory
   - *Fear of being thought a fool* — avoids being embarrassed

2. **The player has 2–3 interventions per round:**
   - A line of dialogue
   - A whispered warning
   - A look (non-verbal)
   - A letter (written intervention)

3. **Every intervention is recorded in the Manifiesto** — the manuscript literally records what the player did and why. These records become codex pages.

### Intervention effects

- Dialogue can shift a character's motive or reveal information
- A whispered warning can protect the tested or mislead the examiner
- A look can communicate without words (ambiguous — the AI may misread it)
- A letter is permanent evidence (cannot be retracted)

## Phase 3 — The Consequence (5–6 outcomes)

The simulation resolves from the setup + the interventions. Outcomes are not "win/lose":

| # | Outcome | Campaign Effect |
|---|---------|-----------------|
| 1 | **The test holds** | The tested stays loyal. A Quest line opens in Region V castle (the Duke's court). |
| 2 | **The test breaks** | Betrayal. The tested kills himself. Humanity −20 regardless of intent. |
| 3 | **The examiner breaks** | The examiner is consumed by the test. Becomes the "Impertinent" — a recurring NPC who follows the player, increasingly wrong. |
| 4 | **Nobody breaks; nothing happens** | The anticlimax. Boring, therefore *true*. Reward: codex page "the only honest ending." |
| 5 | **The player is caught** | The player (as meta-character) is revealed as the author. Unlocks the "El Manuscrito" ending path (§12.2). |
| 6 | **The player refuses to stage it** | Walk away. Chapter ends early with a gap in the manuscript. The gap is visible on the shelf permanently. |

### Outcome determination

- Setup choices weight the probabilities of each outcome
- Interventions shift probabilities round by round
- Character Locura affects stability (high Locura → more likely to break)
- Humanity affects how cruel outcomes feel (narrative, not mechanical)

## Characters

| Role | Book Truth | Reality Truth |
|------|-----------|---------------|
| The Tested | Believes they are proving worth | Knows they are being manipulated |
| The Examiner | Believes they are administering justice | Knows they are being cruel |
| The AI (non-player) | Acts on book-logic | Acts on reality-logic |

## Colophon

Chapter 9 colophon: "This is the story I wish I had written" — the author steps aside and lets the player write.

Chapter 10 colophon: The author writes about responsibility — you are responsible for what you insisted was true.

## Endings impacted

- **La Locura Compartida**: more likely if the test breaks (both characters stressed)
- **El Mundo Real**: more likely if nobody breaks (the anticlimax cures both)
- **El Manuscrito**: unlocked if the player is caught (Outcome 5)

## Locale keys needed

```
ensayo.setup.title
ensayo.setup.tested.quixote
ensayo.setup.tested.sancho
ensayo.setup.examiner.quixote
ensayo.setup.examiner.sancho
ensayo.setup.secret.wife
ensayo.setup.secret.treasure
ensayo.setup.secret.truth
ensayo.setup.told.tested
ensayo.setup.told.examiner
ensayo.setup.told.neither
ensayo.outcome.holds
ensayo.outcome.breaks
ensayo.outcome.examiner_breaks
ensayo.outcome.nothing
ensayo.outcome.caught
ensayo.outcome.refuses
```

## Writing notes

This chapter is locked by D5 and is "the chapter that proves the thesis." Protect it as long as the schedule allows. If the schedule slips, it can be cut as a whole chapter (Tier 3 in ROADMAP.md §4), but the game survives less well without it.
