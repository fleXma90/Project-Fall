extends Node
## Zentraler Input-Router (Autoload "InputRouter").
##
## Übersetzt Rohinputs von Tastatur/Maus, Controller und Touch in semantische Absichten:
## move_input, Facing-Quelle, attack_held / Attack-Press, Dodge-Press.
## Bildschirmvektoren: x = rechts, y = oben (auf dem Bildschirm), Länge 0..1.
## Nur die aktive Quelle liefert Werte; ein echter Quellenwechsel löst alle Held-States.

signal source_changed(source: Source)
signal active_gamepad_disconnected

enum Source { KEYBOARD_MOUSE, GAMEPAD, TOUCH }
enum TouchZone { NONE, STICK, ATTACK, DODGE }

const STICK_DEADZONE: float = 0.18
const TRIGGER_ON: float = 0.35
const TRIGGER_OFF: float = 0.20
const INPUT_BUFFER: float = 0.10
## Relative Mausbewegung in Pixeln, ab der die Maus die aktive Quelle übernimmt.
const MOUSE_TAKEOVER_PIXELS: float = 3.0
## Stickauslenkung, ab der ein Controller die aktive Quelle übernimmt (Rauschen ignorieren).
const STICK_TAKEOVER: float = 0.5
const NO_PRESS: float = -1000.0

var active_source: Source = Source.KEYBOARD_MOUSE
## Desktop-Testhilfe: Touchcontrols sichtbar, Maus erzeugt Touch statt Maus-Gameplay.
var touch_test_mode: bool = false

## Semantische Werte, einmal pro Physiktick aktualisiert.
var move_input: Vector2 = Vector2.ZERO
var attack_held: bool = false
## Letzte echte Mausposition in Viewport-Koordinaten.
var mouse_position: Vector2 = Vector2.ZERO
## Wird erst durch echte Mausbewegung im Tastatur/Maus-Betrieb gültig.
var mouse_aim_valid: bool = false

## Touch-Zustand (für Darstellung lesbar). Stickvektor in Bildschirmkoordinaten (y unten).
var touch_stick_active: bool = false
var touch_stick_origin: Vector2 = Vector2.ZERO
var touch_stick_vector: Vector2 = Vector2.ZERO
var touch_attack_held: bool = false
var touch_dodge_held: bool = false

var _clock: float = 0.0
var _attack_press_time: float = NO_PRESS
var _dodge_press_time: float = NO_PRESS

var _lmb_held: bool = false

var _active_joy: int = -1
var _axes_by_device: Dictionary = {}  # Gerät -> {JoyAxis: float}
var _joy_axes: Dictionary = {}  # Achsen des aktiven Controllers (Referenz in _axes_by_device)
var _rt_on: bool = false
var _lt_on: bool = false
var _rt_latched: bool = false
var _lt_latched: bool = false

var _touch_layout: TouchControls = null
var _touch_owner: Dictionary = {}  # Finger-Index -> TouchZone


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = -100
	_register_actions()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


# --- Öffentliche API --------------------------------------------------------

func uses_mouse_facing() -> bool:
	return active_source == Source.KEYBOARD_MOUSE and mouse_aim_valid and not touch_test_mode


func uses_stick_facing() -> bool:
	return active_source == Source.GAMEPAD or active_source == Source.TOUCH


## Liefert true, wenn innerhalb des Inputbuffers ein neuer Attack-Druck vorlag, und verbraucht ihn.
func consume_attack_press() -> bool:
	if _clock - _attack_press_time <= INPUT_BUFFER:
		_attack_press_time = NO_PRESS
		return true
	return false


## Liefert true, wenn innerhalb des Inputbuffers eine neue Dodge-Druckflanke vorlag, und verbraucht sie.
func consume_dodge_press() -> bool:
	if _clock - _dodge_press_time <= INPUT_BUFFER:
		_dodge_press_time = NO_PRESS
		return true
	return false


## Löst alle gehaltenen Zustände und Buffer (Pause, Fokusverlust, Reset, Disconnect, Quellenwechsel).
func release_all() -> void:
	_lmb_held = false
	_rt_latched = _rt_on or float(_joy_axes.get(JOY_AXIS_TRIGGER_RIGHT, 0.0)) > TRIGGER_OFF
	_lt_latched = _lt_on or float(_joy_axes.get(JOY_AXIS_TRIGGER_LEFT, 0.0)) > TRIGGER_OFF
	_rt_on = false
	_lt_on = false
	_release_touch()
	_attack_press_time = NO_PRESS
	_dodge_press_time = NO_PRESS
	attack_held = false
	move_input = Vector2.ZERO


func set_touch_test_mode(enabled: bool) -> void:
	touch_test_mode = enabled
	Input.emulate_touch_from_mouse = enabled
	release_all()
	if enabled:
		_switch_source(Source.TOUCH)


