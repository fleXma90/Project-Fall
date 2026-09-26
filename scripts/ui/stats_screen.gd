class_name StatsScreen
extends CanvasLayer
## Modaler Attribut-Screen (M3A). Der Spieler öffnet ihn selbst (STATS-Button, C, Controller View/Back),
## das Gameplay pausiert. Jeder Plus-Druck investiert genau einen Punkt; kein Respec.
## Schließen: X-Button, C, View/Back, Esc/B. Esc öffnet dabei nicht zusätzlich die Pause.

signal closed

const FOCUS_COLOR := Color(0.3, 0.95, 0.6, 1.0)

var run: RunState = null
var player: PlayerController = null

var _rows: Dictionary = {}  # Attribut -> {"rank": Label, "value": Label, "plus": Button}
var _info: Label
var _close_button: Button
var _last_invest_frame: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 17
	visible = false
	_build()


func is_open() -> bool:
	return visible


func open(run_state: RunState, player_node: PlayerController) -> void:
	if visible or run_state == null:
		return
	run = run_state
	player = player_node
	InputRouter.release_all()
	get_tree().paused = true
	visible = true
	refresh()
	_focus_first()


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	InputRouter.release_all()  # gehaltener RT wird verriegelt: kein unbeabsichtigter Angriff
	closed.emit()


## Ohne Pausenwechsel ausblenden (Neustart der Arena).
func dismiss() -> void:
	visible = false


func invest(attribute: StringName) -> bool:
	if run == null or not visible:
		return false
	# Höchstens ein Punkt pro Frame (kein Mehrfachkauf durch gehaltene Taste/Doppel-Events).
	var frame := Engine.get_process_frames()
	if frame == _last_invest_frame:
		return false
	if not run.invest(attribute):
		return false
	_last_invest_frame = frame
	refresh()
	var plus: Button = _rows[attribute]["plus"]
	if plus.disabled:
		_focus_first()
	return true


func refresh() -> void:
	if run == null:
		return
	_info.text = "LEVEL %d   ·   XP %d / %d   ·   VERFÜGBARE PUNKTE %d" % [run.player_level, run.current_xp,
			RunState.xp_to_next(run.player_level), run.unspent_attribute_points]
	for attribute in RunState.ATTRIBUTES:
		var row: Dictionary = _rows[attribute]
		var r := run.rank(attribute)
		(row["rank"] as Label).text = "%d / %d" % [r, RunState.MAX_RANK]
		(row["value"] as Label).text = value_text(attribute)
		(row["plus"] as Button).disabled = not run.can_invest(attribute)


## Aktueller tatsächlicher Wert und Vorschau des nächsten Rangs (aus Basisdaten + Run berechnet).
func value_text(attribute: StringName) -> String:
	if run == null or player == null:
		return ""
	var r := run.rank(attribute)
	var at_max := r >= RunState.MAX_RANK
	var now := _value_at(attribute, r)
	var next := _value_at(attribute, mini(r + 1, RunState.MAX_RANK))
	var fmt := "%.1f"
	var unit := ""
	match attribute:
		RunState.POWER:
			unit = "Schaden"
		RunState.VITALITY:
			fmt = "%.0f"
			unit = "Max HP"
		RunState.HASTE:
			fmt = "%.2f s"
			unit = "Zyklus"
		RunState.AGILITY:
			fmt = "%.2f"
			unit = "m/s"
		RunState.IMPACT:
			fmt = "%.2f"
			unit = "m/s Knockback"
		RunState.RECOVERY:
			fmt = "%.2f s"
			unit = "Dodge-Abklingzeit"
	if at_max:
		return (fmt % now) + " " + unit + "  (max)"
	return (fmt % now) + " → " + (fmt % next) + " " + unit


func _value_at(attribute: StringName, r: int) -> float:
	var data := player.weapon.data
	var tuning := player.tuning
	match attribute:
		RunState.POWER:
			return data.damage * run.damage_multiplier(r)
		RunState.VITALITY:
			return tuning.max_hp + run.max_hp_bonus(r)
		RunState.HASTE:
			return data.total_duration() / run.attack_speed_multiplier(r)
		RunState.AGILITY:
			return tuning.move_speed * run.move_multiplier(r)
		RunState.IMPACT:
			return data.knockback_speed * run.knockback_multiplier(r)
		RunState.RECOVERY:
			return tuning.dodge_cooldown * run.dodge_cooldown_multiplier(r)
	return 0.0


func plus_button(attribute: StringName) -> Button:
	return _rows[attribute]["plus"]


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("stats") or event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _focus_first() -> void:
	for attribute in RunState.ATTRIBUTES:
		var plus: Button = _rows[attribute]["plus"]
		if not plus.disabled:
			plus.grab_focus()
			return
	_close_button.grab_focus()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = "ATTRIBUTE"
	title.add_theme_font_size_override("font_size", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var x_button := _button("X", Vector2(56, 56), 24)
	x_button.pressed.connect(close)
	header.add_child(x_button)

	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 18)
	_info.modulate = Color(1, 1, 1, 0.85)
	box.add_child(_info)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	for attribute in RunState.ATTRIBUTES:
		var name_label := _label(RunState.attribute_name(attribute), 20, 180)
		var rank_label := _label("0 / 8", 20, 64)
		var value_label := _label("", 18, 360)
		var plus := _button("+", Vector2(64, 52), 26)
		plus.pressed.connect(invest.bind(attribute))
		for control in [name_label, rank_label, value_label, plus]:
			grid.add_child(control)
		_rows[attribute] = {"rank": rank_label, "value": value_label, "plus": plus}

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	box.add_child(footer)
	var hint := Label.new()
	hint.text = "C · View/Back · Esc/B: schließen   ·   Punkte dürfen gespart werden"
	hint.add_theme_font_size_override("font_size", 14)
	hint.modulate = Color(1, 1, 1, 0.6)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(hint)
	_close_button = _button("Schließen", Vector2(180, 52), 20)
	_close_button.pressed.connect(close)
	footer.add_child(_close_button)


func _label(text: String, font_size: int, min_width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.custom_minimum_size = Vector2(min_width, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _button(text: String, min_size: Vector2, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", font_size)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = FOCUS_COLOR
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(6)
	button.add_theme_stylebox_override("focus", focus)
	return button


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.96)
	style.border_color = Color(0.3, 0.95, 0.6, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style
