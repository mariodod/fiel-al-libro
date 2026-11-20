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

var _current_track: String = ""

## Credits song tracks (GDD.md §14): single player hears the arrangement of
## whichever character they played more.
const CREDITS_BOOK_TRUTH := "res://assets/audio/credits_book_truth.wav"
const CREDITS_REALITY_TRUTH := "res://assets/audio/credits_reality_truth.wav"

## The currently playing credits stream (null when not playing).
var _credits_stream: AudioStreamPlayer = null


func _ready() -> void:
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	_ensure_bus(VOICE_BUS)
	_ensure_bus(UI_BUS)



func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, bus_name)
		AudioServer.set_bus_send(AudioServer.get_bus_count() - 1, &"Master")


func play_credits_song() -> void:
	_current_track = "credits"
	_stop_credits()

	# GDD.md §14: "In single player: the credits song's arrangement depends
	# on which character you played more. You hear your character's verse
	# lead."
	var played_most := GameState.character_played_most()
	var track_path: String = CREDITS_BOOK_TRUTH
	if played_most == &"sancho":
		track_path = CREDITS_REALITY_TRUTH

	var stream := AudioStreamPlayer.new()
	stream.stream = load(track_path)
	stream.bus = MUSIC_BUS
	stream.autoplay = true
	add_child(stream)
	_credits_stream = stream


func stop_music(fade: bool = true) -> void:
	_current_track = ""
	_stop_credits()


## Stop the credits song if it is playing.
func _stop_credits() -> void:
	if _credits_stream != null:
		_credits_stream.stop()
		_credits_stream.queue_free()
		_credits_stream = null
