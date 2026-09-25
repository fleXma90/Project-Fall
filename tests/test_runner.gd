extends Node
## Headless-Verhaltenstests für M1 (Regeln aus docs/PLAYTEST_CHECKLIST.md).
## Start: godot --headless --path . --fixed-fps 60 res://tests/test_runner.tscn
## Eingaben laufen als echte InputEvents durch den InputRouter (Viewport.push_input).

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SWAP_VISUAL: GDScript = preload("res://tests/swap_test_visual.gd")
const DT: float = 1.0 / 60.0

var main: Node
var player: PlayerController
var arena: TrainingArena
var camera: Camera3D
var _current: String = ""
var _failures: PackedStringArray = []
var _checks: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	var tests: PackedStringArray = [
		"test_i1_camera_relative_and_diagonal",
		"test_i2_stick_facing_persists",
		"test_i2_controller_attack_keeps_released_direction",
		"test_i3_held_attack_full_cycle",
		"test_i4_held_dodge_once",
		"test_i5_mouse_ignored_in_controller_mode",
		"test_i6_pause_focus_disconnect_release",
		"test_touch_multitouch_independent",
		"test_mouse_facing_projection",
		"test_desktop_strafe_and_fixed_attack_direction",
		"test_ui_click_does_not_attack",
		"test_c1_one_hit_per_swing",
		"test_c2_sector_limits",
		"test_c3_dodge_cancel_keeps_cadence",
		"test_c4_knockback_time_based",
		"test_f1_open_edge_no_collider",
		"test_f1_no_edge_support",
		"test_f2_player_fall_respawn_once",
		"test_f2_dodge_over_edge_falls",
		"test_f3_dummy_edge_kill_once",
		"test_f3_dummy_hp_kill_once",
		"test_a1_visual_swap",
	]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			tests = PackedStringArray(Array(tests).filter(func(t: String) -> bool: return t.contains(arg.trim_prefix("--only="))))
	for test_name in tests:
		_current = test_name
		var before := _failures.size()
		await _setup()
		await Callable(self, test_name).call()
		await _teardown()
		print("%s  %s" % ["PASS" if _failures.size() == before else "FAIL", test_name])
	print("---")
	print("Checks: %d, Fehler: %d" % [_checks, _failures.size()])
	for f in _failures:
		print("  - " + f)
	get_tree().quit(0 if _failures.is_empty() else 1)


# --- Hilfen ------------------------------------------------------------------

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append("%s: %s" % [_current, message])


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _setup() -> void:
	get_tree().paused = false
	InputRouter.set_touch_test_mode(false)
	InputRouter._switch_source(InputRouter.Source.KEYBOARD_MOUSE)
	InputRouter.release_all()
	InputRouter.mouse_aim_valid = false
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)
	main = MAIN_SCENE.instantiate()
	add_child(main)
	player = main.get("player")
	arena = main.get("arena")
	camera = (main.get("camera_rig") as CameraRig).camera
	await _ticks(4)


func _teardown() -> void:
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	_joy_axis(JOY_AXIS_LEFT_X, 0.0)
	_joy_axis(JOY_AXIS_LEFT_Y, 0.0)
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)
	get_tree().paused = false
	Engine.physics_ticks_per_second = 60
	main.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


## Events sind bereits in Viewport-Koordinaten (wie camera.unproject_position liefert).
func _push(event: InputEvent) -> void:
	get_viewport().push_input(event, true)


func _joy_axis(axis: JoyAxis, value: float, device: int = 0) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = device
	e.axis = axis
	e.axis_value = value
	_push(e)


## Stickauslenkung (Joy-Achsen, y nach unten) für eine gewünschte Welt-XZ-Richtung.
func _stick_for_world(direction: Vector3) -> Vector2:
	var b := camera.global_basis
	var right := Vector3(b.x.x, 0.0, b.x.z).normalized()
	var forward := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
	var screen := Vector2(direction.dot(right), direction.dot(forward))
	return Vector2(screen.x, -screen.y)


func _set_stick(axes: Vector2) -> void:
	_joy_axis(JOY_AXIS_LEFT_X, axes.x)
	_joy_axis(JOY_AXIS_LEFT_Y, axes.y)


func _mouse_move_to(screen: Vector2, relative: Vector2 = Vector2(12, 0)) -> void:
	var e := InputEventMouseMotion.new()
	e.device = 0
	e.position = screen
	e.global_position = screen
	e.relative = relative
	_push(e)


func _mouse_button(index: MouseButton, pressed: bool, screen: Vector2, device: int = 0) -> void:
	var e := InputEventMouseButton.new()
	e.device = device
	e.button_index = index
	e.pressed = pressed
	e.position = screen
	e.global_position = screen
	_push(e)


