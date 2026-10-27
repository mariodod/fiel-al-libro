extends Node
## La Biblioteca — the shelf.
##
## Your loadout IS your collection. You carry FIVE books; equipped books
## grant a passive; everything else lives on a shelf in the Posada, in the
## order you found it. This replaces a gear and inventory system entirely
## (a huge solo-dev saving) and makes the collectible-books feature
## mechanically central instead of a museum.
##
## See GDD.md §8.2 and §9.

const BookData = preload("res://src/data/book_data.gd")

const SHELF_SIZE := 5

## Every book the player has found, in discovery order.
var collected: Array[StringName] = []
## The five currently equipped book ids.
var equipped: Array[StringName] = []
## Book id → the BookData resource (loaded lazily from assets/data).
var _registry: Dictionary = {}


func _ready() -> void:
	var dir = DirAccess.open("res://src/data/books/")
	if dir == null:
		push_warning("[Biblioteca] Could not open res://src/data/books/")
		return
	for file_name in dir.get_files():
		if file_name.ends_with(".tres"):
			var res = load("res://src/data/books/" + file_name)
			if res is BookData:
				register(res)


func register(book: Resource) -> void:
	if book == null:
		return
	var id: StringName = book.get("id")
	if id == null or id == &"":
		push_warning("[Biblioteca] Book resource has no id; ignoring.")
		return
	_registry[id] = book


func get_book(id: StringName) -> Resource:
	return _registry.get(id, null)


func has_book(id: StringName) -> bool:
	return collected.has(id)


## Collect a book. Returns false if it was already collected.
func collect(id: StringName) -> bool:
	if has_book(id):
		return false
	collected.append(id)
	EventBus.book_collected.emit(id)
	# Auto-equip if there is room, so the player always feels the reward.
	if equipped.size() < SHELF_SIZE:
		equipped.append(id)
		EventBus.shelf_changed.emit(equipped)
	return true


## Equip a book, swapping out the oldest if the shelf is full.
func equip(id: StringName) -> void:
	if not has_book(id):
		return
	if equipped.has(id):
		return
	if equipped.size() >= SHELF_SIZE:
		equipped.pop_front()
	equipped.append(id)
	EventBus.shelf_changed.emit(equipped)


func unequip(id: StringName) -> void:
	if equipped.has(id):
		equipped.erase(id)
		EventBus.shelf_changed.emit(equipped)


## The passive abilities granted by the equipped shelf.
func active_passives() -> Array[String]:
	var out: Array[String] = []
	for id: StringName in equipped:
		var book := get_book(id)
		if book == null:
			continue
		var passive: String = str(book.get("passive_id"))
		if passive != "" and not out.has(passive):
			out.append(passive)
	return out


func collected_count() -> int:
	return collected.size()


func total_available() -> int:
	return _registry.size()


func get_collected() -> Array[StringName]:
	return collected.duplicate()


func equipped_books() -> Array[StringName]:
	return equipped.duplicate()


func book_name(id: StringName) -> String:
	var book: Resource = _registry.get(id)
	if book != null:
		var key := str(book.get("display_name_key"))
		if key != "":
			return key
	return String(id)


func passive_name(id: StringName) -> String:
	var book: Resource = _registry.get(id)
	if book != null:
		var key := str(book.get("passive_name_key"))
		if key != "":
			return key
	return ""


# ── Save / load ─────────────────────────────────────────────────────────

func save_state() -> Dictionary:
	# duplicate() matters: returning the live arrays would let a later
	# clear() mutate the "saved" state too.
	return {
		"collected": collected.duplicate(),
		"equipped": equipped.duplicate(),
	}


func load_state(data: Dictionary) -> void:
	collected.clear()
	equipped.clear()
	for id: Variant in data.get("collected", []):
		collected.append(StringName(id))
	for id: Variant in data.get("equipped", []):
		equipped.append(StringName(id))
	EventBus.shelf_changed.emit(equipped)
