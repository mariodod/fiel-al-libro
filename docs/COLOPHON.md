# COLOPHON — the author's voice between chapters

> GDD.md §12.1: *"Between chapters, there is a colophon — a page of the 1605
> text, the author's voice talking to 'you, reader', explaining what you've
> just done. In Book Truth the colophon agrees with you. In Reality Truth it
> corrects you. Occasionally, the colophon is wrong on purpose — and that is
> a clue that reality has shifted."*

## What is shipped

Six colophon pages, one for the prologue and one per region, each written in
both truths:

| Key stem | When it appears |
|---|---|
| `ui.colofon.prologo.*` | After the prologue, before Chapter 1 |
| `ui.colofon.camino_la_mancha.*` | After a chapter in Region I |
| `ui.colofon.sierra_morena.*` | After a chapter in Region II |
| `ui.colofon.el_toboso.*` | After a chapter in Region III |
| `ui.colofon.los_riscos.*` | After a chapter in Region IV |
| `ui.colofon.el_castillo_del_duque.*` | After a chapter in Region V |

The page is `src/world/colophon.tscn` + `colophon.gd`. `ChapterFlow` shows it
during the between-chapter transition, after the ride card and before the next
chapter. It waits for a keypress, with a 12-second auto-advance fallback so a
player walking away is never trapped.

## An important content decision

These colophons are **original game writing, not quotations from Cervantes**.
The Manifiesto fragments in `assets/manifiesto/` are verbatim 1605 text and are
never attributed to this project. The colophons are this game's own author
voice, written for the frame: the GDD asks for a page "in the voice of the
author" between chapters, and writing one that claims to be Cervantes without
a source edition would be a false attribution.

Consequently the colophons live in the locale files as ordinary keys, not as
Manifiesto fragments with an `original_1605` field. The Spanish text is the
original; the other five locales carry the English rendering, consistent with
the rest of the project's current translation state.

## The rule for the voice

- **Book truth**: the page agrees with what the player did. It flatters the
  reading and makes the delusion feel coherent.
- **Reality truth**: the page corrects them. It names the ordinary thing under
  the extraordinary story.
- **Region IV** is deliberately the hardest: the page points out that the
  player built the test themselves. This is the playtest thesis — *you are
  responsible for what you insisted was true* — stated in the author's voice.

## Status

All six passages are written and translated in all six shipped locales.
`tests/test_colophon.gd` verifies the keys, that both truth variants resolve to
different prose, and that the first chapter has a region for its colophon.