func touch_controls_wanted() -> bool:
	return OS.has_feature("mobile") or touch_test_mode or active_source == Source.TOUCH


func register_touch_layout(layout: TouchControls) -> void:
	_touch_layout = layout


func unregister_touch_layout(layout: TouchControls) -> void:
	if _touch_layout == layout:
		_touch_layout = null
		_release_touch()


func source_name() -> String:
	match active_source:
		Source.KEYBOARD_MOUSE:
			return "Tastatur/Maus"
		Source.GAMEPAD:
			return "Controller #%d" % _active_joy
		Source.TOUCH:
			return "Touch (Test)" if touch_test_mode else "Touch"
	return "?"


# --- Takt --------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_clock += delta
	match active_source:
		Source.KEYBOARD_MOUSE:
			move_input = Input.get_vector("move_left", "move_right", "move_down", "move_up")
			attack_held = _lmb_held
		Source.GAMEPAD:
			var raw := Vector2(float(_joy_axes.get(JOY_AXIS_LEFT_X, 0.0)), -float(_joy_axes.get(JOY_AXIS_LEFT_Y, 0.0)))
			move_input = apply_radial_deadzone(raw, STICK_DEADZONE)
			attack_held = _rt_on
		Source.TOUCH:
			var t := Vector2(touch_stick_vector.x, -touch_stick_vector.y)
			move_input = apply_radial_deadzone(t, STICK_DEADZONE)
			attack_held = touch_attack_held


static func apply_radial_deadzone(raw: Vector2, deadzone: float) -> Vector2:
	var length := raw.length()
	if length <= deadzone:
		return Vector2.ZERO
	var scaled := minf((length - deadzone) / (1.0 - deadzone), 1.0)
	return raw / length * scaled


# --- Rohinput ----------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if motion.device == InputEvent.DEVICE_ID_EMULATION or touch_test_mode:
			return
		mouse_position = motion.position
		if motion.relative.length() >= MOUSE_TAKEOVER_PIXELS:
			_switch_source(Source.KEYBOARD_MOUSE)
		if active_source == Source.KEYBOARD_MOUSE:
			mouse_aim_valid = true
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.device == InputEvent.DEVICE_ID_EMULATION or touch_test_mode:
			return
		mouse_position = button.position
		if button.pressed:
			_switch_source(Source.KEYBOARD_MOUSE)
			mouse_aim_valid = true
		elif button.button_index == MOUSE_BUTTON_LEFT:
			# Loslassen immer auswerten, auch wenn die UI das Event später konsumiert.
			_lmb_held = false
	elif event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			_switch_source(Source.KEYBOARD_MOUSE)
	elif event is InputEventJoypadButton:
		var joy_button := event as InputEventJoypadButton
		if joy_button.pressed:
			_switch_source(Source.GAMEPAD, joy_button.device)
	elif event is InputEventJoypadMotion:
		_handle_joy_motion(event as InputEventJoypadMotion)


## Gameplay-Drücke laufen über _unhandled_input, damit UI-Klicks keinen Weltangriff auslösen.
func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or touch_test_mode:
		return
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.device == InputEvent.DEVICE_ID_EMULATION or not button.pressed:
			return
		if button.button_index == MOUSE_BUTTON_LEFT:
			_lmb_held = true
			_attack_press_time = _clock
		elif button.button_index == MOUSE_BUTTON_RIGHT:
			_dodge_press_time = _clock
	elif event is InputEventKey:
		if event.is_action_pressed("dodge", false):
			_dodge_press_time = _clock


