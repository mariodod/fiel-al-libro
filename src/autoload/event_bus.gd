extends Node
## Global signal hub.
##
## Systems never hold direct references to each other. They announce through
## EventBus. That way the Manuscript UI, the HUD, the audio director and the
## combat system can each be stubbed, replaced or loaded in any order during
## development — which is what keeps a two-year solo project survivable.
##
## See TECH_STACK.md §3.1.


# ── Truth layer (D2: one global layer, two readings) ────────────────────
signal truth_layer_changed(old_layer: int, new_layer: int)
signal truth_blend_started(target_layer: int)
signal truth_blend_finished(layer: int)
signal ink_amount_changed(amount: float)


# ── Madness ─────────────────────────────────────────────────────────────
signal locura_changed(character_id: StringName, value: float, threshold: int)
signal locura_threshold_crossed(character_id: StringName, threshold: int)


# ── Characters (D3: swap, never simultaneous control) ───────────────────
signal character_switched(from_id: StringName, to_id: StringName)
signal character_died(character_id: StringName)
signal character_revived(character_id: StringName)
signal player_spawned(pawn: Node)


# ── Investigation (Lectura) ─────────────────────────────────────────────
signal lectura_entered()
signal lectura_exited()
signal anamorphosis_spotted(id: StringName)
signal anamorphosis_resolved(id: StringName)
signal evidence_collected(id: StringName, total: int)


# ── Examine (B6) ───────────────────────────────────────────────────────
## The thing in front of the player changed. An empty id means "nothing".
signal examine_target_changed(object_id: StringName)
## The player examined a thing. The reader is the character they drive.
signal object_examined(object_id: StringName, reader_id: StringName)


# ── Verdicts (asserting a version of events) ────────────────────────────
signal verdict_offered(id: StringName)
signal verdict_resolved(id: StringName, mode: int)


# ── Progression ─────────────────────────────────────────────────────────
signal recuerdos_gained(character_id: StringName, amount: int)
signal milestone_reached(character_id: StringName, index: int)
signal humanity_changed(value: int)


# ── Library & manuscript ────────────────────────────────────────────────
signal book_collected(id: StringName)
signal shelf_changed(equipped: Array[StringName])
signal manuscript_page_written(id: StringName)
signal codex_page_found(id: StringName)


# ── World flow ──────────────────────────────────────────────────────────
signal chapter_started(id: StringName)
signal chapter_completed(id: StringName)
signal venture_started(id: StringName)
signal venture_resolved(id: StringName, mode: int)
signal region_loaded(id: StringName)
signal posada_entered(id: StringName)


# ── UI & system ─────────────────────────────────────────────────────────
signal toast(text_key: StringName, args: Array)
## A character said something. The speaker is part of the line: the
## disagreement has to be told, not read.
signal character_spoke(character_id: StringName, text_key: StringName, args: Array)
signal game_saved(slot: int)
signal game_loaded(slot: int)
signal ending_reached(id: StringName)
signal settings_changed()
