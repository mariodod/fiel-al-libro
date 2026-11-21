extends Node
## Player settings live outside the manuscript save: they survive New Game,
## a deleted save, and a reinstall. Stored as human-readable ConfigFile JSON-ish
## text at user://settings.cfg so a player can edit it by hand if they want to.

const CONFIG_PATH := "user://settings.cfg"
const SECTION_AUDIO := "audio"
const SECTION_LOCALE := "locale"

## Master is the built-in bus 0; the others are created by AudioDirector.
const BUSES: Array[StringName] = [&"Master", &"Music", &"SFX", &"Voice", &"UI"]
const DEFAULT_VOLUME := 1.0

var _config := ConfigFile.new()


func _ready() -> void:
	if _config.load(CONFIG_PATH) != OK:
		_config = ConfigFile.new()
	# Loc._ready() has already picked the OS locale; a player's explicit choice
	# wins. AudioDirector._ready() has created the buses we mix into.
	var locale := str(_config.get_value(SECTION_LOCALE, "language", ""))
	if not locale.is_empty() and Loc.SHIPPED_LOCALES.has(locale):
		Loc.set_locale(locale)
	# Imported languages are applied by TranslationManager._restore_imported(),
	# which runs after this autoload is ready.
	for bus in BUSES:
		_apply_volume(bus)


## The language the player chose, or the one currently in use.
func get_language() -> String:
	return str(_config.get_value(SECTION_LOCALE, "language", Loc.current_locale()))


func set_language(locale: String) -> void:
	_config.set_value(SECTION_LOCALE, "language", locale)
	Loc.set_locale(locale)
	save()


## Persist a locale imported through the Codes screen. It is applied through
## Loc by TranslationManager (Settings itself only knows shipped codes).
func set_custom_language(locale: String) -> void:
	_config.set_value(SECTION_LOCALE, "language", locale)
	save()


## Accessibility (GDD §17). These change presentation only, never the story.
const SECTION_A11Y := "accessibility"

func get_bool(setting: StringName, default: bool = false) -> bool:
	return bool(_config.get_value(SECTION_A11Y, str(setting), default))


func set_bool(setting: StringName, value: bool) -> void:
	_config.set_value(SECTION_A11Y, str(setting), value)
	EventBus.settings_changed.emit()
	save()


func reduce_ink() -> bool:
	return get_bool(&"reduce_ink")


func large_subtitles() -> bool:
	return get_bool(&"large_subtitles")


func toggle_sprint() -> bool:
	return get_bool(&"toggle_sprint")


## Volume as a linear 0..1 value, not decibels — that is what a slider wants.
func get_volume(bus: StringName) -> float:
	if not BUSES.has(bus):
		return DEFAULT_VOLUME
	return clampf(float(_config.get_value(SECTION_AUDIO, str(bus), DEFAULT_VOLUME)), 0.0, 1.0)


func set_volume(bus: StringName, value: float) -> void:
	if not BUSES.has(bus):
		return
	_config.set_value(SECTION_AUDIO, str(bus), clampf(value, 0.0, 1.0))
	_apply_volume(bus)
	EventBus.settings_changed.emit()
	save()


func save() -> void:
	_config.save(CONFIG_PATH)


func _apply_volume(bus: StringName) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index == -1:
		return
	# linear_to_db(0) is -infinity; -80 dB is effectively silence and safe.
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(get_volume(bus), 0.0001)))
