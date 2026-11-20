extends Control
## The Manuscript UI shell — the book metaphor that wraps every screen.
##
## "Your playthrough is a manuscript. The save file is named after that
## fiction. Each chapter is a written page. The ending is a page you can
## read."
##
## Everything is the same book, in-world:
##   - Title page — the cover, shown before the first chapter
##   - Shelf (Biblioteca) — your collected books, up to five equipped
##   - Codex (Manifiesto) — the 48 fragments you've found
##   - Dialogue — barks, reactions, the page-turn lines
##   - Pause — resume, quit, settings
##   - Game — the 3D world, seen "through" the manuscript
##
## Pages turn with a slide animation. Only one page is visible at a time
## (except Game, which is always behind). The shell sits above the game's
## CanvasLayers so it can cover the whole screen when open.
##
## Opens/closes with the Shelf key (I), the Manifiesto key (2), and Pause (P).
## ESC goes back one page (or closes to game).

const TestHarness = preload("res://tests/test_harness.gd")

## How long a page turn takes, in seconds.
const PAGE_TURN_SECONDS := 0.3

## The page ids.
const PAGE_GAME := &"game"
const PAGE_TITLE := &"title"
const PAGE_SHELF := &"shelf"
const PAGE_CODEX := &"codex"
const PAGE_DIALOGUE := &"dialogue"
const PAGE_PAUSE := &"pause"
const PAGE_SETTINGS := &"settings"

## The order pages appear in the shell's history (for back navigation).
var _history: Array[StringName] = [PAGE_GAME]

## The currently visible page.
var _current_page: StringName = PAGE_GAME

## Whether a page turn animation is in progress.
var _turning: bool = false

## Child page containers, found lazily.
var _title_page: Control = null
var _title_continue: Button = null
var _shelf_page: Control = null
var _codex_page: Control = null
var _dialogue_page: Control = null
var _pause_page: Control = null
var _settings_page: Control = null

## The page container that holds all page children.
var _pages_container: Control = null

## Called when the shell node enters the tree.
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Find the pages container (a child named "Pages").
	_pages_container = get_node_or_null("Pages")
	if _pages_container == null:
		push_warning("[ManuscriptUI] No 'Pages' child found; shell will not work.")
		return

	# Find each page child lazily.
	_title_page = _find_child(&"TitlePage")
	_shelf_page = _find_child(&"ShelfPage")
	_codex_page = _find_child(&"CodexPage")
	_dialogue_page = _find_child(&"DialoguePage")
	_pause_page = _find_child(&"PausePage")
	_settings_page = _find_child(&"SettingsPage")

	# The title page's Begin button starts the real chapter flow; without this
	# it is a dead button and the built chapters are unreachable.
	var start := _find_child(&"TitleStart") as Button
	if start != null:
		start.text = "%s (Enter)" % Loc.t(&"ui.menu.new_game")
		if not start.pressed.is_connected(_on_begin_pressed):
			start.pressed.connect(_on_begin_pressed)

	# Continue is the counterpart: it restores the autosave and re-enters the
	# chapter the player was in. It is hidden when no save exists yet.
	_title_continue = _find_child(&"TitleContinue") as Button
	if _title_continue != null:
		_title_continue.text = Loc.t(&"ui.menu.continue")
		if not _title_continue.pressed.is_connected(_on_continue_pressed):
			_title_continue.pressed.connect(_on_continue_pressed)
		_refresh_title_buttons()

	# Settings can be reached from the title and from the pause page. The page
	# itself emits back_pressed so it does not need to know about the shell.
	for button_name in [&"TitleSettings", &"PauseSettings"]:
		var settings_button := _find_child(button_name) as Button
		if settings_button != null:
			settings_button.text = Loc.t(&"ui.menu.settings")
			if not settings_button.pressed.is_connected(_on_settings_pressed):
				settings_button.pressed.connect(_on_settings_pressed)
	if _settings_page != null and _settings_page.has_signal(&"back_pressed") \
			and not _settings_page.back_pressed.is_connected(go_back):
		_settings_page.back_pressed.connect(go_back)
	if not EventBus.settings_changed.is_connected(_refresh_locale_texts):
		EventBus.settings_changed.connect(_refresh_locale_texts)

	# Hide all pages initially.
	_hide_all_pages()


func _on_begin_pressed() -> void:
	visible = false
	ChapterFlow.start_new_game()


func _on_continue_pressed() -> void:
	if not Manuscrito.has_save(Manuscrito.AUTOSAVE_SLOT):
		return
	visible = false
	ChapterFlow.continue_game()


## Show Continue only when there is something to continue. Called whenever the
## title opens, so a save written since the last visit is picked up.
func _refresh_title_buttons() -> void:
	if _title_continue == null:
		return
	var has_save := Manuscrito.has_save(Manuscrito.AUTOSAVE_SLOT)
	_title_continue.visible = has_save
	_title_continue.disabled = not has_save


func _on_settings_pressed() -> void:
	open_settings()


## Button captions are translated once in _ready; refresh them when the player
## changes language on the settings page.
func _refresh_locale_texts() -> void:
	if _title_continue != null:
		_title_continue.text = Loc.t(&"ui.menu.continue")
	var start := _find_child(&"TitleStart") as Button
	if start != null:
		start.text = "%s (Enter)" % Loc.t(&"ui.menu.new_game")
	for button_name in [&"TitleSettings", &"PauseSettings"]:
		var settings_button := _find_child(button_name) as Button
		if settings_button != null:
			settings_button.text = Loc.t(&"ui.menu.settings")


