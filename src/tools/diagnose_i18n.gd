extends SceneTree
## Why do contextual and plural keys not resolve through tr()?

func _init() -> void:
	TranslationServer.set_locale("en")

	print("=== tr() on plain keys ===")
	print("  tr('ui.menu.new_game')      = '%s'" % tr(&"ui.menu.new_game"))
	print("  tr('ui.shelf.count')        = '%s'" % tr(&"ui.shelf.count"))
	print("  tr('ui.shelf.counts')       = '%s'" % tr(&"ui.shelf.counts"))
	print("  tr('ui.shelf.count.plural') = '%s'" % tr(&"ui.shelf.count.plural"))

	print("")
	print("=== tr() on the composed context key ===")
	var composed := "ui.book%sui.word.page" % char(4)
	print("  composed (len %d) = '%s'" % [composed.length(), composed])
	print("  tr(composed)      = '%s'" % tr(StringName(composed)))

	print("")
	print("=== what the DIRECT .po load contains ===")
	var res: Resource = ResourceLoader.load("res://locale/en.po", "Translation", ResourceLoader.CACHE_MODE_IGNORE)
	var t := res as Translation
	for key: String in t.get_message_list():
		if key.contains("shelf.count") or key.contains("word.page"):
			print("  '%s' -> '%s'" % [key, t.get_message(key)])

	print("")
	print("=== what the TranslationServer's REGISTERED en translation contains ===")
	var registered := TranslationServer.get_translation_object("en")
	if registered == null:
		print("  NO REGISTERED TRANSLATION for 'en'!")
		print("  (the locale list in project.godot may not have loaded)")
	else:
		var rt := registered as Translation
		for key: String in rt.get_message_list():
			if key.contains("shelf.count") or key.contains("word.page"):
				print("  '%s' -> '%s'" % [key, rt.get_message(key)])
	quit(0)
