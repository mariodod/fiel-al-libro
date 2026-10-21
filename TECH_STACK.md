# FIEL AL LIBRO — Technical Plan

> Engine, tools, project architecture, performance budgets, and the internationalization pipeline.
> Target: **one solo developer, no budget, PC (Steam) first, stylized painterly 3D.**
>
> Design decisions D1–D7 are locked in [`GDD.md` §21](GDD.md). The ones with engineering weight
> here: **D2** (one global truth layer → one shader uniform, one save field, one network state),
> **D3** (swap, not simultaneous control → the `CharacterPawn` interface, §3.3), **D4** (Humanity is
> a tracked stat, §6 in `GDD.md`), **D7** (48 Manifiesto fragments → 288 literary translations,
> §7).

---

## 1. Engine decision

### ✅ Decision: **Godot 4.x** (GDScript)

| Criterion | Godot 4 | Unreal Engine 5 | Verdict |
|---|---|---|---|
| Cost | Free, MIT, no royalties, no seat licenses | Free < $1M revenue, but 5% above | Tie (Godot wins on certainty) |
| Install / disk | ~1 GB | 100 GB+ (source + DDC + derived data) | **Godot** |
| Dev machine needs | Runs on anything from 2015 | 16 GB RAM, 8-core recommended, SSD | **Godot** |
| Iteration speed | GDScript, instant scene open, hot reload | BP is fast, C++ and shader compiles are slow | **Godot** |
| Stylized painterly 3D | Plenty (Forward+ / Mobile) | Best-in-class (Nanite, Lumen) | Unreal, but not needed here |
| Seamless open world | Weak — you build it by hand | World Partition, best in class | Unreal, but we chose not to |
| Console | 3rd-party porters, extra cost, devkits | First-class, but devkits + cert cost money | Unreal |
| Built-in networking | ENet + WebSocket, decent | Excellent | Unreal, but we need almost none of it |
| 2D for the UI/Manuscrito | Excellent, same project | Clunky without extra tooling | **Godot** |
| Asset pipeline | Blender/Mixamo/CC0 all import cleanly | Same, but more import friction | **Godot** |
| Steam | GodotSteam (MIT) + Steamworks | Native, better | Unreal |

### Why not Unreal 5 (be honest with yourself)

UE5 is the right engine for the *ambition you described in the bullet list* (Skyrim-scale seamless
open world, console day one, 3 DLCs, a team). It is the wrong engine for **your actual
constraints** (solo, no money, one laptop, a painterly stylized look, an i18n-heavy, UI-heavy,
narrative-heavy game). UE's advantages — Nanite, Lumen, World Partition — are all *fidelity*
advantages, and you explicitly chose a **stylized painterly** look, which is the one category where
UE's headline features matter least.

The real cost of UE5 for a solo dev is not the license, it is the **iteration tax**: a shader
compile hitch on every material tweak, a 3-minute cook before you can look at a level, a project
that won't open on a laptop, and a Blueprint/C++ mental tax while you're still learning the design.

### When you should switch to UE5
Move to UE5 if **all three** become true:
1. You have funding or a team of 4+.
2. You are targeting console on day one.
3. You are committing to a seamless open world (the *Skyrim* lane, not the *Dark Souls* lane).

The good news: the architecture in §3 is engine-agnostic in shape (data-driven resources, an
autoload service layer, a character-pawn interface, a central truth-layer state). A port is
painful but not a rewrite.