func _touch(index: int, pressed: bool, pos: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.pressed = pressed
	e.position = pos
	_push(e)


func _drag(index: int, pos: Vector2, relative: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = pos
	e.relative = relative
	_push(e)


## Setzt den Player direkt auf die Plattformoberkante (y = 0), damit er sofort Bodenkontakt hat.
func _place_player(pos: Vector3, facing: Vector3) -> void:
	player.global_position = Vector3(pos.x, 0.0, pos.z)
	player.velocity = Vector3.ZERO
	player.facing_direction = facing.normalized()
	player.rotation.y = PlayerController.yaw_for_direction(player.facing_direction)


## Behält nur einen Dummy (an pos) für isolierte Tests; die anderen werden entfernt.
func _only_dummy(pos: Vector3) -> TrainingDummy:
	var keep: TrainingDummy = arena.dummies[0]
	for i in range(arena.dummies.size() - 1, 0, -1):
		var d: TrainingDummy = arena.dummies[i]
		arena.dummies.remove_at(i)
		d.queue_free()
	_move_dummy(keep, pos)
	return keep


func _move_dummy(d: TrainingDummy, pos: Vector3) -> void:
	d.global_position = pos
	d.velocity = Vector3.ZERO
	d.spawn_transform = d.global_transform


func _gamepad_mode() -> void:
	# Kurzer Stickausschlag übernimmt den Controller, dann neutral.
	_set_stick(Vector2(0.9, 0.0))
	_set_stick(Vector2.ZERO)


# --- Input -------------------------------------------------------------------

func test_i1_camera_relative_and_diagonal() -> void:
	_place_player(Vector3(0, 0.05, 0), Vector3.FORWARD)
	await _ticks(60)  # Kamera auf den Player einschwingen lassen
	var screen_before := camera.unproject_position(player.global_position)
	Input.action_press("move_up")
	await _ticks(30)
	Input.action_release("move_up")
	var screen_after := camera.unproject_position(player.global_position)
	var delta := screen_after - screen_before
	_check(delta.y < -20.0, "W bewegt nicht bildschirm-oben (dy=%.1f)" % delta.y)
	_check(absf(delta.x) < absf(delta.y) * 0.05, "W hat seitlichen Drift (dx=%.1f)" % delta.x)
	await _ticks(20)
	Input.action_press("move_up")
	Input.action_press("move_right")
	var max_speed := 0.0
	for i in 60:
		await _ticks(1)
		max_speed = maxf(max_speed, Vector2(player.velocity.x, player.velocity.z).length())
	Input.action_release("move_up")
	Input.action_release("move_right")
	_check(max_speed <= player.tuning.move_speed + 0.001, "Diagonale überschreitet Maxspeed (%.3f)" % max_speed)
	_check(max_speed >= player.tuning.move_speed * 0.98, "Diagonale erreicht Maxspeed nicht (%.3f)" % max_speed)


func test_i2_stick_facing_persists() -> void:
	_place_player(Vector3(0, 0.05, 0), Vector3.FORWARD)
	var target := Vector3(1, 0, 1).normalized()
	_set_stick(_stick_for_world(target))
	await _ticks(10)
	_check(InputRouter.active_source == InputRouter.Source.GAMEPAD, "Controller nicht aktiv")
	_check(player.facing_direction.distance_to(target) < 0.02, "Stick setzt Facing nicht")
	_set_stick(Vector2.ZERO)
	await _ticks(30)
	_check(player.facing_direction.distance_to(target) < 0.02, "Facing nach Stick-Neutral verloren")
	# Knockback-artige Fremdgeschwindigkeit und Gravitation ändern Facing nicht.
	player.velocity = Vector3(-6, 3, 2)
	await _ticks(20)
	_check(player.facing_direction.distance_to(target) < 0.02, "Fremdgeschwindigkeit ändert Facing")
	# Stickrauschen unter Deadzone ändert Facing nicht.
	_set_stick(Vector2(0.1, -0.1))
	await _ticks(10)
	_check(player.facing_direction.distance_to(target) < 0.02, "Rauschen in Deadzone ändert Facing")


func test_i2_controller_attack_keeps_released_direction() -> void:
	var d := _only_dummy(Vector3(-1.3, 0.02, 0))  # Dummy links (Welt -X)
	_place_player(Vector3(0, 0.05, 0), Vector3.FORWARD)
	var b := camera.global_basis
	var up_right := (Vector3(b.x.x, 0, b.x.z).normalized() + Vector3(-b.z.x, 0, -b.z.z).normalized()).normalized()
	_set_stick(Vector2(0.7, -0.7))  # schräg rechts oben
	await _ticks(6)
	_set_stick(Vector2.ZERO)
	var facing := player.facing_direction
	_check(facing.distance_to(up_right) < 0.03, "Stick rechts-oben ergibt falsches Facing")
	player.global_position = Vector3(0, 0.05, 0)
	player.velocity = Vector3.ZERO
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _ticks(3)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _ticks(30)
	_check(player.attack_direction.distance_to(facing) < 0.001, "Attack-Richtung weicht vom Facing ab")
	_check(player.weapon.direction.distance_to(facing) < 0.001, "Swing-Richtung magnetisiert")
	_check(is_equal_approx(d.hp, d.max_hp), "Dummy außerhalb der Schlagrichtung getroffen")


func test_i3_held_attack_full_cycle() -> void:
	_only_dummy(Vector3(5, 0.02, 3))
	_place_player(Vector3(0, 0.05, 0), Vector3.FORWARD)
	var starts: Array[int] = []
	var tick := [0]
	player.weapon.swing_started.connect(func(_id: int, _dir: Vector3) -> void: starts.append(tick[0]))
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	for i in 120:
		tick[0] = i
		await _ticks(1)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	var total := player.weapon.data.total_duration()
	_check(starts.size() == 4, "Gehaltenes RT: %d statt 4 Swings in 2 s" % starts.size())
	for i in range(1, starts.size()):
		var interval := (starts[i] - starts[i - 1]) * DT
		_check(interval >= total - 0.0001, "Swing-Abstand %.3f s < voller Zyklus %.2f s" % [interval, total])
	# Loslassen/erneutes Drücken resettet keinen Cooldown.
	await _ticks(2)
	starts.clear()
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _ticks(2)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _ticks(2)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _ticks(2)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _ticks(10)
	_check(starts.size() <= 1, "Schnelles Nachdrücken erzeugt %d Swings" % starts.size())


func test_i4_held_dodge_once() -> void:
	_only_dummy(Vector3(5, 0.02, 3))
	_place_player(Vector3(-3, 0.05, 0), Vector3.RIGHT)
	var dodges := [0]
	var last_state := [player.state]
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	for i in 120:
		await _ticks(1)
		if player.state == PlayerController.State.DODGE and last_state[0] != PlayerController.State.DODGE:
			dodges[0] += 1
		last_state[0] = player.state
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	_check(dodges[0] == 1, "LT 2 s gehalten: %d Dodges" % dodges[0])
	# Trigger-Hysterese: Pendeln zwischen 0.25 und 0.3 (unter AN, über AUS) erzeugt keinen Dodge.
	await _ticks(50)
	dodges[0] = 0
	for i in 20:
		_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.3 if i % 2 == 0 else 0.25)
		await _ticks(2)
		if player.state == PlayerController.State.DODGE and last_state[0] != PlayerController.State.DODGE:
			dodges[0] += 1
		last_state[0] = player.state
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	_check(dodges[0] == 0, "Trigger-Rauschen löst Dodge aus")
	# Tastatur: Space gedrückt halten (Echo-Events) → höchstens ein Dodge.
	await _ticks(50)
	_place_player(Vector3(-3, 0.05, 0), Vector3.RIGHT)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.keycode = KEY_SPACE
	key.pressed = true
	_push(key)
	dodges[0] = 0
	for i in 90:
		if i % 3 == 0:
			var echo := key.duplicate() as InputEventKey
			echo.echo = true
			_push(echo)
		await _ticks(1)
		if player.state == PlayerController.State.DODGE and last_state[0] != PlayerController.State.DODGE:
			dodges[0] += 1
		last_state[0] = player.state
	_check(dodges[0] == 1, "Space gehalten: %d Dodges" % dodges[0])


func test_i5_mouse_ignored_in_controller_mode() -> void:
	_place_player(Vector3(0, 0.05, 0), Vector3.FORWARD)
	_set_stick(_stick_for_world(Vector3.LEFT))
	await _ticks(4)
	_set_stick(Vector2.ZERO)
	await _ticks(2)
	var facing := player.facing_direction
	var far_right := camera.unproject_position(player.global_position + Vector3(4, 0, 0))
	_mouse_move_to(far_right, Vector2(1, 1))  # Mikrobewegung unter Übernahmeschwelle
	await _ticks(10)
	_check(InputRouter.active_source == InputRouter.Source.GAMEPAD, "Mausrauschen übernimmt Quelle")
	_check(player.facing_direction.distance_to(facing) < 0.001, "Unbewegte Maus dreht Player im Controllerbetrieb")
	_mouse_move_to(far_right, Vector2(15, 0))
	await _ticks(2)
	_check(InputRouter.active_source == InputRouter.Source.KEYBOARD_MOUSE, "Echte Mausbewegung übernimmt nicht")
	_check(player.facing_direction.dot(Vector3.RIGHT) > 0.98, "Maus-Facing nach Übernahme falsch")


func test_i6_pause_focus_disconnect_release() -> void:
	_only_dummy(Vector3(5, 0.02, 3))
	_place_player(Vector3(0, 0.05, 0), Vector3.FORWARD)
	var pause_menu: PauseMenu = main.get("pause_menu")
	var starts := [0]
	player.weapon.swing_started.connect(func(_id: int, _dir: Vector3) -> void: starts[0] += 1)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _ticks(2)
	_check(InputRouter.attack_held, "RT gehalten nicht erkannt")
	pause_menu.open()
	_check(not InputRouter.attack_held, "Pause löst gehaltenen Attack nicht")
	await _ticks(10)
	pause_menu.close()
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.95)  # weiterhin physisch gehalten
	await _ticks(60)
	var count_after: int = starts[0]
	await _ticks(60)
	_check(starts[0] == count_after, "Nach Pause läuft gehaltener Angriff weiter")
	_check(not InputRouter.attack_held, "RT nach Fortsetzen nicht gelatcht")
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _ticks(40)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _ticks(2)
	_check(InputRouter.attack_held, "Neuer RT-Druck nach Loslassen nicht erkannt")
	# Fokusverlust
	InputRouter.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await _ticks(1)
	_check(not InputRouter.attack_held, "Fokusverlust löst Held-Input nicht")
	# Disconnect des aktiven Controllers: lösen + pausieren
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _ticks(2)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _ticks(2)
	InputRouter._on_joy_connection_changed(0, false)
	_check(not InputRouter.attack_held, "Disconnect löst Held-Input nicht")
	_check(get_tree().paused and pause_menu.is_open(), "Disconnect pausiert nicht")
	pause_menu.close()
	# Reset löst Held-Input (Maus)
	_mouse_button(MOUSE_BUTTON_LEFT, true, Vector2(640, 400))
	await _ticks(1)
	_check(InputRouter.attack_held, "LMB gehalten nicht erkannt")
	arena.reset_training()
	await _ticks(1)
	_check(not InputRouter.attack_held, "Reset löst Held-Input nicht")
	_mouse_button(MOUSE_BUTTON_LEFT, false, Vector2(640, 400))


