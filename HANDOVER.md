# HANDOVER — Fiel al Libro

> **Read this first if you have not seen this project before.**
> Written to be sufficient on its own. You should be able to pick this up cold.
>
> Last updated: **2026-10-20** · Repo: **https://github.com/mariodod/fiel-al-libro**

---

## 1. What this is, in one paragraph

**Fiel al Libro** is a souls-like action RPG based on *Don Quijote*, in which the world runs on
**two simultaneous truths**. Every object has a Book state (what the 1605 novel says — windmills
are giants, Dulcinea is an enchantress) and a Reality state (what actually happened). Don Quixote
reads the Book; Sancho reads Reality. **The player plays both and switches between them freely.**
The whole game — combat, investigation, progression, collectibles, the DLC plan — is generated
from that one mechanic.

A souls-like by Mordheim, made by a solo developer with no budget, on Godot 4.7, targeting
PC/Steam first, with 6 languages at launch.

**The thesis:** *A man who believes the world is a book will find a book in every rock. A man
who believes the world is a book can also be taught that the rock is only a rock — but only by
someone willing to pay for the lesson with their own mind.*

---

## 2. Where everything is

### Public repo (this one)

| Path | What it is |
|---|---|
| `README.md` | Entry point. The concept, the five decisions, the setup commands. |
| `TECH_STACK.md` | Engine choice and why, engine configuration, project architecture, asset pipeline, performance budgets, the full i18n pipeline. |
| `ROADMAP.md` | 12-week vertical slice → 30-month plan. Scope-cut tiers, weekly rituals, risk register. |
| `TODO.md` | The live task list. **Start here.** |
| `GDD.md` | ⚠️ **PRIVATE — on the owner's machine only.** The full design: pillars, the two-truths system, characters, the *Lectura* mechanic, progression, the library, the bestiary, the regions, the endings, the 4 DLCs, the credits song, art/audio direction, cultural-sensitivity rules, the locked decisions D1–D7. |
| `docs/IP_CLEARANCE.md` | ⚠️ **PRIVATE — owner's machine only.** Title clearance memo: what was searched, the "Don Quijote" finding, the trademark strategy, the manual search checklist. |
| `docs/NEXT_STEPS.md` | **The plan for the next 12 weeks, task by task.** |
| `docs/NEXT_SESSION.md` | **Start here if you are picking this up.** What is done, what is next, in what order, and what not to do. |
| `docs/PLAYTEST_NOTES.md` | The playtest: the protocol, the findings, the ten "but"s. **The most valuable document in the repo.** |
| `docs/ANIMATION_BRIEF.md` | The brief for the hero rigs and their animation sets (2.6–2.8), with the timings they must hit. |
| `HANDOVER.md` | This file. |
| `src/` | All game code. |
| `src/world/slice.tscn` | **The Week 1–2 grey box — the playable build, and the main scene.** Windmill/giant, rock/book, two characters, two readings, and a walled practice yard with a training dummy in it. |
| `src/systems/perception.gd` | The reading rule: the world has one truth, the characters make two things of it. |
| `src/systems/examine.gd` | The Examine verb: what you are looking at, and what **this character** makes of it. |
| `src/systems/attack_hitbox.gd` | A swing: the short window in which what is in front of you takes the hit. |
| `src/systems/harm.gd` | The asymmetry rules: what a blow may do, and what it costs in Humanity. |
| `src/systems/lock_on.gd` | The soft lock-on: the target you are looking at, and when the lock is given up. |
| `src/systems/chatter.gd` | The chatter: what the companion says about the thing it is looking at. |
| `src/systems/reaction.gd` | The reaction: what a character says when the world moves under them. |
| `src/world/truth_object.gd` | An object with two faces. The data shape the whole game is built on. |
| `src/world/training_dummy.gd` | The thing to fight: a telegraphed swing in a walled yard. |
| `src/world/straw_man.gd` | The thing that must not be harmed: the innocent, for the second rule. |
| `src/world/venture.gd` | The first boss: the Venture of Montiel, in two forms and two movesets, in the era to the south. |
| `src/data/` | `Resource` subclasses and the `.tres` content: characters, primitives, moves, forms, ventures. |
| `reference/` | **Local only, gitignored.** The reference texts: the 1605 first part, the 1615 second part, and the OCR of the 1605 printing. Fetch them with `tools\fetch_reference.ps1`. |
| `tests/` | 24 suites, 533 assertions. |
| `locale/` | gettext PO files: es, en, fr + the template. |
| `assets/` | Shaders, the Manifiesto content format. |
| `tools/` | `godot.ps1` (locator), `blender.ps1` (locator), `setup.ps1` (one-command setup). |

