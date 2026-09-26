class_name FloorRewardScreen
extends CanvasLayer
## Pflichtauswahl nach dem Räumen eines nicht finalen Floors (M3A): 1 aus 3 Run-Upgrades.
## Pausiert das Gameplay; kein Überspringen, kein Reroll. Touch, Maus, Tastatur und Controller-Fokus.

signal chosen(id: StringName)

const FOCUS_COLOR := Color(1.0, 0.8, 0.35, 1.0)

var choices: Array[StringName] = []
var _cards: HBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 17
	visible = false
	_build()


func is_open() -> bool:
	return visible


func open(options: Array[StringName]) -> void:
	choices = options.duplicate()
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	for id in choices:
		var card := Button.new()
		card.text = "%s\n\n%s" % [RunState.upgrade_name(id).to_upper(), RunState.upgrade_description(id)]
		card.custom_minimum_size = Vector2(290, 170)
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_theme_font_size_override("font_size", 20)
		var focus := StyleBoxFlat.new()
		focus.draw_center = false
		focus.border_color = FOCUS_COLOR
		focus.set_border_width_all(4)
		focus.set_corner_radius_all(8)
		card.add_theme_stylebox_override("focus", focus)
		card.pressed.connect(choose.bind(id))
		_cards.add_child(card)
	InputRouter.release_all()
	get_tree().paused = true
	visible = true
	if _cards.get_child_count() > 0:
		(_cards.get_child(0) as Button).grab_focus()


## Auswahl übernehmen (einmalig), danach Spiel fortsetzen.
func choose(id: StringName) -> void:
	if not visible or not choices.has(id):
		return
	visible = false
	chosen.emit(id)
	get_tree().paused = false
	InputRouter.release_all()


func card(index: int) -> Button:
	return _cards.get_child(index) as Button


func dismiss() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	# Kein Überspringen: Pause/Zurück/Stats werden während der Auswahl verschluckt.
	if visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("stats")):
		get_viewport().set_input_as_handled()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.96)
	style.border_color = Color(1.0, 0.72, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	var title := Label.new()
	title.text = "EBENE GERÄUMT"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Wähle ein Upgrade für diesen Run – danach öffnet sich die Luke"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.modulate = Color(1, 1, 1, 0.8)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 16)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards)