func test_touch_multitouch_independent() -> void:
	_only_dummy(Vector3(5, 0.02, 3))
	_place_player(Vector3(-3, 0.05, 3), Vector3.FORWARD)
	var tc: TouchControls = main.get_node("TouchLayer/TouchControls")
	var stick := tc.stick_rest_center()
	_touch(0, true, stick)
	_drag(0, stick + Vector2(90, 0), Vector2(90, 0))
	await _ticks(10)
	_check(InputRouter.active_source == InputRouter.Source.TOUCH, "Touch nicht aktiv")
	_check(InputRouter.move_input.distance_to(Vector2(1, 0)) < 0.01, "Stick rechts ergibt move_input %s" % InputRouter.move_input)
	var screen_right := Vector3(camera.global_basis.x.x, 0, camera.global_basis.x.z).normalized()
	_check(player.facing_direction.distance_to(screen_right) < 0.02, "Touch-Stick setzt Facing nicht")
	var starts := [0]
	player.weapon.swing_started.connect(func(_id: int, _dir: Vector3) -> void: starts[0] += 1)
	_touch(1, true, tc.attack_center())
	await _ticks(3)
	_check(InputRouter.touch_attack_held and starts[0] == 1, "Attack-Finger startet keinen Angriff")
	_check(InputRouter.move_input.length() > 0.9, "Attack-Finger stört Stick")
	_touch(2, true, tc.dodge_center())
	await _ticks(2)
	_check(player.state == PlayerController.State.DODGE, "Dritter Finger (Dodge) nicht ausgelöst")
	# Kein Stehlen: vierter Finger auf belegtem Attack-Button wird ignoriert.
	_touch(3, true, tc.attack_center())
	_touch(3, false, tc.attack_center())
	_check(InputRouter.touch_attack_held, "Fremder Finger hat Attack-Besitz gestohlen/gelöst")
	# Stickfinger über Buttons ziehen bleibt Stick.
	_drag(0, tc.attack_center(), Vector2(400, 0))
	_check(InputRouter.touch_stick_active and InputRouter.touch_attack_held, "Stickfinger wechselt Control")
	# Gehaltener Dodge-Finger erzeugt keinen zweiten Dodge.
	var dodges := [0]
	var last := [player.state]
	for i in 90:
		await _ticks(1)
		if player.state == PlayerController.State.DODGE and last[0] != PlayerController.State.DODGE:
			dodges[0] += 1
		last[0] = player.state
	_check(dodges[0] == 0, "Gehaltener Dodge-Finger erzeugt weitere Dodges")
	_touch(1, false, tc.attack_center())
	_touch(2, false, tc.dodge_center())
	var facing := player.facing_direction
	_touch(0, false, stick)
	await _ticks(10)
	_check(InputRouter.move_input == Vector2.ZERO, "Stick-Loslassen setzt Bewegung nicht zurück")
	_check(player.facing_direction.distance_to(facing) < 0.001, "Facing nach Touch-Loslassen verloren")
	# Emulierte Maus aus Touch zählt nicht als Angriff.
	starts[0] = 0
	await _ticks(40)
	_mouse_button(MOUSE_BUTTON_LEFT, true, Vector2(640, 400), InputEvent.DEVICE_ID_EMULATION)
	await _ticks(3)
	_mouse_button(MOUSE_BUTTON_LEFT, false, Vector2(640, 400), InputEvent.DEVICE_ID_EMULATION)
	_check(starts[0] == 0, "Emulierte Maus erzeugt Angriff")