### The one alternative worth considering
**Godot 4 but 2.5D (isometric, like *Hades* / *Death's Door*)** rather than free-roaming third-person.
It is 30–40% cheaper to build, makes the two-truth layer *much* easier to read (you see more of the
world at once), and it removes most camera/AI/animation headaches. It loses the *Skyrim* feeling
and the horseback riding. **Recommendation:** if the vertical slice feels slow to build in 3D,
pivot to 2.5D — it is the most likely successful pivot, and Godot makes it a project setting
change, not a rewrite.

---

## 2. Engine configuration

### 2.1 Project settings

```
Renderer:            Forward+ (PC default)  →  Mobile (perf tier)  →  Compatibility (legacy)
Texture format:      VRAM Compressed (S3TC/BPTC) for PC; Basis Universal if you plan Switch
MSAA:                2x (Forward+ has no built-in TAA — do not enable TAA)
Use HDR 2D:          On
Default clear color: N/A (always driven by the truth-layer shader)
Physics:             Jolt (Godot 4.4+)  — better character controllers than GodotPhysics3D
Threading:           Physics on a separate thread; WorkerThreadPool for baking/streaming
```

> **Note on MSAA vs. the line-art pass:** the ink outline is a screen-space edge detect. It looks
> best on MSAA 2–4x. If you use a TAA/FXAA-ish solution, the line will shimmer. Prefer **MSAA 2x
> + a light FXAA** on the low tier, MSAA 4x on high.

### 2.2 Rendering pipeline (this is the visual identity — get it right early)

```
WorldEnvironment
 ├─ Tonemap:      AgX (Godot 4.3+) or Filmic.  AgX desaturates highlights beautifully.
 ├─ Adjustments:  per-region contrast/saturation/tint LUTs (use a ColorCorrection LUT resource)
 ├─ Glow:         ON, low intensity — used mainly in the Book layer
 ├─ SSAO:         OFF by default (expensive, ugly on painterly art); enable as a "high" option
 ├─ SDFGI/SSIL:   OFF (bake instead)
 ├─ Fog:          depth fog with a per-region color; the single cheapest "scale" trick
 └─ Volumetrics:  ON only for 3 hero locations (caves, the castle)
Custom fullscreen shader (a ColorRect / a ViewportTexture pass):
 ├─ truth_uniform: 0.0 = Reality, 1.0 = Book, 0.5 = Ink (blend, not a hard switch)
 ├─ line_art:      screen-space depth+normal edge detect → pen-and-ink contour
 ├─ paper_grain:   animated fbm noise, subtle
 ├─ letterforms:   drifting glyph sprites, Book layer only
 └─ ink_bleed:     domain-warped distortion, Ink layer only
```

**Everything else in the game is lit with baked lightmaps + a small number of dynamic lights.**
This is both a performance decision and an art decision: a painterly 16th-c. look wants soft,
directional, high-contrast light, which bakes beautifully.

### 2.3 Lighting & world building

- **LightmapGI** for static geometry, per-region, baked offline (use `LightmapGI` in Godot 4, or
  bake in Blender and import as a second UV set).
- **VoxelGI / SDFGI:** off. Use baked lightmaps + a "fake" bounce via a low-intensity OmniLight
  budget (max 8 dynamic lights per frame, globally).
- **Fog:** per-region `Environment.fog_*`. Long sight-lines + fog = perceived scale. Free.
- **Terrain:** `HeightMapShape3D` for collision; `FastNoiseLite` for the heightmap; a
  `PlaneMesh` with a splat material driven by 4–6 splat maps.
- **Foliage:** `MultiMeshInstance3D` with `ArrayMesh` + per-instance colour variation. 10k–50k
  grass instances in a single MultiMesh. Trees as MultiMesh too (billboard for far LOD).
- **Occlusion:** `OccluderInstance3D` boxes for buildings/rock formations. Cheap, big win.
- **Draw distance:** 250–400 m in the plains, 80–120 m in caves. Per-region, in the
  `Environment`.

---

## 3. Project architecture

### 3.1 Directory layout

```
fiel-al-libro/
├─ project.godot
├─ assets/
│  ├─ models/          .glb (Blender-exported)
│  ├─ textures/        .png / .ktx
│  ├─ audio/           .wav / .ogg
│  ├─ fonts/           .ttf / .otf  (see §7.4)
│  ├─ shaders/         .gdshader
│  └─ data/            .tres resources (see below)
├─ src/
│  ├─ autoload/        # singletons
│  │  ├─ event_bus.gd
│  │  ├─ game_state.gd      # global truth layer, flags, ending variables
│  │  ├─ manuscript.gd      # save system ("El Manuscrito")
│  │  ├─ loc.gd             # localization helper
│  │  ├─ memoria.gd         # Recuerdos (XP) / progression
│  │  ├─ locura.gd          # madness director, per-character
│  │  ├─ truth_layer.gd     # the two-truths state machine + shader uniform driver
│  │  ├─ audio_director.gd
│  │  └─ biblioteca.gd      # the shelf / loadout / collectibles
│  ├─ data/            # Resource subclasses + .tres instances
│  │  ├─ character_data.gd
│  │  ├─ enemy_data.gd
│  │  ├─ book_data.gd
│  │  ├─ chapter_data.gd
│  │  ├─ venture_data.gd
│  │  └─ locale_ref.gd
│  ├─ systems/
│  │  ├─ combat/
│  │  ├─ investigation/     # Lectura: anamorphosis detection & resolution
│  │  ├─ verdict/           # truth-shifting scripted moments
│  │  ├─ interact/          # interactions, evidence, veredict triggers
│  │  └─ ai/
│  ├─ characters/      # player rigs, NPC rigs, mounts
│  ├─ enemies/
│  ├─ world/           # region scenes, modular kits, level chunks
│  ├─ ui/              # Manuscript UI, HUD, shelf, codex
│  └─ tools/           # editor-only helpers, import scripts
├─ locale/             # .po files, one per language (see §7)
├─ tests/              # GUT unit tests
├─ addons/             # GodotSteam, GUT, DialogueManager (if used)
├─ build/              # export presets, CI scripts
└─ docs/               # this folder
```

### 3.2 Data-driven design (critical for a solo dev)

Never hard-code content in scripts. Everything tunable is a **Godot `Resource`** with an
`@export`ed set of fields, saved as `.tres` in `assets/data/`, and referenced by the scenes.

```gdscript
class_name CharacterData extends Resource

@export var id: StringName
@export var display_name_key: StringName          # localization key, never a literal
@export var max_madness: int = 100
@export var stamina_max: float = 100.0
@export var poise: float = 30.0
@export var light_attack: AbilityData
@export var heavy_attack: AbilityData
@export var abilities: Array[AbilityData]
@export var truth_layer_affinity: int               # 0 = Reality, 1 = Book
@export var model_scene: PackedScene
```

**Why this matters for you:** a designer (you) can add a new enemy, a new book, a new Venture, or
a new line of dialogue by editing a `.tres` in the Godot inspector, with no code change and no
recompile. It is the difference between 12 months of work and 30.

### 3.3 The character-pawn interface (the co-op-proof architecture)

**The most important architectural decision in the project.** Build it on day one, even though
co-op is a year away.

```
PlayerController  (input)  ──▶  CharacterPawn (interface)
                                        ├─ QuixotePawn
                                        └─ SanchoPawn

AICompanion      (brain)  ──▶  CharacterPawn (same interface)
```

- `CharacterPawn` exposes: `move(dir)`, `light_attack()`, `heavy_attack()`, `dodge()`, `block()`,
  `ability(id)`, `set_truth_view(layer)`, `get_madness()`, `die()`.
- The **AI companion** implements the same interface. Switching characters = changing which
  driver owns the pawn. No special-case code, ever.
- In co-op, the second player is a remote driver on the same pawn. **The game is co-op-ready
  without having written any co-op code.**
- The AI companion is *not* a dummy: it barks, reacts, solves a few things, and complains. It is
  a character. Budget real time for it — it is a third of the game's personality in single player.

### 3.4 Scene composition & streaming

- One scene per **region chunk** (~5–15 min of play), loaded with `ResourceLoader.load_threaded_request`
  and `change_scene_to_packed`.
- **Do not** build one giant scene. Godot's editor will fight you.
- Keep a `RegionGraph` in `game_state` so travel between chunks is data-driven.
- Streaming budget: keep resident memory under ~1.5 GB.

### 3.5 Version control

- **Git + Git LFS**, hosted on a private GitHub repo (free).
  - LFS-track: `.blend`, `.png`, `.wav`, `.ogg`, `.fbx`, `.glb`, `.ttf`, `.po`? (PO files are text —
    track them normally, they diff beautifully).
  - **Do not** LFS-track: `.import` files (Godot regenerates them), or you will have merge hell.
- `.gitignore` essentials:
  ```
  .godot/
  /build/
  export_presets.cfg        # contains signing secrets — keep OUT of git, template it instead
  *.tmp
  ```
  → commit `export_presets.template.cfg` and have CI regenerate the real one from secrets.
- **Do not commit `.godot/`** — it contains absolute paths and local settings.
- **Do commit the `*.import` sidecar files as plain text** (not LFS). They are small and they
  hold the import presets — committing them is what makes a fresh clone on a new machine import
  identically. This is the fix for the "the meshes broke on the other computer" problem described
  in §4.2.
- Branching: `main` (always shippable) + `feature/*` + `release/*`. Tag releases `v0.1.0`.
- **Commit discipline:** commit the `.tres` data files separately from scenes so a content change
  is a 5-line diff. This is what makes a 2-year solo project survivable.

### 3.6 Backup

Three copies, two media, one offsite. You are one disk failure from losing 2 years:
1. GitHub (remote).
2. A local external drive (weekly mirror).
3. **Monthly archive** of the whole project folder to a cloud drive (Blobs, Backblaze B2 ~$6/mo, or
   Google Drive). Automatic. Set it up on day one.

---

## 4. Asset & content pipeline

### 4.1 Everything you need is free

| Need | Free tool | Notes |
|---|---|---|
| 3D modelling | **Blender 5.2 LTS** | Sculpt, retopo, UV, vertex paint. Everything else is optional. |
| Texturing | **Blender** + **Quixel Mixer** (free w/ Epic account) | Or **Material Maker** (open source) |
| Base textures | **ambientCG** (CC0), **Poly Haven** (CC0 HDRIs), **Kenney** (CC0) | 100% legal, shippable |
| Props / kits | **itch.io** asset packs, **Quixel** free library, **Sketchfab** (check licence per-asset!) | Check every licence |
| Rigging / mocap | **Mixamo** (free) | Base clips only — hand-author the signature animations |
| Iconography / UI | **Kenney UI packs**, Aseprite (paid, $20) or **LibreSprite** (free) | The Manuscript UI is hand-painted |
| Fonts | **Google Fonts** (OFL) | See §7.4 — do NOT use a font without a permissive licence |
| SFX | **Freesound** (CC0 filter), **Sonniss GDC bundles**, **Kenney audio** | |
| Music | **LMMS** (free), or commission | The credits song is commissioned — see GDD §14 |
| Voice | Your own voice + friends, or a cheap service | Barks only at launch |
| Voice cleanup | **Audacity** (free) | |
| Version control | Git + LFS | |
| CI | **GitHub Actions** (free for public repos, 2000 min/mo for private) | Headless export + unit tests |
| Store page | **OBS** (capture), **DaVinci Resolve** (free) (edit) | Trailer + capsules |
| Crash reports | **Sentry** (free tier) or Godot's built-in | |
| Localization | **Weblate** (self-hosted, free) or **PoEditor** (free tier) | See §7.3 |
| Analytics | **Steamworks** (free) + **PlayFab** (free tier) | Optional |

### 4.2 The Blender → Godot import preset (set it once, never again)

Godot's importer settings are per-project and stored in `.godot/imported` (not in git), so **every
new machine re-imports with default settings** and your meshes break. Fix this:

1. Set the import defaults once (Godot → *Editor → Editor Settings → Filesystem/Import* → **Set as
   Default for 'Scene'**).
2. Import preset for `.blend`/`.glb`:
   - ✅ Generate LODs
   - ✅ Use **SDFGI** off, **Lightmap** on
   - ✅ Mesh compression: **Disabled** (keeps vertex colors and avoids artifacts)
   - ✅ Materials: **Extract** → the `.tres` is a separate file you can edit
   - ✅ **Apply** transforms
3. **Re-export the preset**: `Editor Settings → Import → Export as "Default Settings"`? No — instead
   keep a committed `docs/import-presets.md` and set the defaults once per machine.
4. Verify: the reimport must produce identical results. Test by deleting `.godot/` and reimporting
   on a clean clone. **Do this in month 1, not month 18.**

### 4.3 Content budgets (design your content to fit)

| Asset | Target per release | Notes |
|---|---|---|
| Character (heroic) | 2 | Quixote, Sancho |
| Character (NPC) | 12–18 | Recombine: 6 body types × 3 outfits × hat/prop variants |
| Enemy | 18 base + 3 boss | Base types reskin per region with different lore |
| Mount | 2 | Rocinante, Dapple |
| Environment kit | 15 modular kits | Recombined across 5 regions |
| Prop | 120–200 | Kitbash + variation |
| Animation (per hero) | 14–18 | idle, run, roll, 3× light, heavy, block, parry, hit, death, mount, interact, madness variants |
| Book / codex art | 15 | Each a unique cover — a nice personal touch |
| Music track | 6–8 | 1 credits song, 5 region variants, 1 hub, 1 boss |
| Voice | 0 at launch | Barks only |

---

## 5. Performance budgets (PC, Steam)

| Tier | Target | Preset |
|---|---|---|
| **Minimum** (GTX 1050 / RX 560, 8 GB) | 1080p / 30 fps | Forward+ → **Mobile renderer**, no shadows, no SSAO, 100 m draw, grass 5k, 4 dynamic lights |
| **Recommended** (GTX 1660 / RX 5500 XT) | 1080p / 60 fps | Forward+, 2x MSAA, 250 m draw, grass 20k, 8 dynamic lights |
| **High** (RTX 3060+) | 1440p / 60 fps | Forward+, 4x MSAA, 400 m draw, grass 50k, 16 lights, volumetrics |
| **Ultra** | 2160p / 60 fps | + 8x MSAA, deferred, full foliage |

**Hard rules:**
- **Frame budget at 60 fps = 16.6 ms.** Target ≤ 12 ms CPU + GPU to leave headroom.
- **Draw calls: < 1500** at the recommended tier. Use MultiMesh aggressively.
- **No per-frame allocations in GDScript** in combat code. Pool objects. `GDScript` GC is not
  free — a `PackedVector3Array` per frame in a hot loop is a real frame-time source.
- Profile with Godot's built-in profiler + **RenderDoc** (free) for GPU work.
- **Test on the minimum-spec machine from month 1**, not at the end.

---

## 6. Testing & CI

- **Unit tests:** a small dependency-free harness (`tests/test_harness.gd`) rather than GUT.
  GUT is an addon you must install, and this project must run its whole CI on a fresh clone with
  nothing but Godot. If you outgrow the harness, swapping in GUT changes only the `suite()`
  signature in each test file.
  - These are the systems you will break while refactoring, and they are all covered:
    `locura.gd`, `truth_layer.gd`, `manuscrito.gd` (save/load round-trip), `biblioteca.gd`,
    `memoria.gd`, the ending aggregation, and the locale key parity.
  - **Run them:** `godot --headless res://tests/test_runner.tscn` → exit 0 = green.
    The suite runs as a *scene*, not via `--script`, so Godot's autoloads exist exactly as they
    do in a real run.
  - Current state: 7 suites, 84 assertions, 0 failures.
- **CI (GitHub Actions), on every push to `main`:**
  1. Headless Godot import check → fails if a scene/resource/script is broken.
  2. Run the test suite.
  3. Export **Windows** and **Linux** builds and upload them as artifacts.
  - `setup-godot` installs the export templates; the cache keeps it to ~5 min per push.
- **Locale parity is a test, not a chore.** `tests/test_locales.gd` fails the build if any
  `locale/*.po` has drifted from `messages.pot` — a key added to the template and forgotten in
  `fr.po` would otherwise ship as a raw key string in the French build.
  - Fix it locally with `godot --headless --script res://src/tools/sync_locales.gd`, which
    appends the missing entries with empty `msgstr` and carries the translator comments across.
- **Playtest builds:** itch.io private page → build → invite. Use a **Steam Playtest** once
  you're on Steam, so you get Steam's own community and wishlist ranking.
- **Bug tracker:** GitHub Issues with labels (`bug`, `polish`, `i18n`, `perf`, `content`).
  A solo dev with a text file of bugs loses them; an issue tracker with labels does not.

### 6.1 Save system — "El Manuscripto"

Implemented in `src/autoload/manuscrito.gd` (autoload name: `Manuscrito`).

```gdscript
const SAVE_VERSION := 1
const SAVE_DIR := "user://saves"
const SLOT_COUNT := 3

func save_game(slot: int) -> bool:
    var payload := {
        "version": SAVE_VERSION,
        "timestamp": Time.get_unix_time_from_system(),
        "ms": OS.get_unique_id(),          # Steam user id when using GodotSteam
        "game_state": _serialize_game_state(),
        "truth_layer": TruthLayer.save_state(),
        "locura": Locura.save_state(),
        "memoria": Memoria.save_state(),
        "biblioteca": Biblioteca.save_state(),
    }
    # write to a .tmp first, then rename → atomic save, no corruption on power loss
```

- **Atomic writes** (write `.tmp`, then `DirAccess.rename`) — a half-written save from a crash
  during a boss fight is the worst possible bug.
- **Snapshot semantics.** Every `save_state()` returns a `duplicate()`d copy. Returning the live
  array is a bug the test suite caught during Phase 0: clearing the shelf also cleared the
  "saved" shelf.
- **Migrate on load**: if `data.version < SAVE_VERSION`, run the migration chain. Keep
  migrations forever; you *will* break old saves in month 14.
- **3 save slots** + autosave at each Posada.
- **Cloud saves** via GodotSteam (free) once on Steam.

---

## 7. Internationalization pipeline

This is a first-class system, not a post-launch chore. It has to work on day one because the
**Book layer** (the 1605 Spanish text vs. the modern rendering) is a *design* pillar, not a
translation afterthought.

### 7.1 Two string layers, and why they are different

| Layer | What it is | Languages | Where it lives |
|---|---|---|---|
| **Game layer** | UI, dialogue, codex prose, item text, tooltips, tutorials | All N languages | `locale/*.po` |
| **Book layer** | Fragments of the 1605 original + a **modernized rendering** | The original is **identical in every build** (it's source content); the modern rendering is localized | `assets/manifiesto/*.json` (one file per fragment) |

> **Implemented:** `assets/manifiesto/bk.ch01.apertura.json` shows the real structure —
> the 1605 text, a `modern` object with one entry per language, optional `pd_translations`
> (Motteux 1700, the French 1632 translation, …), a `source` block with provenance, and a
> `verified` flag. **A fragment with `verified: false` does not ship**, and the validator
> and the test suite both enforce it.

**Content budget (D7): 48 fragments** = 32 Venture (8 × 4) + 5 Region + 3 Posada + 6 Colofón +
2 Ending. Each needs a modernized rendering in 6 launch languages → **288 literary
translations**, plus provenance records and optional PD translations. This is the single largest
translation task in the project; it starts at month 12, not month 24. Full breakdown in
`GDD.md` §20.1.

The Book layer panel shows:

```
┌──────────────────────────────────────────────┐
│  «Y luego, saliendo del.real., le salió al  │
│   encuentro un yerro, que no, y luego un      │   ← 1605 original (fixed, always Spanish)
│  erville, que era de la mesma ciudad.»       │
│                                              │
│  ──  Modern rendering  ────────────────────  │   ← localized
│  And then, leaving the inn, he met with an   │
│  error, and then a knight, who was from the  │
│  same town.                                  │
│                                              │
│  [ ◀◀ ]  Chapter VIII  [ ▶▶ ]  Source: Wikisource │  ← provenance + navigation
└──────────────────────────────────────────────┘
```

For non-Spanish locales, the original panel stays in Spanish and gains a translator's note.
If a **public-domain translation** exists for that language for that fragment, it can be offered
as a third tab: *"Motteux, 1700"* / *"Ormsby, 1901"*. **This is the feature that makes the game
feel scholarly and it's nearly free to implement** — the texts are on Wikisource.

### 7.2 Key naming convention

**Never use the source text as the key.** Keys must survive a rewrite of the string.

```
<namespace>.<domain>.<key>
```

| Namespace | Domain | Example |
|---|---|---|
| `ui.` | menus | `ui.menu.new_game` |
| `ui.` | prompts | `ui.prompt.interact` |
| `dia.` | dialogue lines | `dia.quixote.posada.001` |
| `dia.` | barks | `dia.sancho.bark.014` |
| `it.` | items/books | `it.book.cid.name` / `it.book.cid.desc` |
| `it.` | abilities | `it.ability.desvelar.desc` |
| `tip.` | tutorials | `tip.lectura.intro` |
| `loc.` | UI strings for localization itself | `loc.language.name.fr` |
| `bk.` | the Book layer | `bk.ch08.molinos.01` |

**Rules:**
- Keys are `StringName` (compile-time interned) — use `&"ui.menu.new_game"` not `"ui.menu.new_game"`.
- One key = one string. Never concatenate translated fragments.
- `display_name_key` in every data resource; no literal display names in `.tres` files.
- **Character limits:** for UI strings that must fit a fixed panel, add a translator comment
  `# MAXLEN: 24` and keep 35% slack. Never hard-code a fixed-width text box.

#### ⚠️ Two Godot 4.7 limitations that shape this convention

These were found empirically (probe files, then confirmed by the test suite) and they are
**not** how standard gettext works. Both are load-time behaviours of
`core/io/translation_loader_po.cpp`:

| gettext feature | Godot 4.7 reality | What we do instead |
|---|---|---|
| `msgctxt` | Creates the key `context<U+0004>msgid` but leaves the **value empty**. A contextual string can never be translated. | **No `msgctxt`.** The context is part of the key name: `ui.word.page.book`, `ui.word.page.nav`, `character.quixote`. |
| `msgid_plural` | Only `msgstr[0]` is exposed; `msgstr[1+]` are dropped. A file using `msgid_plural` is **rejected outright** unless the header carries a valid `Plural-Forms` line. There is no `ngettext`. | **No `msgid_plural`.** The plural form is its own ordinary key: `ui.shelf.count` / `ui.shelf.count.plural`, selected with `Loc.tp(key, n)`. |

Both are verified by `tests/test_translations.gd`, so a future Godot upgrade that changes the
behaviour fails the build instead of silently breaking every contextual and plural string.

**Plurals**

```gdscript
Loc.tp(&"ui.shelf.count", 1)   # "1 book on the shelf"
Loc.tp(&"ui.shelf.count", 4)   # "4 books on the shelf"
```

Never hand-roll `"1 libro / N libros"` in a script — that is exactly the bug the i18n QA pass
is for, and languages disagree about it (Russian has three plural forms, Arabic six).

### 7.2b Registering the locales with the engine

**This is the step that is easy to miss and fails silently.** Godot imports `locale/*.po` into
`Translation` resources perfectly, but the engine does not load them into `TranslationServer`
unless they are listed in `Project Settings > Localization > Translations`. Without that list
every `tr()` call returns the raw key — `ui.menu.new_game` instead of `Begin the manuscript` —
and nothing errors.

Run the tool after adding a language:

```bash
godot --headless --script res://src/tools/setup_translations.gd
```

It discovers every `locale/*.po` and writes the list into `project.godot`. The test suite
(`tests/test_translations.gd`) asserts the list is populated and that each locale really returns
its own text, so this can never silently regress.

### 7.3 Toolchain

**Authoring format: `gettext` PO** (`.po`/`.pot`). Chosen because it natively supports translator
comments and fuzzy matching, and every translation platform speaks it. (Contexts and plurals are
*not* used — see the table above for why.)

```
locale/
├─ messages.pot          # template, generated from code
├─ es.po                 # source language (Spanish)
├─ es_419.po             # Latin American Spanish
├─ en.po
├─ fr.po
├─ de.po
├─ pt_BR.po
├─ ja.po
├─ ko.po
├─ zh_Hans.po
├─ ru.po
├─ pl.po
├─ it.po
└─ tr.po
```

**Workflow:**
1. **Extract** strings: run Godot headless with `--headless --script res://src/tools/extract_strings.gd`,
   which walks the scenes, reads every `StringName` that matches the key convention, and writes
   `messages.pot`. (Godot 4 has a built-in "Extract Strings to CSV" via the editor too, but a
   scripted extractor gives you the **max-length and context** metadata that the built-in lacks.)
2. **Translate**: **Weblate** (self-hosted, free, git-backed, great for a solo dev who speaks
   Spanish and can pull in community translators) or **PoEditor** (free tier, simpler).
   - Crowdin is better if you want community translation at scale — but it costs nothing for open
     source and it treats you as a project owner. Either is fine; Weblate is the more solo-friendly
     default because it can live in the same repo.
3. **Import**: Godot imports `.po` files natively as `Translation` resources. Ensure the **import
   path** and the locale code are set right, and that `.po` files are in the project root's
   `locale/` folder.
4. **Ship**: `loc.gd` (autoload) selects the locale from the OS / Steam / a settings menu.

**In-game translation UI:** a "Código" screen in the Manuscript where the player can read the
game's text in any language they install, and even *add* one (import a `.po` from a file picker).
This is a *cheap, delightful* feature: your Spanish community can translate the game for you, and
you have a distribution channel built in. It is also a real marketing differentiator.

### 7.4 Fonts (the #1 i18n failure point)

Ship **two** font families and no more:

| Use | Font | Coverage |
|---|---|---|
| UI / dialogue | **Noto Sans** (OFL) | Latin Extended, Cyrillic, Greek, Turkish, Vietnamese |
| Book layer (the 1605 facsimile) | **EB Garamond** or **Cormorant Garamond** (OFL) | Latin + a 1605-style feel |

**CJK, Arabic, Indic, and Hebrew:** do **not** bundle 20 MB CJK fonts in the base build.
Use Godot's `SystemFont` resource with a fallback list:

```gdscript
var sys := SystemFont.new()
sys.font_names = PackedStringArray([
    "Noto Sans CJK SC", "Noto Sans CJK JP", "Noto Sans CJK KR",
    "Microsoft YaHei", "PingFang SC", "Yu Gothic", "Meiryo",
    "Noto Sans Arabic", "Noto Naskh Arabic", "Noto Sans Devanagari"
])
sys.allow_system_fallback = true
```

- A `SystemFont` with `allow_system_fallback = true` covers CJK/Arabic on real devices.
- **Verify on a clean Windows machine with no language packs installed** — that is where the
  tofu boxes appear.
- If you need a *guaranteed* result, download Noto Sans CJK (the "Variable" or `NotoSansSC`
  subset) and subset it per-language with `fonttools pyftsubset` → ship a separate download or a
  language pack. Budget a day for this.
- **Always render the 1605 Spanish text in a font with full Latin-1 + ligature support** and with
  proper italic/long-s handling if you go for the 1605 typography.

### 7.5 QA for localization

Do these **before** every release. They catch 90% of localization bugs.

1. **Pseudo-localization.** Script that copies every string and inflates it by ~40% with
   accented pseudo-Latin (`Ëñçôdé Ñöñséẗ`). Run the game with it on. Anything that overflows,
   clips, or breaks layout shows up immediately.
2. **Text-length audit.** A script that flags any string > 40 chars in a UI slot with a fixed
   width.
3. **Screenshot sweep.** Automate with `godot --headless` + a screenshot script per locale per
   main menu, and eyeball a contact sheet.
4. **Right-to-left readiness.** Not shipping RTL now, but design for it: use anchors, never
   hard-coded left/right for panels; use `layout_direction` on containers; avoid directional icon
   metaphors. It costs nothing now and saves a rewrite later.
5. **Font fallback sweep.** Render a test scene with every UI string in every shipped language,
   look for tofu.
6. **Cultural review** of each language's *register*: the game is a period piece with a modern
   sensibility in places; don't let a translator sand it into blandness or, worse, into
   contemporaneity.

### 7.6 Language roadmap

| Wave | Languages | When |
|---|---|---|
| **1.0 (launch)** | es-ES, en, es-419, fr, de, pt-BR | 0.5 before launch |
| **Post-launch 1** | it, pl, ru, tr | +2 months, community-driven |
| **Post-launch 2** | ja, ko, zh-Hans | +3 months |
| **Stretch** | ar, he, hi, id, vi | Only if the in-game translation feature gets traction |

**Do not launch in 14 languages.** Launch in 6 that you can *review*, then let the community
extend it. The in-game translation feature (§7.3) makes the community path real.

**Es-419 vs. es-ES:** not just spelling. Latin American Spanish readers will want *tuteo*
("tú") and different lexicon. Ship them as **separate `.po` files**, and treat es-419 as a
*first-class* translation, not a copy — this game is a gift to the Spanish-speaking world and
southern-Spain-only diction will read as parochial to half your audience.

---

## 8. Steam & publishing

| Item | Cost / effort |
|---|---|
| **Steam Direct** fee | **$100 per app**, recoupable after $1,000 in adjusted gross revenue |
| **Store page** | Capsule 616×353, header 460×215, screenshots ≥1920×1080, trailer ≥30 s |
| **Early Access** | Steam requires 30 days minimum on the first release; do not do it for a 10-hour game — do a **Playtest** instead |
| **Steam Playtest** | Free, great for feedback + wishlists |
| **GodotSteam** | MIT plugin for achievements, cloud saves, rich presence, Workshop |
| **Rich Presence** | Show the current chapter + which character you're playing |
| **Steam Cloud** | 3 slots, free, uses the Manuscript save |
| **Workshop** | Consider it for user-generated "anamorphosis" locations — great community hook, and cheap once the data format is text |
| **Deck** | Godot games need no special work; verify touch/mouse on Deck |
| **Localization** | Steam's own translation tools can help but won't replace your own pipeline |

**Wishlist strategy:** build the Steam page *before* the game is done, with real key art from the
vertical slice. The demo (itch.io + Steam demo) is the conversion funnel. Target: 3,000 wishlists
before the 1.0 date for a realistic chance.

---

## 9. Build & release

| Item | Choice |
|---|---|
| **Version control** | Git + Git LFS, GitHub private repo |
| **CI** | GitHub Actions: headless import check → GUT tests → export build → artifact |
| **Export targets** | Windows (x86_64) first → Linux → macOS |
| **Build script** | `godot --headless --export-release "Windows Desktop" build/FielAlLibro.exe` |
| **Versioning** | SemVer for the app; a separate `content_version` for the book/Manifiesto content |
| **Patch notes** | Keep `CHANGELOG.md` in the repo, auto-generate the Steam notes from it |
| **Modding** | Ship the game with a documented "Mods" folder that loads `.json` + `.po` — a huge value-add for a literary game with a Spanish-speaking community |

---

## 10. Backlog: tech tasks, in priority order

**Phase 0 — Foundation (weeks 1–4)** — *done, except where noted; see `TODO.md`*
- [x] Godot 4.7 project, Git + LFS, `.gitignore`, `.gitattributes`, CI pipeline (import check + test + export)
- [x] Blender → Godot import presets, documented (`TECH_STACK.md` §4.2)
- [x] `EventBus` + `GameState` autoloads with unit tests
- [x] `CharacterPawn` interface + `PlayerController` + `CompanionAI` (this validates the co-op architecture early)
- [x] The truth-layer shader — one uniform, three looks
- [x] `loc.gd` + the PO pipeline + 3 locales (es, en, fr) + `sync_locales.gd` + parity test
- [x] Save system with atomic writes + version migration
- [x] The grey-box scene: walk, swap, flip the world
- [ ] Install export templates locally and produce a first Windows build
- [ ] Set up the monthly cloud backup

> **Note on the shader:** Godot 4's `canvas_item` shaders cannot read the depth buffer
> (`hint_depth_texture` is unsupported there), and have no `SCREEN_PIXEL_SIZE` or `VIEWPORT_SIZE`
> built-ins. The outline pass is therefore a luminance Sobel over the screen texture, with the
> pixel footprint derived from `textureSize(screen_tex, 0)`. For true depth silhouettes, move the
> pass into a `CompositorEffect` with an `RDShaderFile` — a Phase 1 task.

**Phase 1 — Vertical slice (weeks 5–12)**
- [ ] Player controller: walk, run, dodge, lock-on
- [ ] Quixote rig + 8 animations; Sancho rig + 8 animations
- [ ] Combat: light/heavy/dodge/block, stamina, poise, hit reactions
- [ ] One enemy with a Book form and a Reality form + Sancho's `Desvelar`
- [ ] `Lectura` mode: the screen-space highlight + one anamorphosis you must view from a spot
- [ ] One Posada (checkpoint, shelf, NPC)
- [ ] One Venture (boss) with two resolutions
- [ ] The Manuscript UI shell
- [ ] The credits song, commissioned, playing in the Posada

**Phase 2 — Production**
- [ ] Region kits (15) → regions (5)
- [ ] The full enemy roster
- [ ] The bookshelf / loadout system
- [ ] The 15 books + the Manifiesto facsimile reader
- [ ] Endings & the manuscript prologue
- [ ] Steam page, demo, wishlist push
- [ ] Localization to 6 languages

---

## 11. Key risks (technical)

| Risk | Impact | Mitigation |
|---|---|---|
| **Godot's 3D tooling fights you** (cameras, animation retargeting, IK) | High — can kill the project's pace | Use a simple third-person camera; author animations per rig, never retarget. Consider 2.5D if it bites. |
| **The truth-layer shader tanks performance** | Medium | Make it a single pass; provide a "reduced effects" toggle from day one; test on min-spec. |
| **GDScript performance in combat** | Medium | Pool everything; avoid per-frame allocation; profile early with a 500-enemy stress test. |
| **The line-art pass shimmers with TAA** | Low | Use MSAA, not TAA. |
| **You lose the project** | Catastrophic | 3-2-1 backups. Automate the monthly archive. |
| **Scope explosion from the 3 DLCs** | High | DLC 1 and 2 are designed to be cheap. DLC 3 is expensive. Ship DLC 3 only if the base game is done and profitable. |
| **The "two truths" idea isn't fun** | Catastrophic | The vertical slice exists to answer this in 8 weeks. If it isn't fun by week 12, cut the Book layer and pivot to a pure souls-like with the literary *theming*. |
| **Translation slips past QA** | Medium | Pseudo-loc + screenshot sweep in CI. |
| **Font tofu in CJK** | Medium | SystemFont fallbacks + a clean-machine test. |
| **You burn out** | High | Ship the vertical slice to itch as a free demo. Finish something small and public before starting a 3-year project. |
