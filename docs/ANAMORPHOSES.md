# ANAMORPHOSES — the detail that does not add up

> GDD §11.3: every chapter has "one optional case (2–4 anamorphoses)".
> GDD §4: the two-truths mechanic is legible when a single object yields two
> readings. An anamorphosis is the smallest unit of that idea: a detail visible
> only from one spot, and only in Lectura mode.

## What is shipped

**94 anamorphoses across all 47 chapter scenes — exactly two per chapter.**

- Data: `src/data/anamorphoses/ana.ch<NN>.<motif>.tres`, one `TruthObjectData`
  per discovery, carrying `anamorphosis_id`, `anamorphosis_tell_key`, evidence
  (1), a vantage position, angle and a 5 m radius.
- Scenes: each chapter `.tscn` has `Anamorphosis_<Motif>` nodes at opposite
  sides of the play area, with rock/Book truth forms.
- Locale: `ui.anamorphosis.<id>.desc` and `.tell` in all six shipped locales.
  Spanish is original; the others carry the English rendering.
- Tells are drawn from ten recurring motifs — weight, shadow, hollow sound,
  seam, dust, inner glow, hidden words, newness in an old place, early echo,
  miscounting marks — prefixed by the chapter's own title so each is a
  distinct discovery. They are drafted content, like the region passages.

## How the player finds one

1. Press `Q` to enter Lectura (time slows, the screen desaturates).
2. Stand at the vantage point and face the required direction — `slice.gd`'s
   vantage check gates perception.
3. Examine the object. `player_controller.gd` spots the anamorphosis; the
   tell line appears. Examining again resolves it and grants evidence.
4. Evidence (3 points) unlocks a Verdict — §2.15 of NEXT_STEPS.

## Why the resource is a `TruthObjectData`

The anamorphosis is not a separate system bolted on: it is a hidden property of
an object that is already two things at once. Reusing `TruthObjectData` means
the Examine panel, the perception tags, the truth-layer shader and `Lectura`
all work on it with no special cases. This is the same shape as the rock and
the windmill, one scale down.

## Regenerating

`tools/generate_anamorphoses.py` is deterministic. It creates the `.tres`
files, the locale keys and the scene nodes; re-running is safe. If you add a
chapter, re-run it and then re-run the test suite.

`tests/test_anamorphoses.gd` pins: two nodes per chapter, every resource
loadable with an id and translated tell, 94 total, and that resolving an
anamorphosis grants evidence exactly once.

## A bug this exposed

Loading a chapter scene for the first time in a test revealed that 275
`Transform3D` constructors in the generated chapter `.tscn` files had 8 or 9
values instead of Godot's required 12. The scenes had never been instantiated,
so nothing had caught it. `tools/fix_chapter_transforms.py` mapped them to an
identity basis with the intended translation; all 847 transforms are now
well-formed and `test_anamorphoses.gd` instantiates a chapter scene to keep it
that way.

## Manifiesto rewards

Resolving an anamorphosis also grants a Manifiesto page where that chapter's
fragment has no Venture or region grant path. The field
`anamorphosis_fragment` on `TruthObjectData` names the page; `Lectura.resolve()`
accepts it as a third argument and calls `GameState.grant_codex_page()`.

This closes the collection loop: **all 48 fragments are now reachable** — 14
venture rewards, 5 region pages, and 29 anamorphosis rewards. `tools/audit_grant_paths.py`
verifies the count, and `tests/test_anamorphoses.gd` pins that resolving a
reward-bearing anamorphosis adds the page to the codex exactly once.

## Still drafted

- Individual tell prose deserves a literary pass (one sentence per discovery).
- The 29 non-backed Manifiesto fragments still need grant paths; anamorphosis
  resolution is the natural place for some of them (see NEXT_SESSION §3b).