func test_mouse_facing_projection() -> void:
	_place_player(Vector3(1.0, 0.05, -0.5), Vector3.FORWARD)
	await _ticks(30)  # Kamera folgt
	var worst := 0.0
	for i in 12:
		var angle := TAU * i / 12.0
		var dir := Vector3(cos(angle), 0, sin(angle))
		var world_point := player.global_position + dir * 3.0
		_mouse_move_to(camera.unproject_position(world_point))
		await _ticks(1)
		worst = maxf(worst, rad_to_deg(player.facing_direction.angle_to(dir)))
	_check(worst < 1.0, "Maus-Facing-Abweichung %.2f° > 1°" % worst)
	_check(player.velocity.length() < 0.01, "Maus-Facing bewegt den Player")
	# Maus direkt auf dem Player: letzte gültige Richtung bleibt.
	var last := player.facing_direction
	_mouse_move_to(camera.unproject_position(player.global_position))
	await _ticks(1)
	_check(player.facing_direction.distance_to(last) < 0.001, "Maus am Player verändert Facing")


func test_desktop_strafe_and_fixed_attack_direction() -> void:
	var d := _only_dummy(Vector3(1.3, 0.02, 0))
	_place_player(Vector3(0, 0.05, 0), Vector3.FORWARD)
	# Maus rechts (Welt +X), A gehalten: Bewegung bildschirm-links, Facing zur Maus.
	_mouse_move_to(camera.unproject_position(Vector3(4, 0, 0)))
	Input.action_press("move_left")
	await _ticks(20)
	Input.action_release("move_left")
	var move_dir := Vector3(player.velocity.x, 0, player.velocity.z).normalized()
	var screen_left := -Vector3(camera.global_basis.x.x, 0, camera.global_basis.x.z).normalized()
	_check(move_dir.distance_to(screen_left) < 0.05, "A bewegt nicht bildschirm-links")
	_check(player.facing_direction.dot(Vector3.RIGHT) > 0.9, "Facing folgt beim Strafen nicht der Maus")
	_check(move_dir.dot(player.facing_direction) < -0.5, "Bewegung und Facing nicht unabhängig")
	# Schlag Richtung Dummy starten, dann Maus nach hinten: Richtung bleibt fixiert.
	_place_player(Vector3(0, 0.05, 0), Vector3.RIGHT)
	await _ticks(40)
	_mouse_move_to(camera.unproject_position(Vector3(4, 0, 0)))
	await _ticks(1)
	var mouse_screen := camera.unproject_position(Vector3(4, 0, 0))
	_mouse_button(MOUSE_BUTTON_LEFT, true, mouse_screen)
	await _ticks(2)
	_mouse_button(MOUSE_BUTTON_LEFT, false, mouse_screen)
	_mouse_move_to(camera.unproject_position(Vector3(-4, 0, 0)))
	await _ticks(30)
	_check(player.weapon.direction.distance_to(Vector3.RIGHT) < 0.02, "Swing-Richtung folgt Maus während des Schlags")
	_check(is_equal_approx(d.hp, d.max_hp - player.weapon.data.damage), "Dummy in fixierter Richtung nicht getroffen (HP %.0f)" % d.hp)


