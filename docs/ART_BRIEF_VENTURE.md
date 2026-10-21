# ART BRIEF — the Venture of Montiel

> The two faces of the windmill: **the mill** (the Reality truth) and **the giant of
> the mills** (the Book truth). They are the same object read two ways, and they are
> the first boss of the game (NEXT_STEPS.md §2, task 2.11).
>
> **Reference:** `docs/reference/venture_of_montiel_concept_sheet.jpg` — generated from
> the prompt in the session notes, and the authority for the shapes below. The meshes
> in `src/world/forms/` are built from it: low-poly, flat, in the game's palette.

## The look

The house style: **gouache on plaster** — a 16th-century Spanish painting that has
started moving (GDD.md §15.1). The reference sheet already is in the style, which is
the point of using it: warm ochres, bone whites, olive scrub, iron grey, one dried-blood
accent, a dark ink contour, visible brush, and a long low sun on a dry plain.

The palette is the game's (`docs/ANIMATION_BRIEF.md` §2) and only that palette:

`#C08A3E` ochre · `#8A5A28` dark ochre · `#E8DCC0` bone white · `#C9B896` dirty bone ·
`#6E7345` olive · `#4A4E2E` dark olive · `#4C4A46` iron grey · `#2E2C2A` black iron ·
`#7A2E22` dried blood · `#6B4A2C` wood · `#8A8C90` steel

## THE MILL — the Reality form

`src/world/forms/windmill_reality.tscn`

- A **round tower** of ochre limestone, eight-sided, eight metres, wider at the foot.
- A **cone cap** of dark tile.
- A **low doorway** at the base, black inside, with a lintel. **It is a weak point**:
  the Venture is fought at its foot, and the foot is the door.
- **Four tattered canvas sails** on an iron axle, made of three strips of decreasing
  length so the ends are ragged. They turn (`spin_sails.gd`).

## THE GIANT — the Book form

`src/world/forms/windmill_book.tscn`

- Nine metres, gaunt, bare, dusty ochre clay skin. **All elbows.**
- The **arms are far too long** — from the shoulder at seven metres to the ankle — and
  each ends in a **tattered mill sail instead of a hand**.
- The **head is the millstone**: a disc of iron grey with the hole through it, facing
  you.
- A coarse **olive cloth belt** at the waist. Bare feet.

He is not a monster. He is a mill that has been read as a man: tired, workmanlike,
silent. No horns, no glowing eyes, no roar.

## The rules

- **Silhouette first.** The mill is a cross of sails on a tower; the giant is a
  long-armed figure with a disc for a head. They must read at a glance, from across
  the era, in the Book grade.
- **Low-poly, flat, vertex-coloured.** Both are boxes and cylinders: under 400
  triangles each, one material per surface, no textures, no smoothing. The truth-layer
  shader draws the ink outline over everything, and that outline is what makes
  low-poly read as illustration.
- **No lighting baked in.** One sun, one ambient sky, one post-process.

## What is still missing

- **The masonry.** The tower is a flat ochre cylinder; the reference has courses of
  stone. That is a hand-painted 2K texture on the triplanar material, and it is the
  next pass, not this one.
- **The tatter.** The sails are three boxes of decreasing length. They read as ragged
  at a distance, which is what a silhouette needs, and not much closer.
- **Quixote and Sancho.** Their rigs are built and animated, but the poses are still
  grey-box: the next pass is the one that makes them read as Velázquez rather than as
  a fighting game (`docs/ANIMATION_BRIEF.md`).

## The other primitive — the rock

The rock is the tutorial's centrepiece, and it is the same idea one scale down: a
thing with two faces, and a seam in each.

**The stone** (`rock_reality.tscn`) — faceted, not smooth: dry lichen on the top, its
base sunk in the earth. "A grey stone the size of a fist, with dry lichen on the top
and its base sunk in the earth."

**The book** (`rock_book.tscn`) — a small book in brown leather on the stone the rock
was, tied shut with a strap, its leaves gilt at the edge. "A small book, bound in
brown leather and tied with a strap. The edges of the leaves are gilt and stain the
fingers."

The seam is the same in both: **it is heavier than it should be.**

## How to regenerate the reference

The prompt that produced the sheet, and the one to use for anything else in this
world — the Posada, the shelf, the two characters:

```
Concept sheet for a video game boss: THE VENTURE OF MONTIEL — one object
with two faces, drawn side by side on the same dry Spanish plain.

LEFT — THE REALITY FORM, THE MILL. A squat stone windmill of 16th-century
Castile: a tower of warm ochre limestone polished smooth by grain, a low
wooden door standing open, four long canvas sails on an iron axle, a cone
cap of dark ochre tile. The sails are turned and the ground around the
tower is bare and swept. It reads as a building that has been standing in
the wind for a hundred years.

RIGHT — THE BOOK FORM, THE GIANT OF THE MILLS. The same mill read by the
Book: a nine-metre man. Enormous, gaunt, bare, dusty ochre flesh like
sun-baked clay; arms far too long, hanging past the knees, and each arm
ends in a tattered mill sail instead of a hand; a small stone millstone
for a head, sunk between the shoulders; a coarse dark-olive cloth belt at
the waist. He is not a monster. He is a mill that has been read as a man.

BOTH: a full-body, three-quarter view of each, standing on the same
ground line, at the same scale, in the same light, so the two can be
compared directly. Long low sun, hard shadows, dry air, a lot of empty
space.

Style: gouache on plaster. A 16th-century Spanish painting that has started
moving. Warm ochres and bone whites, olive scrub, iron grey, one dried-blood
accent. Painted, dry and lit, not grimdark and not photoreal. Visible brush
and paper tooth, simplified flat shapes, a strong dark ink contour, like an
Okami ink line over a Goya etching. Silhouette first: the forms must read
instantly at a distance. Palette: ochre #C08A3E, dark ochre #8A5A28, bone
white #E8DCC0, dirty bone #C9B896, olive #6E7345, dark olive #4A4E2E, iron
grey #4C4A46, black iron #2E2C2A, dried blood #7A2E22, wood #6B4A2C.

Not a fantasy game, not a knight, not an orc, no horns, no glowing eyes, no
dramatic purple rim light, no photoreal texture, no modern clothing, no
text, no logo, no border, no background clutter, no other characters.
```