## Recursively find a descendant node by name.
func _find_child(name: StringName, from: Node = null) -> Node:
	var search_from: Node = from if from != null else self
	for i in range(search_from.get_child_count()):
		var child = search_from.get_child(i)
		if child.name == name:
			return child
		var found = _find_child(name, child)
		if found != null:
			return found
	return null


## Hide every page (including the game background).
func _hide_all_pages() -> void:
	if _pages_container == null:
		return
	for child in _pages_container.get_children():
		if child is Control:
			child.visible = false


## Show a specific page, hiding all others. Animates the turn.
func _show_page(page: StringName) -> void:
	if _turning:
		return
	if _current_page == page:
		return
	_turning = true

	var previous := _current_page
	_current_page = page

	# Hide everything first.
	_hide_all_pages()

	# Show the new page.
	var page_node = _page_node(page)
	if page_node != null:
		page_node.visible = true

	# Record history (don't duplicate consecutive same page).
	if _history.size() > 0 and _history[_history.size() - 1] != page:
		_history.append(page)

	# Animate: simple fade-in for now (page-turn slide is Phase 2 art).
	var tween := get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, PAGE_TURN_SECONDS)
	tween.tween_callback(func():
		_turning = false
	)


## Get the Control node for a page id.
func _page_node(page: StringName) -> Control:
	match page:
		PAGE_GAME: return null  # Game is the background, not a child
		PAGE_TITLE: return _title_page
		PAGE_SHELF: return _shelf_page
		PAGE_CODEX: return _codex_page
		PAGE_DIALOGUE: return _dialogue_page
		PAGE_PAUSE: return _pause_page
		PAGE_SETTINGS: return _settings_page
		_: return null


## Go back to the previous page in history.
func go_back() -> void:
	if _turning:
		return
	if _history.size() <= 1:
		# Already at the game page; close the shell entirely.
		close()
		return
	_history.pop_back()
	var previous := _history[_history.size() - 1]
	_show_page(previous)


## Close the shell and return to the game.
func close() -> void:
	_turning = false
	_history = [PAGE_GAME]
	_current_page = PAGE_GAME
	_hide_all_pages()
	visible = false


## Open the shelf page.
func open_shelf() -> void:
	if _turning:
		return
	if _current_page == PAGE_SHELF:
		close()
		return
	visible = true
	_show_page(PAGE_SHELF)


## Open the codex page.
func open_codex() -> void:
	if _turning:
		return
	if _current_page == PAGE_CODEX:
		close()
		return
	visible = true
	_show_page(PAGE_CODEX)


## Open the pause page.
func open_pause() -> void:
	if _turning:
		return
	if _current_page == PAGE_PAUSE:
		close()
		return
	visible = true
	_show_page(PAGE_PAUSE)


## Open the settings page.
func open_settings() -> void:
	if _turning:
		return
	if _current_page == PAGE_SETTINGS:
		close()
		return
	visible = true
	_show_page(PAGE_SETTINGS)


## Open the title page.
func open_title() -> void:
	if _turning:
		return
	_refresh_title_buttons()
	visible = true
	_show_page(PAGE_TITLE)


## ── Input ──────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	# Enter/Space on the title page resumes a saved campaign when there is one;
	# otherwise it begins a new campaign. This keeps the keyboard equivalent of
	# whichever button is actually on offer.
	if _current_page == PAGE_TITLE and event.is_action_pressed(&"ui_accept"):
		if Manuscrito.has_save(Manuscrito.AUTOSAVE_SLOT):
			_on_continue_pressed()
		else:
			_on_begin_pressed()
		get_viewport().set_input_as_handled()
		return

	# ESC always goes back or closes.
	if event.is_action_pressed(&"ui_cancel"):
		go_back()
		get_viewport().set_input_as_handled()
		return

	# Shelf key (I) toggles the shelf page.
	if event.is_action_pressed(&"shelf"):
		if _current_page == PAGE_SHELF:
			close()
		else:
			open_shelf()
		get_viewport().set_input_as_handled()
		return

	# Manifiesto key (2) toggles the codex page.
	if event.is_action_pressed(&"manifiesto"):
		if _current_page == PAGE_CODEX:
			close()
		else:
			open_codex()
		get_viewport().set_input_as_handled()
		return

	# Pause key (P) toggles the pause page.
	if event.is_action_pressed(&"pause"):
		if _current_page == PAGE_PAUSE:
			close()
		else:
			open_pause()
		get_viewport().set_input_as_handled()
		return


## ── Test hook ──────────────────────────────────────────────────────────

## For unit tests: run the suite against this script.
static func suite(harness: TestHarness) -> void:
	harness.suite("ManuscriptUI")

	# The shell starts on the game page (hidden).
	harness.expect_eq(PAGE_GAME, &"game", "game page id")
	harness.expect_eq(PAGE_SHELF, &"shelf", "shelf page id")
	harness.expect_eq(PAGE_CODEX, &"codex", "codex page id")
	harness.expect_eq(PAGE_PAUSE, &"pause", "pause page id")
	harness.expect_eq(PAGE_SETTINGS, &"settings", "settings page id")

	harness.expect_eq(PAGE_TURN_SECONDS, 0.3, "page turn duration")