func test_ui_click_does_not_attack() -> void:
	_only_dummy(Vector3(5, 0.02, 3))
	var hud: Hud = main.get("hud")
	var button: Button = hud.get_node("SafeRoot/PauseButton")
	var starts := [0]
	player.weapon.swing_started.connect(func(_id: int, _dir: Vector3) -> void: starts[0] += 1)
	var center := button.get_global_rect().get_center()
	_mouse_button(MOUSE_BUTTON_LEFT, true, center)
	_mouse_button(MOUSE_BUTTON_LEFT, false, center)
	await _ticks(10)
	var pause_menu: PauseMenu = main.get("pause_menu")
	_check(pause_menu.is_open(), "Pause-Button per Maus öffnet Pause nicht")
	_check(starts[0] == 0 and not InputRouter.attack_held, "UI-Klick löst Weltangriff aus")
	pause_menu.close()


# --- Combat ------------------------------------------------------------------

func _single_rt_attack() -> void:
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _ticks(2)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)


func test_c1_one_hit_per_swing() -> void:
	var d := _only_dummy(Vector3(1.2, 0.02, 0))
	_gamepad_mode()
	_place_player(Vector3(0, 0.05, 0), Vector3.RIGHT)
	var hits := [0]
	player.hit_landed.connect(func(_t: Node3D, _p: Vector3) -> void: hits[0] += 1)
	await _single_rt_attack()
	await _ticks(40)
	_check(hits[0] == 1, "Ein Swing trifft %d-mal" % hits[0])
	_check(is_equal_approx(d.hp, d.max_hp - 20.0), "Dummy-HP nach einem Swing: %.0f" % d.hp)