func _handle_joy_motion(event: InputEventJoypadMotion) -> void:
	var axis := event.axis
	var value := event.axis_value
	var device_axes: Dictionary = _axes_by_device.get_or_add(event.device, {})
	device_axes[axis] = value
	if active_source != Source.GAMEPAD or event.device != _active_joy:
		# Übernahme nur bei deutlicher Absicht: Stickauslenkung (radial) oder Trigger über AN-Schwelle.
		var stick := Vector2(float(device_axes.get(JOY_AXIS_LEFT_X, 0.0)), float(device_axes.get(JOY_AXIS_LEFT_Y, 0.0)))
		var significant := stick.length() >= STICK_TAKEOVER \
				or float(device_axes.get(JOY_AXIS_TRIGGER_RIGHT, 0.0)) >= TRIGGER_ON \
				or float(device_axes.get(JOY_AXIS_TRIGGER_LEFT, 0.0)) >= TRIGGER_ON
		if not significant:
			return
		_switch_source(Source.GAMEPAD, event.device)
	var accept_press := not get_tree().paused
	if axis == JOY_AXIS_TRIGGER_RIGHT:
		if _rt_latched:
			_rt_latched = value > TRIGGER_OFF
		elif not _rt_on and value >= TRIGGER_ON:
			_rt_on = accept_press
			if accept_press:
				_attack_press_time = _clock
		elif _rt_on and value <= TRIGGER_OFF:
			_rt_on = false
	elif axis == JOY_AXIS_TRIGGER_LEFT:
		if _lt_latched:
			_lt_latched = value > TRIGGER_OFF
		elif not _lt_on and value >= TRIGGER_ON:
			_lt_on = true
			if accept_press:
				_dodge_press_time = _clock
		elif _lt_on and value <= TRIGGER_OFF:
			_lt_on = false


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if get_tree().paused or _touch_owner.has(event.index):
			return
		_switch_source(Source.TOUCH)
		var zone: int = _touch_layout.zone_at(event.position) if _touch_layout != null else TouchZone.NONE
		if zone == TouchZone.NONE or _touch_owner.values().has(zone):
			return  # Kein Finger stiehlt eine bereits belegte Control.
		_touch_owner[event.index] = zone
		match zone:
			TouchZone.STICK:
				touch_stick_active = true
				touch_stick_origin = event.position
				touch_stick_vector = Vector2.ZERO
			TouchZone.ATTACK:
				touch_attack_held = true
				_attack_press_time = _clock
			TouchZone.DODGE:
				touch_dodge_held = true
				_dodge_press_time = _clock
	else:
		_release_finger(event.index)


func _handle_drag(event: InputEventScreenDrag) -> void:
	if int(_touch_owner.get(event.index, TouchZone.NONE)) != TouchZone.STICK:
		return
	var radius := _touch_layout.stick_radius if _touch_layout != null else 90.0
	var offset := event.position - touch_stick_origin
	if offset.length() > radius:
		# Dynamischer Stick: Ursprung folgt dem Finger, wenn er über den Radius hinauszieht.
		touch_stick_origin = event.position - offset.normalized() * radius
		offset = event.position - touch_stick_origin
	touch_stick_vector = offset / radius


func _release_finger(index: int) -> void:
	var zone: int = _touch_owner.get(index, TouchZone.NONE)
	_touch_owner.erase(index)
	match zone:
		TouchZone.STICK:
			touch_stick_active = false
			touch_stick_vector = Vector2.ZERO
		TouchZone.ATTACK:
			touch_attack_held = false
		TouchZone.DODGE:
			touch_dodge_held = false


func _release_touch() -> void:
	_touch_owner.clear()
	touch_stick_active = false
	touch_stick_vector = Vector2.ZERO
	touch_attack_held = false
	touch_dodge_held = false


func _switch_source(source: Source, joy_device: int = -1) -> void:
	var joy_changed := source == Source.GAMEPAD and joy_device != _active_joy
	if source == active_source and not joy_changed:
		return
	# Echter Wechsel: alte Held-States und Buffer lösen. Facing bleibt beim Player erhalten.
	release_all()
	_rt_latched = false
	_lt_latched = false
	if joy_changed:
		_active_joy = joy_device
		_joy_axes = _axes_by_device.get_or_add(joy_device, {})
	if source != Source.KEYBOARD_MOUSE:
		mouse_aim_valid = false
	active_source = source
	source_changed.emit(source)


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if device != _active_joy:
		return
	if connected:
		# Reconnect übernimmt keine gehaltenen Altinputs.
		_joy_axes.clear()
		_rt_latched = Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) > TRIGGER_OFF
		_lt_latched = Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT) > TRIGGER_OFF
	else:
		var was_active := active_source == Source.GAMEPAD
		release_all()
		_joy_axes.clear()
		_rt_latched = false
		_lt_latched = false
		if was_active:
			active_gamepad_disconnected.emit()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			release_all()


# --- Aktionen ----------------------------------------------------------------

func _register_actions() -> void:
	_add_action("move_up", [_key(KEY_W), _key(KEY_UP)])
	_add_action("move_down", [_key(KEY_S), _key(KEY_DOWN)])
	_add_action("move_left", [_key(KEY_A), _key(KEY_LEFT)])
	_add_action("move_right", [_key(KEY_D), _key(KEY_RIGHT)])
	_add_action("attack", [_mouse(MOUSE_BUTTON_LEFT)])
	_add_action("dodge", [_key(KEY_SPACE), _mouse(MOUSE_BUTTON_RIGHT)])
	_add_action("pause", [_key(KEY_ESCAPE), _joy_button(JOY_BUTTON_START)])
	_add_action("debug_reset", [_key(KEY_R)])
	_add_action("debug_toggle_overlay", [_key(KEY_F3)])
	_add_action("debug_toggle_touch", [_key(KEY_F2)])


func _add_action(action: StringName, events: Array[InputEvent]) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for e in events:
		InputMap.action_add_event(action, e)


func _key(physical: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = physical
	return e


func _mouse(index: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = index
	return e


func _joy_button(index: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = index
	e.device = -1
	return e
