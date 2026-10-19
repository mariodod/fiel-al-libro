extends Node
## Audio director.
##
## The credits song's melody is the spine of the whole soundtrack; every
## region is a variation of it. The Posada always has the skeleton.
##
## GDD.md §14 and §16.

const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const VOICE_BUS := &"Voice"
const UI_BUS := &"UI"

## Region id → music stream key (resolved from assets/audio/music/).
var _region_tracks: Dictionary = {}
var _current_track: String = ""
var _fade_time: float = 1.2


func _ready() -> void:
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	_ensure_bus(VOICE_BUS)
	_ensure_bus(UI_BUS)

	# The Book layer gets a subtle layer: page turns and a scratching quill.
	EventBus.truth_layer_changed.connect(_on_truth_changed)


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, bus_name)
		AudioServer.set_bus_send(AudioServer.get_bus_count() - 1, &"Master")


func register_region_track(region_id: StringName, track_key: String) -> void:
	_region_tracks[region_id] = track_key


func play_region(region_id: StringName) -> void:
	var key := str(_region_tracks.get(region_id, ""))
	if key == "" or key == _current_track:
		return
	_current_track = key
	# TODO(Phase 1): resolve the key against a ResourceLoader path table and
	# cross-fade with a tween. Wired up in the slice.


func play_credits_song() -> void:
	_current_track = "credits"
	# TODO(Phase 1): load assets/audio/music/romance_del_caballero_y_el_escudero.ogg
	# and play it with the "credits" arrangement variant.


func stop_music(fade: bool = true) -> void:
	_current_track = ""


func _on_truth_changed(_old: int, new_layer: int) -> void:
	# The Book layer is drier and thinner; Reality is fuller. Implemented as
	# a bus effect once the audio middleware is in place.
	pass