func test_c2_sector_limits() -> void:
	# Reine Geometrie (Reichweite 1.9, Winkel 110°, Zielradius 0.4).
	var o := Vector3.ZERO
	var f := Vector3.RIGHT
	_check(WeaponController.is_in_sector(o, f, Vector3(1.5, 0, 0), 0.4, 1.9, 110, 1.5), "Front nicht im Sektor")
	_check(WeaponController.is_in_sector(o, f, Vector3(2.25, 0, 0), 0.4, 1.9, 110, 1.5), "Reichweitengrenze nicht im Sektor")
	_check(not WeaponController.is_in_sector(o, f, Vector3(2.4, 0, 0), 0.4, 1.9, 110, 1.5), "Außerhalb Reichweite getroffen")
	_check(not WeaponController.is_in_sector(o, f, Vector3(-1.2, 0, 0), 0.4, 1.9, 110, 1.5), "Rückseite getroffen")
	_check(not WeaponController.is_in_sector(o, f, Vector3(0, 0, 1.4), 0.4, 1.9, 110, 1.5), "90°-Seite getroffen")
	_check(not WeaponController.is_in_sector(o, f, Vector3(1.0, 2.0, 0), 0.4, 1.9, 110, 1.5), "Höhenunterschied getroffen")
	# Integration: Dummies hinten, seitlich, zu weit → kein Treffer; zwei im Sektor → beide.
	var dummies := arena.dummies.duplicate()
	_gamepad_mode()
	_place_player(Vector3(0, 0.05, 0), Vector3.RIGHT)
	_move_dummy(dummies[0], Vector3(-1.3, 0.02, 0))
	_move_dummy(dummies[1], Vector3(0, 0.02, 1.4))
	_move_dummy(dummies[2], Vector3(3.2, 0.02, 0))
	await _ticks(2)
	await _single_rt_attack()
	await _ticks(40)
	for dd: TrainingDummy in dummies:
		_check(is_equal_approx(dd.hp, dd.max_hp), "Dummy bei %s außerhalb getroffen" % dd.global_position)
	_move_dummy(dummies[0], Vector3(1.3, 0.02, 0.7))
	_move_dummy(dummies[1], Vector3(1.3, 0.02, -0.7))
	await _ticks(2)
	_place_player(Vector3(0, 0.05, 0), Vector3.RIGHT)
	await _single_rt_attack()
	await _ticks(40)
	_check(dummies[0].hp < dummies[0].max_hp and dummies[1].hp < dummies[1].max_hp, "Zwei Ziele im Sektor nicht beide getroffen")


func test_c3_dodge_cancel_keeps_cadence() -> void:
	_only_dummy(Vector3(5, 0.02, 3))
	_gamepad_mode()
	_place_player(Vector3(-3, 0.05, 0), Vector3.RIGHT)
	var starts: Array[int] = []
	var tick := [0]
	player.weapon.swing_started.connect(func(_id: int, _dir: Vector3) -> void: starts.append(tick[0]))
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	for i in 70:
		tick[0] = i
		if i == 4:
			_joy_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
		if i == 8:
			_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
		await _ticks(1)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_check(starts.size() >= 2, "Kein zweiter Angriff nach Dodge")
	if starts.size() >= 2:
		var interval := (starts[1] - starts[0]) * DT
		_check(interval >= player.weapon.data.total_duration() - 0.0001, "Dodge-Abbruch verkürzt Takt auf %.3f s" % interval)


func _measure_knockback(ticks_per_second: int) -> Dictionary:
	Engine.physics_ticks_per_second = ticks_per_second
	var d := arena.dummies[0]
	_move_dummy(d, Vector3(1.2, 0.02, 0))
	d.hp = d.max_hp
	_place_player(Vector3(0, 0.05, 0), Vector3.RIGHT)
	await _ticks(3)
	var start := d.global_position
	var max_step := 0.0
	var last := start
	await _single_rt_attack()
	for i in int(1.5 * ticks_per_second):
		await _ticks(1)
		max_step = maxf(max_step, d.global_position.distance_to(last))
		last = d.global_position
	var result := {"distance": Vector2(last.x - start.x, last.z - start.z).length(), "max_step": max_step,
			"hit": d.hp < d.max_hp, "rest_speed": Vector2(d.velocity.x, d.velocity.z).length()}
	Engine.physics_ticks_per_second = 60
	return result


