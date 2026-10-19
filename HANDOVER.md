# HANDOVER — Fiel al Libro

> **Read this first if you have not seen this project before.**
> Written to be sufficient on its own. You should be able to pick this up cold.
>
> Last updated: **2026-10-19** · Repo: **https://github.com/mariodod/fiel-al-libro**

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
| `HANDOVER.md` | This file. |
| `src/` | All game code. |
| `tests/` | 8 suites, 109 assertions. |
| `locale/` | gettext PO files: es, en, fr + the template. |
| `assets/` | Shaders, the Manifiesto content format. |
| `tools/` | `godot.ps1` (locator), `setup.ps1` (one-command setup). |

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
| `.\tools\godot.ps1 --headless res://tests/test_runner.tscn` | **Run the tests.** Exit 0 = green. |
| `.\tools\godot.ps1 --headless --editor --quit` | Import the project (first run, or after adding assets). |
| `.\tools\godot.ps1 --headless --script res://src/tools/setup_input_map.gd` | Write the input map into `project.godot`. |
| `.\tools\godot.ps1 --headless --script res://src/tools/setup_translations.gd` | **Register `locale/*.po` with the engine.** Run after adding a language. |
| `.\tools\godot.ps1 --headless --script res://src/tools/sync_locales.gd` | Bring every locale in line with the template; report orphans and duplicates. |
| `.\tools\godot.ps1 --headless --export-release "Windows Desktop" build/FielAlLibro.exe` | Build (needs `build/` to exist). |
| `.\tools\godot.ps1 res://src/world/main.tscn` | **Play the grey-box.** TAB swaps characters, T flips the world. |

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
| The visual identity | `assets/shaders/truth_layer.gdshader` — reality / book / ink in one uniform |
| Character abstraction | `src/characters/character_pawn.gd` (base), `player_controller.gd`, `companion_ai.gd` |
| Data-driven content | `src/data/*.gd` — `Resource` subclasses; tune in the inspector, never in code |
| Save system | `src/autoload/manuscrito.gd` — atomic writes, snapshot semantics, version migration |
| Madness | `src/autoload/locura.gd` |
| The shelf / collectibles | `src/autoload/biblioteca.gd` |
| Localisation | `src/autoload/loc.gd` + `locale/*.po` |
| The ending logic | `GameState.compute_ending()` in `src/autoload/game_state.gd` — pure, and unit-tested |
| Everything is a signal | `src/autoload/event_bus.gd` — no direct references between systems |

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
| **Phase** | Phase 0 complete. **Phase 1 (vertical slice) not started.** |
| **Working code** | ~20 GDScript files: autoload spine, data resources, character abstraction, the truth-layer shader, the save system, the i18n pipeline, a grey-box scene. |
| **Tests** | 8 suites, 109 assertions, all green, enforced in CI. |
| **CI** | Green on every push. Produces Windows + Linux builds as artifacts. |
| **Game content** | **None yet.** No art, no levels, no enemies, no audio. The grey box is grey boxes. |
| **Money spent** | €0. Godot is free, assets are CC0, the only planned spend is the credits song (~$200–800) and later the EUIPO filing (~€1,150). |

**What exists is the skeleton, the tooling and the plan.** The fun has not been proven yet —
that is what the vertical slice is for, and it is the single most important thing in the project.

---

## 10. If you are picking this up, do this

1. Read `README.md`, then this file, then `GDD.md` (ask the owner for it if you don't have it).
2. Run `tools\setup.ps1` and get the tests green.
3. Play the grey box: `.\tools\godot.ps1 res://src/world/main.tscn`. TAB swaps, T flips the world.
4. Read `docs/NEXT_STEPS.md` and start at **Week 1**.
5. **The one thing that matters:** the vertical slice exists to answer a single question —
   *is the two-truths mechanic fun?* If it isn't, find out in month 3, not month 24. Everything
   else is secondary.

**Three rules for this project:**

1. **Cut from the bottom, never the top.** `ROADMAP.md` §4 has the tiered cut list.
2. **Data-driven, always.** Content goes in `.tres` resources, not in scripts.
3. **One shader, one palette.** "Stylized painterly" is a discipline (Goya + Okami + one ochre
   palette), not a mood board. Ambition here is how a solo dev ends up with forty half-finished
   asset styles.