> **The two private documents are gitignored on purpose** — they are not merely untracked, they
> were kept out of git *history* as well, so they cannot be recovered from an old commit. If you
> are not the owner, ask for them. **If you are the owner and you lose this machine, they are
> gone — back them up.**

---

## 3. Setup, on any machine

```bash
git clone https://github.com/mariodod/fiel-al-libro.git
cd fiel-al-libro
powershell -ExecutionPolicy Bypass -File tools\setup.ps1
```

That checks git/LFS/Godot, imports the project, and runs the test suite. It prints the four
things that still need a human (Steam Direct, the trademark searches, the EUIPO filing, and the
cloud backup).

**If the build step fails** with "No export template found", install the export templates
(~1.2 GB): Godot editor → **Editor → Manage Export Templates…** → 4.7.2-stable → Download and
Install. CI installs its own, so this only affects local builds.

**`tools/godot.ps1` wraps the Godot binary** because winget may not put it on PATH (it needs
admin rights to create the alias). Use it instead of calling `godot` directly:

```bash
.\tools\godot.ps1 --headless res://tests/test_runner.tscn
```

---

## 4. The commands

| Command | What it does |
|---|---|
| `tools\play.cmd` | **Play the week 1–2 grey box.** `tools\play.cmd res://some/scene.tscn` plays any scene. |
| `tools\play.cmd res://src/tools/shot.tscn` | **Take the screenshots.** Writes `artifacts/shot_*.png` — the evidence a playtest runs on. |
| `.\tools\godot.ps1 --headless res://tests/test_runner.tscn` | **Run the tests.** Exit 0 = green. |
| `.\tools\blender.ps1 --version` | **Blender** (5.2 LTS) — it builds the hero rigs and their animation sets. `.\tools\blender.ps1 -b -P script.py` runs a script headless. |
| `.\tools\godot.ps1 --headless --editor --quit` | Import the project (first run, or after adding assets). |
| `.\tools\godot.ps1 --headless --script res://src/tools/setup_input_map.gd` | Write the input map into `project.godot`. |
| `.\tools\godot.ps1 --headless --script res://src/tools/setup_translations.gd` | **Register `locale/*.po` with the engine.** Run after adding a language. |
| `.\tools\godot.ps1 --headless --script res://src/tools/sync_locales.gd` | Bring every locale in line with the template; report orphans and duplicates. |
| `.\tools\godot.ps1 --headless --script res://src/tools/validate_manifiesto.gd` | Check the Manifiesto fragments: the 1605/1615 trap, the missing modern renderings, the unverified ones, and the worklist against the 48 the plan wants. |
| `.\tools\godot.ps1 --headless --export-release "Windows Desktop" build/FielAlLibro.exe` | Build (needs `build/` to exist). |
| `powershell -ExecutionPolicy Bypass -File tools\fetch_reference.ps1` | **Fetch the reference texts** (the 1605 and 1615 editions) into `reference\`. |

> **To play, use `tools\play.cmd`, not `.\tools\godot.ps1 <scene>`.** Windows resolves a
> `.ps1` and a `.tscn` by file association, and on some machines that hands the scene to
> a text editor or a notes app instead of to Godot. A `.cmd` is executed natively by
> `cmd.exe`: no association, no execution policy, works from any shell and from a
> double-click. `.\tools\godot.ps1` with no arguments prints this list.

CI (`.github/workflows/ci.yml`) runs on every push: import check → tests → Windows + Linux
exports → artifacts.

---

## 5. The design in 90 seconds

Read `GDD.md` for the full thing. The parts you cannot infer from the code:

**The two truths (D2).** One global `truth_layer` value drives one global shader uniform.
Changing the world's reality is a *float write*, never an asset swap. The two characters differ
in what they can perceive and do, never in whether they are in a different world. This is why
there is one `TruthLayer` autoload and not a per-player reality.

**Swapping, not co-op (D3).** The other character is always present as a full AI companion.
Press TAB and you switch; the world does not pause; it is a tactical verb. `CharacterPawn` is
the only way to touch a character, so a second player in co-op would just *claim the pawn the AI
was driving* — networking later, not a redesign now.

**Madness is a mechanic (D1, P2).** `Locura` is per-character, 0–100, with four bands. Quixote
fights *better* at high Locura. The game constantly tempts you to let him break.

**Progression is perception, not damage numbers.** Milestones unlock new *verbs* and new things
you are able to *notice*. This is the anti-grind argument and it is the cheapest part of the
design to implement.

**Your loadout is your collection.** No gear system at all. You carry **5 books**; each grants
a passive. The loadout screen is a literal shelf.

**The *Ensayo* (D5).** The Curious Impertinent chapter is a **player-staged simulation**: the
player sets up a test (who plays the tested, who the examiner, what the secret is, who is told
the truth), watches it play out over 4–6 social rounds, and lives with one of six outcomes —
including the ones that hurt, which are all ones the player constructed. It reuses the Verdict
scaffolding, so it is a new *data shape*, not a new engine system.

**Your playthrough is a manuscript.** The save file is named after that fiction. Each chapter is
a written page. The ending is a page you can read.

---

## 6. Architecture: where the key decisions live in code

| Decision | Where it is |
|---|---|
| Global truth layer | `src/autoload/truth_layer.gd` + the `truth_layer` global shader parameter |
| **The reading rule** | `src/systems/perception.gd` — the world has one truth; each character makes two things of it |
| **An object with two faces** | `src/world/truth_object.gd` + `src/data/truth_object_data.gd` (`.tres` content) |
| The visual identity | `assets/shaders/truth_layer.gdshader` — reality / book / ink in one uniform |
| **The page turn** | `src/ui/post_process.gd` — a sheet of paper carrying a line of the 1605 original crosses the screen when the truth flips |
| **The Examine verb** | `src/systems/examine.gd` + `src/ui/examine_panel.gd` — `E` on a thing, and the game says what **this character** sees: the name, the description, the title, the text on the page, and the one detail that does not add up. Never the truth table, never the other character |
| **The reaction** | `src/systems/reaction.gd` + `src/ui/bark_line.gd` — when a character's reading changes, they say so, with their name on it |
| **The verbs** | `src/characters/character_pawn.gd` — the dodge: a directional burst, a window of invulnerability, and the stamina that comes back; the swing, which chains three and spends stamina; and the guard, which stops most of a blow, costs stamina, and — for Sancho — **parries** |
| **The animation** | `src/characters/character_pawn.gd` + `assets/models/*.glb` — the rig is a child of the character and the pawn plays the clips: `idle`, `walk`, `run`, `roll`, `light_1/2/3`, `heavy`, `block`, `parry`, `hit`, `stagger`, `death`, `interact`, `desvelar`, `idle_lost`. The rigs are built headless by `tools/build_fiel_al_libro_animations.py` |
| **The asymmetry** | `src/systems/harm.gd` — the two rules that make the two characters un-stackable: Quixote cannot harm the innocent, and Sancho cannot meaningfully damage an enemy. He staggers; he does not kill |
| **Desvelar** | `src/world/truth_object.gd` — Sancho's verb: `X` strips the "Book skin" off a thing for eight seconds, and both characters see its true form |
| **The lock-on** | `src/systems/lock_on.gd` + `src/systems/camera_follow.gd` — `M` picks the target you are looking at; the character turns towards it and walks around it, and the camera frames both |
| **The companion's voice** | `src/systems/chatter.gd` + `src/characters/companion_ai.gd` — a line about the thing it is looking at, or an idle line, never the same thing twice |
| **Something to fight** | `src/world/training_dummy.gd` + the yard in `src/world/slice.gd` — a telegraphed swing, a health bar, and four walls. The dodge cannot be judged without an enemy and a space limit |
| **The first boss** | `src/world/venture.gd` + `src/data/ventures/`, `src/data/forms/`, `src/data/moves/` — the Venture of Montiel: the mill and the giant, two movesets, and the two levers that change the shape of the fight (`T` for Quixote, `X` for Sancho) |
| Character abstraction | `src/characters/character_pawn.gd` (base), `player_controller.gd`, `companion_ai.gd` |
| **The companion in the fight** | `src/characters/companion_ai.gd` — it fights the target you are locked onto, and it catches the wind-up on its guard to parry, which staggers the attacker. That is the design's "one kills, one controls" |
| Data-driven content | `src/data/*.gd` — `Resource` subclasses; tune in the inspector, never in code |
| Save system | `src/autoload/manuscrito.gd` — atomic writes, snapshot semantics, version migration |
| Madness | `src/autoload/locura.gd` |
| The shelf / collectibles | `src/autoload/biblioteca.gd` |
| Localisation | `src/autoload/loc.gd` + `locale/*.po` |
| The ending logic | `GameState.compute_ending()` in `src/autoload/game_state.gd` — pure, and unit-tested |
| Everything is a signal | `src/autoload/event_bus.gd` — no direct references between systems |

**The reading rule, in one paragraph.** The world's truth is global (D2) — one value, one
shader uniform, one save field. What each character *makes of it* is not. A character who
can perceive the world's truth reads the world as it is; a character who cannot falls back
on the truth they are made of: Quixote is made of the Book, Sancho of Reality. Quixote
loses the ability to perceive Reality as his Locura rises; Sancho needs the second sight
to perceive the Book at all. That is the whole mechanic, and it is why the truth toggle
alone is not the game — the *swap* is.

**Two values, and they must stay separate.** The world's *look* (`world_blend()`, the
shader) follows the world's truth. The *reader's* reading (`view_blend()`, the objects)
follows the character you are driving. When they were tangled together, pressing `T` and
pressing `L` produced an identical picture, and a stranger asked what the difference was.
There wasn't one. `tests/test_truth_layer.gd` now pins them apart.

---

## 7. Hard-won gotchas — read this before you write code

These cost real time. All are covered by tests so they cannot regress silently.

### 7.1 Godot 4.7's PO loader cannot do two standard gettext things

| gettext | What Godot 4.7 actually does | What we do |
|---|---|---|
| `msgctxt` | Creates the key `context<U+0004>msgid` but leaves the **value empty**. A contextual string can never be translated. | **No `msgctxt`.** Context goes in the key name: `ui.word.page.book`, `character.quixote`. |
| `msgid_plural` | Only `msgstr[0]` is exposed; `msgstr[1+]` are dropped. A file using it is **rejected outright** without a valid `Plural-Forms` header. There is no `ngettext`. | **No `msgid_plural`.** The plural is its own key: `ui.shelf.count` / `ui.shelf.count.plural`, selected with `Loc.tp(key, n)`. |

Verified by `tests/test_translations.gd`. If a future Godot changes this, the build fails rather
than silently breaking every string.

### 7.2 Locales must be *registered* or they are silently ignored

Godot imports `locale/*.po` perfectly, but the engine only loads them into `TranslationServer`
if they are listed in `Project Settings > Localization > Translations`. Without that list every
`tr()` returns the raw key and **nothing errors**. `setup_translations.gd` writes the list; the
test suite asserts it is populated and that each locale returns its own text.

### 7.3 `canvas_item` shaders cannot read the depth buffer

`hint_depth_texture` is unsupported in `canvas_item`, and there is no `SCREEN_PIXEL_SIZE` or
`VIEWPORT_SIZE` built-in. The outline pass is therefore a **luminance Sobel** over the screen
texture, with the pixel footprint from `textureSize(screen_tex, 0)`. For true depth silhouettes,
move it to a `CompositorEffect` + `RDShaderFile` — a Phase 1 task.

### 7.4 Godot 3 API habits that do not exist in Godot 4

- `OS.set_exit_code()` → **Godot 3 only.** In Godot 4 the exit code goes through `quit(code)`.
  Getting this wrong makes a headless test run **hang forever** instead of failing.
- `RenderingServer.global_shader_parameter_add(name, value, type)` → the order is
  `(name, type, value)`.
- `OS.get_locale_country()` → does not exist. Parse `OS.get_locale()` yourself.
- `TranslationServer.get_translation_object_list()` → does not exist.

### 7.5 GDScript typing

`var ok := a == b` fails to infer when `a`/`b` are `Variant`. Write `var ok: bool = a == b`.
This caused a parse error in the test harness that took a while to find.

### 7.6 Save state must be a snapshot, not a reference

`save_state()` returns `duplicate()`d collections. Returning the live array means clearing the
shelf also clears the "saved" shelf. The test suite caught this.

### 7.7 A `Control` under a `CanvasLayer` gets no size from its anchors

**The truth-layer shader had never rendered.** The post-process is a `ColorRect` on a
`CanvasLayer`; the anchors were set to full-rect, and the rect stayed **0×0**, so the
shader never drew a single pixel. The game looked flat, and because "flat" is what a grey
box looks like, nobody noticed.

A `Control` whose parent is a `CanvasLayer` has no `Control` parent, so it is not laid out
against a parent rect and it is not told when the window is resized. Drive the size from
the viewport instead:

```gdscript
set_anchors_preset(Control.PRESET_TOP_LEFT)
position = Vector2.ZERO
size = get_viewport().get_visible_rect().size
get_viewport().size_changed.connect(_fit_to_viewport)
```

See `src/ui/post_process.gd`. If the game ever looks flat and the shader is fine, check the
rect's size first.

### 7.8 `RenderingServer.global_shader_parameter_get_list()` is editor-only

Calling it in a game run logs *"This function should never be used outside the editor"* for
every call, returns nothing useful, and the `add()` that follows then fails because the
parameter already exists (it is declared in `project.godot`). Guard the whole thing with
`Engine.is_editor_hint()`. See `src/autoload/truth_layer.gd`.

### 7.9 The tree root is busy while the main scene's `_ready` runs

`root.add_child(x)` from inside the main scene's `_ready` **fails**: *"Parent node is busy
setting up children"*, and the child never gets its `_ready()`. The tree root is mid-way
through propagating readiness at that point.

This bites in tests, where a suite runs inside the runner's own `_ready`. Use the current
scene as the parent instead — it is already ready:

```gdscript
var parent: Node = tree.current_scene if tree.current_scene != null else tree.root
parent.add_child(scene)
```

### 7.10 A broken test suite hangs CI forever

A suite with a parse error still loads as a `GDScript` object, but it cannot be
instantiated. The runner used to call `.new()` on it, die mid-`_ready`, never call
`quit()` — and CI hung instead of failing. The runner now checks `can_instantiate()` and
records a broken suite as a **failure**. Keep that check.

### 7.11 An exported `NodePath` in a `.tscn` does not resolve the way you hope

`target = NodePath("Characters/Quixote")` on a node that is a *sibling* of `Characters`
resolved to nothing, and so did `../Characters/Quixote`. The path is stored relative to
the scene root, not to the node that owns the property. Rather than fight it, wire node
references in code (`camera_rig.target = quixote`) — a camera pointed at nothing is a
silent failure, and code makes it impossible to miss.

### 7.12 Windows will hand a `.tscn` to your notes app if you let it

`.\tools\godot.ps1 res://src/world/slice.tscn` worked on the build machine and opened the
scene **in the notes app** on the owner's. Nothing was wrong with the script: Windows
resolves `.ps1` and `.tscn` by *file association*, and whatever the machine has
associated with those extensions wins over what you typed. A scene file is not a document;
it is an argument.

The fix is to stop depending on associations: **`tools\play.cmd`**. A `.cmd` is executed
natively by `cmd.exe` — no association, no execution policy, and it works from any shell
and from a double-click in Explorer. Use it for anything interactive; keep `godot.ps1`
for the headless commands, which never touch a scene file by association.

### 7.13 Godot resolves `res://` against the working directory

The same command then opened **Godot** — the Project Manager — instead of the game. Cause:
Godot looks for `project.godot` in the **current working directory**. Launched from
anywhere else it finds no project, so it shows the manager.

`tools\godot.ps1` now does two things: it changes directory to the repository root, and it
passes `--path <repo root>` explicitly. So every documented command works from any
directory, and `build/` always lands in the project. Check the `[project]` line it prints —
if that path is wrong, `res://` is resolving against the wrong project.

### 7.14 A file whose name starts with `_` is invisible to Godot

`FileAccess.open("res://assets/manifiesto/_SAMPLE.bk_ch08_molinos.json")` returned null
with `ERR_FILE_CANT_OPEN`, while `DirAccess` happily listed the file. Godot treats a
leading underscore as "hidden": the file never enters the FileSystem, so it cannot be
read at runtime and it is not exported.

That is why the sample Manifiesto fragment was documentation and never content, and why
the first real fragment is `assets/manifiesto/bk.ch01.apertura.json` — no underscore. If a
data file has to be read by the game, it must not start with `_`.

**The sample is gone.** It had been the format documentation, and a format documented by
a file that no tool can read is a format that drifts: the sample carried the 1615 wording
under an `original_1605` key, and nothing could have said so. The format now lives in the
`_comment` of the first real fragment, where the validator can see it — and it is
enforced, not merely written down.

### 7.15 A game run does not re-import

Change a `.gdshader` and run the game: it uses the **cached** shader, not the one on
disk. You will debug a shader that is not the one you wrote. Run
`.\tools\godot.ps1 --headless --editor --quit` after touching any imported resource —
shaders, textures, `.tres`.

This cost about twenty minutes of "the shader is not doing what I wrote" before the
cause was obvious.

### 7.16 The viewport texture cannot be read while the world is changing

`get_viewport().get_texture().get_image()` returns **null** from inside a signal handler
or during `_process` on the frame the change happens. So a wipe that shows the *old*
frame while the new one is drawn is not available.

The page turn does not need it: the sheet covers the change instead of hiding it behind
the old picture. That is also the better effect — the sheet says "a page turned" rather
than pretending nothing happened.

### 7.17 A SubViewport's image is already the right way up

The printed line for the page turn is rendered into a `SubViewport` and read back with
`get_image()`. That image is **upright** — do not `flip_y()` it. And in the shader it is
sampled with `uv.y` directly: the screen's v is bottom-up and the image's is not, and the
two cancel out. Flipping either one puts the text upside down on the sheet.

### 7.18 A `.ps1` without a BOM is read as Windows-1252

Windows PowerShell 5.1 reads a `.ps1` file **without a BOM** as Windows-1252, not as
UTF-8. Every non-ASCII character in it is then silently mangled — and the failure is
silent, because a mangled *string literal* or *regular expression* simply stops
matching.

This cost an afternoon: `tools\fetch_reference.ps1` had a regex with an accented `í` in
it, it matched zero chapters, and the only symptom was an empty output file and a
confident "0 chapters" message.

**Keep `.ps1` files ASCII-only**, or give them a UTF-8 BOM. `tools\fetch_reference.ps1`
is ASCII-only on purpose and says so at the top.

### 7.19 A signal nobody listens to is a feature that does not exist

`EventBus.toast` was emitted by the companion AI every twelve seconds, for a whole
playtest, and **nothing was subscribed to it**. Every bark the companion ever said went
into the void.

The playtest noticed the symptom — *"Text showing what the other sees feels like too
handholding"* — and read it as "the tag is the wrong UI". The tag was not the wrong UI.
The barks were the right UI and they were invisible. The build had a character who could
not speak.

There is a voice now: `src/ui/bark_line.gd` listens to `EventBus.character_spoke`, and
the barks carry the speaker's name. The rule for the future: **if a system announces
something, something has to be listening.** If you add a signal and nothing subscribes to
it, the feature is not half-built — it does not exist, and no test will catch it.

### 7.20 Wikisource's 1905 transcription loses the first letter of small capitals

The 1905 edition sets the first word of a paragraph in *versalitas*. Wikisource's
transcription renders those as `{{May|n}}` for "En" — the leading capital is gone from
the source, in about 190 lines, and it cannot be repaired from the source.

Project Gutenberg #2000 has the same edition, clean, with all 52 chapters and the
*Curioso Impertinente* in its 1605 place. Use that for the reference text and the
facsimile for checking a wording.

And the reason it matters: **the 1605 and 1615 editions differ**, and DLC 1 is the 1615
book. The 1605 incipit is *"…de los de lanza en astillero, adarga antigua, rocín flaco y
galgo corredor"*; the 1615 revision replaces it with *"…galera en coraza y bacía en el
casco"*. A fragment quoted from the wrong edition is a fragment from the wrong book, and
the project's own sample fragment had the 1615 wording under an `original_1605` key.

**This is checked now, not remembered:** `src/tools/validate_manifiesto.gd` flags any
fragment whose original carries the 1615 wording, and the test suite fails the build if a
fragment the game reads has not been verified against the edition.

---

## 8. The IP situation — read before you write store copy

**"Don Quijote" is NOT available as a game title.** Three occupancies:

1. **An active Steam game** — app 4499530, Rough Diamond Games (Rubén Prende), released May 2026:
   126 chapters, 107K bilingual words, 4 endings, 13 languages with full audio, neo-noir
   Goya/Velázquez/Mignola art, **also built in Godot**. Marketed as "the most complete
   interactive adaptation ever made".
2. **"Don Quijote" (1987) by Dinamic Software** — a Spanish classic; Dinamic is a major
   trademarked publisher.
3. **The 1979 TV series.**

**"Fiel al Libro" is clear** — no game by that name on Steam or itch.io, no pre-existing use in
any media category. But it is a **common Spanish phrase**, so it is a weak, descriptive mark.

**The fix, which costs nothing:** file the **composite**
`FIEL AL LIBRO: LA LOCURA Y LA VERDAD` (classes 9 + 41). The subtitle is already designed; a
longer mark is materially more distinctive. EUIPO first (~€1,150, covers all 27 EU states), then
USPTO (~$700). Both accept intent-to-use — **file before launch, not at launch.**

Referencing "Don Quijote" *descriptively* in the store copy is fine (nominative fair use). Keep
it descriptive; in the English build "Fiel al Libro" must be what the player sees.

**Also play "Hidalgo" and "Dark Bound"** — the closest thematic neighbours. "Dark Bound" (2026,
Spanish) is an investigation game about a descent into madness with eroding sanity: very close
to this project's pillars.

Full memo: `docs/IP_CLEARANCE.md` (private).

---

## 9. Where the project actually is

| | |
|---|---|
| **Phase** | Phase 0 complete. **Phase 1, weeks 1–2: the grey box exists, the playtest has happened twice, and week 3–4 (combat) has started.** |
| **Working code** | ~37 GDScript files: autoload spine, data resources, character abstraction, the truth-layer shader, the save system, the i18n pipeline, the reading rule, the Examine verb, the reactions, the dodge, the swing, the training dummy, and the week 1–2 grey box. |
| **Tests** | 24 suites, 533 assertions, all green, enforced in CI. |
| **CI** | Green on every push. Produces Windows + Linux builds as artifacts. |
| **Game content** | Two primitives (a windmill/giant, a rock/book) as low-poly placeholders, a training dummy and a walled yard, eight reaction lines in three languages, and one real Manifiesto fragment. No art, no levels, no enemies, no audio. |
| **Money spent** | €0. Godot is free, assets are CC0, the only planned spend is the credits song (~$200–800) and later the EUIPO filing (~€1,150). |

**What exists is the skeleton, the tooling, the plan — and now a box that answers the
question.** The mechanic is built and legible: press `T` and the windmill becomes a giant;
press `TAB` and, through Sancho's eyes, it is a windmill again. That is the premise, made
visible.

**And it has its first evidence.** Six runs of the grey box by the owner and one by a
stranger, 19 October 2026, written up in `docs/PLAYTEST_NOTES.md` §6. The verdict is
*"yes, but"*: the premise holds — *"less interesting when both see the same thing"*
(run 4) says the disagreement, not the filter, carries the game, and the stranger was
surprised by the swap. Six of the eight "but"s are fixed and shipped, and the two that
remain are named.

**The stranger's run also found the best bug in the project.** "What is the difference
between pressing T and L? They do the same." They did, because the shader's grade
followed the reader as well as the objects. Now the world's *look* follows the world's
truth and only the *objects* follow the reader, so a mad knight insisting on a giant
stands in a world that has not changed — a different picture from the world itself
turning over.

**The fun is not fully proven.** A build that demonstrates a mechanic is not a mechanic
that is fun. Seven data points is a sample, not a signal, and the strangest data point
still missing is a player who does not know the controls.

**The second playtest, 20 October 2026, added two more "but"s** — and they are the
sharpest ones yet, because they are about the *test rig*, not the idea. *"Examining
shouldn't give away all the information. It should give the information the character
sees."* The panel had been printing the truth table and both characters' readings: the
whole mechanic, handed over for free. It now prints one character's perception and the
one detail that does not add up. And: *"For the dodge it is difficult to assess if it's
fine at this stage without any enemies or space limitations."* A dodge on an empty plain
is a dash. There is now a training dummy in a walled yard, with swings that land.

**What still needs judging is the numbers.** The dodge is 4 m for Quixote and 2 m for
Sancho — half of it — and Quixote is untouchable for a quarter of a second, because he
is not a fighter. The dummy's wind-up is 0.62 s, its reach 2.9 m, its arc 110°. They are
all data, and all of them are now measurable in a rig that has something to fight. The
lock-on (`M`) is in too: the target you are looking at, and a camera that frames both.
Full write-up: `docs/PLAYTEST_NOTES.md` §7.

**The next milestone is week 3–4 — combat — and the first task in it is not a rig.** Two
people, one of them a stranger, asked to *touch* the thing that surprised them, so the
cheapest possible **Examine** beat comes first: walk up to an object, press `E`, and the
game tells you what **you** see. A player who cannot touch the thing that made them
curious will not come back.

**And now it can.** The Examine verb is built, and so is the other half of the same
note: when a character's reading changes, they say so. *"Don Quijote: ¡Un libro! ¡Mirad,
un libro! ¿Quién lo ha puesto aquí?"* The barks used to go into the void — nothing
listened to `EventBus.toast` — so the companion was a label and not a character. It is a
character now.

**All of it is untested.** It was built after the last playtest, and the next run is the
owner's.

---

## 10. If you are picking this up, do this

1. Read `README.md`, then this file, then `GDD.md` (ask the owner for it if you don't have it).
2. Run `tools\setup.ps1` and get the tests green.
3. **Read `docs/NEXT_SESSION.md`.** It has the state, the order of work, and the list of
   things not to do yet.
4. Play the grey box: `tools\play.cmd`. `T` flips the world (and turns a page), `TAB`
   swaps characters, `E` examines the thing in front of you, `Space` dodges, `LMB`/`RMB`
   swing (the light one chains three), `F` raises the guard (Sancho can parry, Quixote
   cannot), `M` locks on, `X` unveils a thing (Sancho's Desvelar), `V` gives Sancho the
   second sight, `L` pushes Quixote's Locura from Lucid to Lost, `F2` hides the perception
   tags, `H` hides the HUD, `K` resets the practice yard (to the west).
5. **The rigs and the animation sets** are the next piece of work, and the tool for them
   is installed: `.\tools\blender.ps1 -b -P <script.py>` runs Blender headless. The brief
   is in the conversation: two distinct skeletons, ~16 clips each, and every contact
   frame landing inside the window the combat code opens.
6. Read `docs/PLAYTEST_NOTES.md` §6 and §7 — the playtest findings, the ten "but"s, and
   the two that have just been built: **B9, the Examine panel that shows a perception
   instead of the truth table**, and **B10, the training dummy in the walled yard**.
   Both are untested.
7. **The next task is week 3–4, and it is art.** The lock-on, the dodge, the chain, the
   guard, the parry, the poise, the asymmetry rules and Desvelar are all in, and the
   silhouettes are distinct (a lance and a basin for Quixote, a sack and a flail for
   Sancho). What is left of 2.6–2.8 is the **animation sets**: eight clips each, and
   hit reactions that are animations rather than a flash and a push.
8. **The one thing that matters:** the vertical slice exists to answer a single question —
   *is the two-truths mechanic fun?* The answer is yes. Everything from here is about
   turning a proven mechanic into a game.

**Three rules for this project:**

1. **Cut from the bottom, never the top.** `ROADMAP.md` §4 has the tiered cut list.
2. **Data-driven, always.** Content goes in `.tres` resources, not in scripts.
3. **One shader, one palette.** "Stylized painterly" is a discipline (Goya + Okami + one ochre
   palette), not a mood board. Ambition here is how a solo dev ends up with forty half-finished
   asset styles.