func test_c4_knockback_time_based() -> void:
	_only_dummy(Vector3(1.2, 0.02, 0))
	_gamepad_mode()
	var at60: Dictionary = await _measure_knockback(60)
	var data := player.weapon.data
	_check(at60["hit"], "Kein Treffer für Knockback-Messung")
	_check(at60["max_step"] <= data.knockback_speed / 60.0 * 1.05, "Knockback-Sprung %.3f m pro Tick (Teleport?)" % at60["max_step"])
	_check(at60["distance"] > 0.7 and at60["distance"] < 1.5, "Knockback-Distanz %.2f m unplausibel" % at60["distance"])
	_check(at60["rest_speed"] < 0.01, "Dummy kommt nicht zur Ruhe")
	var at30: Dictionary = await _measure_knockback(30)
	var ratio: float = at30["distance"] / maxf(at60["distance"], 0.001)
	_check(absf(ratio - 1.0) < 0.12, "Knockback tickratenabhängig: 60 Hz %.2f m / 30 Hz %.2f m" % [at60["distance"], at30["distance"]])
	print("    Knockback 60 Hz: %.3f m, 30 Hz: %.3f m" % [at60["distance"], at30["distance"]])


# --- Fall / Kante ------------------------------------------------------------

func test_f1_open_edge_no_collider() -> void:
	var space := player.get_world_3d().direct_space_state
	var world_mask := 1
	# Alle Kollisionsformen der Welt: genau die Plattform.
	var shapes := arena.find_children("*", "CollisionShape3D", true, false).filter(
			func(s: Node) -> bool: return s.get_parent() is StaticBody3D)
	_check(shapes.size() == 1, "Unerwartete statische Collider: %d" % shapes.size())
	var edges := [Vector3(6.5, 0, 0), Vector3(-6.5, 0, 0), Vector3(0, 0, 5), Vector3(0, 0, -5)]
	for edge: Vector3 in edges:
		var outward := Vector3(signf(edge.x), 0, signf(edge.z))
		var inside := edge - outward * 0.1
		var outside := edge + outward * 0.1
		var down_in := space.intersect_ray(PhysicsRayQueryParameters3D.create(inside + Vector3.UP * 3, inside + Vector3.DOWN * 3, world_mask))
		var down_out := space.intersect_ray(PhysicsRayQueryParameters3D.create(outside + Vector3.UP * 3, outside + Vector3.DOWN * 3, world_mask))
		_check(not down_in.is_empty() and absf(down_in["position"].y) < 0.01, "Kein Boden innen an %s" % edge)
		_check(down_out.is_empty(), "Collider außerhalb der Kante %s" % edge)
		for h in [0.1, 0.6, 1.5]:
			var across := space.intersect_ray(PhysicsRayQueryParameters3D.create(edge - outward * 1.0 + Vector3.UP * h, edge + outward * 3.0 + Vector3.UP * h, world_mask))
			_check(across.is_empty(), "Randbarriere an %s in Höhe %.1f" % [edge, h])


func test_f1_no_edge_support() -> void:
	# Kapselrundung darf kein Stehen über der Kante erlauben (Schwerpunkt 0,2 m jenseits der Kante).
	var d := _only_dummy(Vector3(6.7, 0.0, -2.0))
	_gamepad_mode()
	_place_player(Vector3(6.7, 0.0, 2.0), Vector3.RIGHT)
	await _ticks(40)
	_check(player.global_position.y < -1.0, "Player steht auf der Kante (y %.2f)" % player.global_position.y)
	_check(d.is_defeated or d.global_position.y < -1.0, "Dummy steht auf der Kante (y %.2f)" % d.global_position.y)


func test_f2_player_fall_respawn_once() -> void:
	_only_dummy(Vector3(-4, 0.02, -3))
	var respawns := [0]
	player.respawned.connect(func() -> void: respawns[0] += 1)
	_place_player(Vector3(5.0, 0.05, 0), Vector3.RIGHT)
	_set_stick(_stick_for_world(Vector3.RIGHT))
	var min_y := 10.0
	var saw_falling := false
	for i in 200:
		await _ticks(1)
		min_y = minf(min_y, player.global_position.y)
		saw_falling = saw_falling or player.state == PlayerController.State.FALLING
		if player.state == PlayerController.State.OUT:
			break
	_set_stick(Vector2.ZERO)
	_check(min_y < arena.kill_height, "Player fällt nicht unter Killhöhe (min y %.2f)" % min_y)
	_check(saw_falling, "Kein FALLING-Zustand während des Falls")
	await _ticks(60)
	_check(player.fall_count == 1 and arena.player_fall_count == 1, "Fall zählt %d/%d statt 1" % [player.fall_count, arena.player_fall_count])
	_check(respawns[0] == 1, "Respawn %d-mal" % respawns[0])
	var spawn := arena.player_spawn.global_position
	_check(player.global_position.distance_to(spawn) < 0.3, "Nicht am Spawn: %s" % player.global_position)
	_check(player.state == PlayerController.State.MOVE and player.is_on_floor(), "Nach Respawn nicht bewegungsbereit")
	await _ticks(60)
	_check(player.fall_count == 1 and respawns[0] == 1, "Nachträglicher Doppel-Reset")
	_check(is_equal_approx(player.hp, player.tuning.max_hp), "Sturzschaden in M1")


