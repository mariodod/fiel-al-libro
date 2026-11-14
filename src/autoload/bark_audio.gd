extends Node
## BarkAudio — plays audio for character barks.
##
## Listens to EventBus.character_spoke and plays the corresponding WAV file
## from assets/audio/barks/<character_id>/<slug>.wav.
##
## Bark keys follow the pattern:
##   dia.<character_id>.<category>.<slug_parts>
##   e.g. dia.quixote.chatter.rock  ->  quixote/chatter.rock.wav
##        dia.quixote.bark.001       ->  quixote/bark.001.wav
##        dia.quixote.reaction.windmill.book -> quixote/reaction.windmill.book.wav
##
## Register as an autoload named "BarkAudio" in project.godot.
##
## Missing WAV files are silently skipped — add them as they are recorded.

signal bark_played(character_id: StringName, text_key: StringName)

var _bark_sounds: Dictionary = {}  # cache of loaded audio streams

func _ready() -> void:
	EventBus.character_spoke.connect(_on_character_spoke)

func _on_character_spoke(character_id: StringName, text_key: StringName, args: Array) -> void:
	var slug := _key_to_slug(text_key)
	if slug.is_empty():
		return
	var path := "res://assets/audio/barks/%s/%s.wav" % [character_id, slug]
	var stream := _get_stream(path)
	if stream == null:
		return  # No audio file yet — that's OK, placeholder
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	bark_played.emit(character_id, text_key)

## Convert a bark key like "dia.quixote.chatter.rock" to a slug "chatter.rock".
func _key_to_slug(text_key: StringName) -> String:
	var parts := str(text_key).split(".")
	if parts.size() < 3:
		return ""
	# parts[0] = "dia", parts[1] = character_id, rest = slug parts
	var suffix := parts.slice(2, parts.size() - 2)
	return "_".join(suffix)

## Load and cache a stream by path.
##
## Missing files are cached as null so load() is only called once — this
## avoids Godot logging "Resource file not found" every frame.
func _get_stream(path: String) -> AudioStream:
	if _bark_sounds.has(path):
		return _bark_sounds[path]
	var stream := load(path)
	_bark_sounds[path] = stream
	return stream