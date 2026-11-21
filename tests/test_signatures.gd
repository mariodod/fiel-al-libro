extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## GDD §5.1/§5.2: each character has three signature verbs with distinct
## costs, gating and effects. They must be data, not hardcode.

func suite(t):
	t.suite("SignatureAbilities")

	var quixote: CharacterData = load("res://src/data/characters/quixote.tres")
	var sancho: CharacterData = load("res://src/data/characters/sancho.tres")
	t.expect_true(quixote != null and sancho != null, "both characters load")
	if quixote == null or sancho == null:
		return

	t.test("each character owns three signature verbs")
	t.expect_eq(quixote.abilities.size(), 3, "Quixote has three")
	t.expect_eq(sancho.abilities.size(), 4, "Sancho has Desvelar plus three")
	var qids: Array[StringName] = []
	for a in quixote.abilities:
		qids.append(a.id)
	var sids: Array[StringName] = []
	for a in sancho.abilities:
		sids.append(a.id)
	for id in [&"golpe_lanza", &"carga_knight", &"fase_gigante"]:
		t.expect_has(qids, id, "Quixote has %s" % id)
	for id in [&"golpe_saco", &"refutar", &"panuelo", &"desvelar"]:
		t.expect_has(sids, id, "Sancho has %s" % id)

	t.test("the verbs carry the GDD's shapes and gating")
	var lanza: AbilityData = load("res://src/data/abilities/golpe_lanza.tres")
	t.expect_gt(lanza.poise_damage, lanza.damage, "lance strike is poise-first")
	t.expect_gt(lanza.arc_degrees, 90.0, "wide arc")
	var saco: AbilityData = load("res://src/data/abilities/golpe_saco.tres")
	t.expect_gt(saco.poise_damage, saco.damage * 3.0, "sack blow is poise, not damage")
	var gigante: AbilityData = load("res://src/data/abilities/fase_gigante.tres")
	t.expect_eq(gigante.truth_layer, 1, "giant phase is Book-only")
	t.expect_eq(gigante.min_locura, 50, "giant phase needs high Locura")
	var refutar: AbilityData = load("res://src/data/abilities/refutar.tres")
	t.expect_gt(float(refutar.duration), 0.0, "refute lasts a few seconds")

	t.test("signature text resolves in six locales")
	var original := TranslationServer.get_locale()
	for locale in ["es", "en", "fr", "de", "it", "pt_BR"]:
		TranslationServer.set_locale(locale)
		t.expect_ne(Loc.t(&"it.ability.golpe_lanza.name"), "it.ability.golpe_lanza.name",
			"name in %s" % locale)
	TranslationServer.set_locale(original)