func test_f2_dodge_over_edge_falls() -> void:
	_only_dummy(Vector3(-4, 0.02, -3))
	_gamepad_mode()
	_place_player(Vector3(5.3, 0.05, 0), Vector3.RIGHT)
	await _ticks(2)
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await _ticks(3)
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	var was_dodge := player.state == PlayerController.State.DODGE
	var min_y := 10.0
	for i in 90:
		await _ticks(1)
		min_y = minf(min_y, player.global_position.y)
	_check(was_dodge, "Dodge nicht ausgelöst")
	_check(min_y < arena.kill_height, "Dodge über Kante fällt nicht (min y %.2f)" % min_y)
	_check(player.fall_count == 1, "Fallzähler nach Dodge-Fall: %d" % player.fall_count)


func test_f3_dummy_edge_kill_once() -> void:
	var d := _only_dummy(Vector3(5.9, 0.02, 0))
	_gamepad_mode()
	_place_player(Vector3(4.6, 0.05, 0), Vector3.RIGHT)
	await _ticks(2)
	await _single_rt_attack()
	var min_y := 10.0
	for i in 100:
		await _ticks(1)
		if d.visible:
			min_y = minf(min_y, d.global_position.y)
	_check(min_y < 0.0 or not d.visible, "Dummy fällt nicht")
	_check(d.defeat_count == 1 and d.last_defeat_reason == TrainingDummy.DefeatReason.FALL, "Kanten-Niederlage %d-mal / Grund %d" % [d.defeat_count, d.last_defeat_reason])
	_check(arena.dummy_fall_defeats == 1 and arena.dummy_hp_defeats == 0, "Arenazähler Kante %d / HP %d" % [arena.dummy_fall_defeats, arena.dummy_hp_defeats])
	await _ticks(160)
	_check(d.visible and not d.is_defeated, "Dummy nicht respawnt")
	_check(d.defeat_count == 1, "Doppelte Niederlage nach Respawn")


func test_f3_dummy_hp_kill_once() -> void:
	var d := _only_dummy(Vector3(-2.7, 0.02, 0))
	_place_player(Vector3(-4.0, 0.05, 0), Vector3.RIGHT)
	_set_stick(_stick_for_world(Vector3.RIGHT) * 0.6)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	for i in 240:
		await _ticks(1)
		if d.is_defeated:
			break
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_set_stick(Vector2.ZERO)
	_check(d.is_defeated and d.last_defeat_reason == TrainingDummy.DefeatReason.HP, "HP-Niederlage nicht erreicht (HP %.0f)" % d.hp)
	_check(d.defeat_count == 1 and arena.dummy_hp_defeats == 1, "HP-Niederlage %d-mal" % d.defeat_count)
	var hit := HitInfo.new()
	hit.damage = 20.0
	_check(not d.receive_hit(hit), "Besiegter Dummy nimmt weitere Treffer")
	# Besiegter Dummy fällt unter Killhöhe: keine zweite Niederlage.
	d.global_position = Vector3(d.global_position.x, arena.kill_height - 1.0, 0)
	await _ticks(2)
	_check(d.defeat_count == 1 and arena.dummy_fall_defeats == 0, "HP- und Fall-Niederlage doppelt gezählt")


# --- Architektur -------------------------------------------------------------

func test_a1_visual_swap() -> void:
	var d := _only_dummy(Vector3(1.2, 0.02, 0))
	# Placeholder komplett entfernen und durch anders strukturierte Darstellung ersetzen.
	for child in player.visual_root.get_children():
		player.visual_root.remove_child(child)
		child.free()
	var replacement: PlayerVisual = SWAP_VISUAL.new()
	player.visual_root.add_child(replacement)
	var socket := replacement.get_weapon_socket()
	player.refresh_visual()
	await _ticks(2)
	_check(player.weapon.mount.global_position.distance_to(socket.global_position) < 0.001, "Weapon-Mount folgt fremdem Socket nicht")
	_gamepad_mode()
	_place_player(Vector3(0, 0.05, 0), Vector3.RIGHT)
	await _single_rt_attack()
	await _ticks(40)
	_check(is_equal_approx(d.hp, d.max_hp - 20.0), "Angriff nach Visual-Austausch trifft nicht")
	# Ganz ohne Visual-Adapter: Gameplay läuft weiter.
	for child in player.visual_root.get_children():
		player.visual_root.remove_child(child)
		child.free()
	player.refresh_visual()
	Input.action_press("move_right")
	InputRouter._switch_source(InputRouter.Source.KEYBOARD_MOUSE)
	await _ticks(20)
	Input.action_release("move_right")
	_check(Vector2(player.velocity.x, player.velocity.z).length() > 1.0, "Bewegung ohne Visual-Adapter defekt")
