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
		"test_m11_movement_identical_with_attack_held",
		"test_m11_body_follows_stick_while_attack_held",
		"test_m11_direction_rule_windup_active_recovery",
		"test_m11_visual_swing_crosses_sector_sideways",
		"test_e1_approach_and_attack_cycle",
		"test_e2_no_contact_damage_only_active",
		"test_e3_one_hit_per_enemy_attack",
		"test_e4_no_retarget_after_commit",
		"test_e5_enemy_range_angle_height",
		"test_e6_dodge_iframes_block_damage_and_knockback",
		"test_e7_valid_hit_hp_and_knockback",
		"test_e8_interrupted_attacks_never_hit_late",
		"test_e9_enemy_defeat_once_hp_and_fall",
		"test_e10_edge_probe_stops_chase_only",
		"test_e11_player_death_and_clean_restart",
		"test_e12_player_fall_resets_encounter",
		"test_e13_mode_switch_and_pause_release_inputs",
		"test_e14_probe_held_attack_pressure",
	]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			tests = PackedStringArray(Array(tests).filter(func(t: String) -> bool: return t.contains(arg.trim_prefix("--only="))))
	for test_name in tests:
		_current = test_name
		var before := _failures.size()
		# M1/M1.1-Regressionen laufen im Trainingsmodus, M2A-Tests (test_e…) im Kampfmodus.
		await _setup(TrainingArena.Mode.COMBAT if test_name.begins_with("test_e") else TrainingArena.Mode.TRAINING)
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


func _setup(mode: TrainingArena.Mode) -> void:
	get_tree().paused = false
	InputRouter.set_touch_test_mode(false)
	InputRouter._switch_source(InputRouter.Source.KEYBOARD_MOUSE)
	InputRouter.release_all()
	InputRouter.mouse_aim_valid = false
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)
	main = MAIN_SCENE.instantiate()
	main.set("start_mode", mode)
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
	_check(rad_to_deg(player.attack_direction.angle_to(facing)) < 1.0, "Attack-Richtung weicht vom Facing ab")
	_check(rad_to_deg(player.weapon.direction.angle_to(facing)) < 1.0, "Swing-Richtung magnetisiert")
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
	# Vollständige Zyklen in 2 s bei gehaltenem RT (0,80 s → Starts bei 0 / 0,8 / 1,6 s).
	var expected := int(floor(119.0 / (total * 60.0))) + 1
	_check(starts.size() == expected, "Gehaltenes RT: %d statt %d Swings in 2 s" % [starts.size(), expected])
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
	arena.restart()
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
	# Schlag Richtung Dummy; sobald ACTIVE läuft, Maus nach hinten: Sektor bleibt fixiert.
	_place_player(Vector3(0, 0.05, 0), Vector3.RIGHT)
	await _ticks(40)
	_mouse_move_to(camera.unproject_position(Vector3(4, 0, 0)))
	await _ticks(1)
	var mouse_screen := camera.unproject_position(Vector3(4, 0, 0))
	_mouse_button(MOUSE_BUTTON_LEFT, true, mouse_screen)
	await _ticks(2)
	_mouse_button(MOUSE_BUTTON_LEFT, false, mouse_screen)
	while player.weapon.phase != WeaponController.Phase.ACTIVE:
		await _ticks(1)
	_mouse_move_to(camera.unproject_position(Vector3(-4, 0, 0)))
	await _ticks(30)
	_check(player.weapon.direction.distance_to(Vector3.RIGHT) < 0.02, "Swing-Richtung folgt Maus während ACTIVE")
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
	for i in 360:
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


# --- M1.1: Dauerattacke --------------------------------------------------------

## Stickskript: eine volle 360°-Umdrehung in 1,5 s, danach harte Richtungswechsel alle 0,25 s.
## Liefert Joy-Achsen (x rechts, y unten) für Tick i.
func _sweep_stick(i: int) -> Vector2:
	if i < 90:
		var angle := TAU * i / 90.0
		return Vector2(cos(angle), -sin(angle))
	var reversals: Array[Vector2] = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
	return reversals[((i - 90) / 15) % reversals.size()]


const SWEEP_TICKS: int = 150


func _body_forward() -> Vector3:
	var f := -player.global_basis.z
	return Vector3(f.x, 0, f.z).normalized()


func _record_sweep(hold_attack: bool) -> Array[Vector2]:
	_place_player(Vector3(0, 0, 0), Vector3.FORWARD)
	await _ticks(10)
	var velocities: Array[Vector2] = []
	if hold_attack:
		_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	for i in SWEEP_TICKS:
		_set_stick(_sweep_stick(i))
		await _ticks(1)
		velocities.append(Vector2(player.velocity.x, player.velocity.z))
	_set_stick(Vector2.ZERO)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _ticks(60)
	return velocities


func test_m11_movement_identical_with_attack_held() -> void:
	_only_dummy(Vector3(5.5, 0.02, 4))
	_gamepad_mode()
	var free: Array[Vector2] = await _record_sweep(false)
	var held: Array[Vector2] = await _record_sweep(true)
	var worst := 0.0
	for i in SWEEP_TICKS:
		worst = maxf(worst, free[i].distance_to(held[i]))
	print("    Max. Geschwindigkeitsabweichung mit/ohne gehaltenes RT: %.3f m/s" % worst)
	_check(worst < 0.05, "Bewegung bei gehaltenem RT weicht um %.2f m/s ab" % worst)


func test_m11_body_follows_stick_while_attack_held() -> void:
	_only_dummy(Vector3(5.5, 0.02, 4))
	_gamepad_mode()
	_place_player(Vector3(0, 0, 0), Vector3.FORWARD)
	await _ticks(10)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	var last_yaw := player.rotation.y
	var max_step := 0.0
	var diff_sum := 0.0
	var diff_count := 0
	var attack_ticks := 0
	for i in 90:  # nur die kontinuierliche Umdrehung
		_set_stick(_sweep_stick(i))
		await _ticks(1)
		max_step = maxf(max_step, absf(rad_to_deg(angle_difference(last_yaw, player.rotation.y))))
		last_yaw = player.rotation.y
		if player.state == PlayerController.State.ATTACK:
			attack_ticks += 1
		if player.weapon.phase != WeaponController.Phase.ACTIVE:
			diff_sum += rad_to_deg(_body_forward().angle_to(player.facing_direction))
			diff_count += 1
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_set_stick(Vector2.ZERO)
	var mean_diff := diff_sum / maxf(diff_count, 1)
	print("    Angriff aktiv in %d/90 Ticks, max. Körperdrehung/Tick %.1f°, mittl. Körper↔Facing außerhalb ACTIVE %.1f°" % [attack_ticks, max_step, mean_diff])
	_check(attack_ticks > 60, "Gehaltenes RT hält den Angriff nicht dauerhaft aktiv")
	_check(max_step < 20.0, "Körper springt um %.1f° in einem Tick" % max_step)
	_check(mean_diff < 20.0, "Körper folgt dem Stick nicht (mittl. %.1f°)" % mean_diff)


func test_m11_direction_rule_windup_active_recovery() -> void:
	var dummies := arena.dummies.duplicate()
	_gamepad_mode()
	_place_player(Vector3(0, 0, 0), Vector3.RIGHT)
	await _ticks(20)
	# Ziel vorne (Welt -Z), seitlich (+X, bisherige Richtung) und hinten (+Z).
	_move_dummy(dummies[0], Vector3(0, 0.02, -2.2))
	_move_dummy(dummies[1], Vector3(1.4, 0.02, 0))
	_move_dummy(dummies[2], Vector3(0, 0.02, 2.4))
	await _ticks(2)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _ticks(2)
	_check(player.weapon.phase == WeaponController.Phase.WINDUP, "Angriff nicht im WINDUP")
	# Während WINDUP auf Welt -Z umlenken: bevorstehende Schlagrichtung folgt.
	_set_stick(_stick_for_world(Vector3.FORWARD) * 0.5)
	while player.weapon.phase == WeaponController.Phase.WINDUP:
		await _ticks(1)
	var fixed := player.weapon.direction
	_check(rad_to_deg(fixed.angle_to(Vector3.FORWARD)) < 5.0, "WINDUP-Umlenkung nicht übernommen (%.1f°)" % rad_to_deg(fixed.angle_to(Vector3.FORWARD)))
	_check(rad_to_deg(_body_forward().angle_to(fixed)) < 0.5, "Körper und Treffersektor weichen bei ACTIVE-Beginn ab")
	# Während ACTIVE nach hinten lenken: Sektor, Körper und Trail bleiben fixiert, Position bewegt sich.
	_set_stick(_stick_for_world(Vector3.BACK) * 0.5)
	var start_velocity_z := player.velocity.z
	var trail: SwingTrail = player.get_node("SwingTrail")
	while player.weapon.phase == WeaponController.Phase.ACTIVE:
		await _ticks(1)
		_check(player.weapon.direction.distance_to(fixed) < 0.0001, "Treffersektor dreht während ACTIVE")
		_check(rad_to_deg(_body_forward().angle_to(fixed)) < 0.5, "Körper dreht während ACTIVE")
		var trail_forward := -trail.global_basis.z
		_check(rad_to_deg(Vector3(trail_forward.x, 0, trail_forward.z).angle_to(fixed)) < 0.5, "Trail weicht vom Sektor ab")
	# Bewegung folgt dem neuen Input (+Z) auch während ACTIVE.
	_check(player.velocity.z - start_velocity_z > 1.5, "Bewegung folgt Input während ACTIVE nicht (Δvz %.2f)" % (player.velocity.z - start_velocity_z))
	_check(dummies[0].hp < dummies[0].max_hp, "Ziel in fixierter Richtung nicht getroffen")
	_check(is_equal_approx(dummies[1].hp, dummies[1].max_hp), "Ziel in alter Startrichtung getroffen")
	_check(is_equal_approx(dummies[2].hp, dummies[2].max_hp), "Ziel hinten getroffen")
	# RECOVERY: freie Ausrichtung, keine weiteren Treffer.
	_check(player.weapon.phase == WeaponController.Phase.RECOVERY, "Nach ACTIVE keine RECOVERY")
	var hp_before: Array[float] = [dummies[0].hp, dummies[1].hp, dummies[2].hp]
	var recovery_ticks := 0
	while player.weapon.phase == WeaponController.Phase.RECOVERY and recovery_ticks < 12:
		await _ticks(1)
		recovery_ticks += 1
	_check(rad_to_deg(_body_forward().angle_to(Vector3.BACK)) < 15.0, "Körper dreht in RECOVERY nicht frei (%.1f°)" % rad_to_deg(_body_forward().angle_to(Vector3.BACK)))
	# Nächster gehaltener Swing nutzt die neueste Richtung.
	while player.weapon.phase != WeaponController.Phase.ACTIVE:
		await _ticks(1)
	_check(rad_to_deg(player.weapon.direction.angle_to(Vector3.BACK)) < 5.0, "Nächster Swing nutzt nicht die neueste Richtung")
	_check(dummies[0].hp == hp_before[0], "Treffer außerhalb von ACTIVE")
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_set_stick(Vector2.ZERO)
	await _ticks(20)
	_check(dummies[2].hp < dummies[2].max_hp, "Zweiter Swing trifft Ziel in neuer Richtung nicht")


## Placeholder-Adapter: Der Hammerkopf läuft während ACTIVE von rechts nach links durch den Sektor
## und bleibt dabei überwiegend seitlich (keine vertikale Hackbewegung).
func test_m11_visual_swing_crosses_sector_sideways() -> void:
	_only_dummy(Vector3(5.5, 0.02, 4))
	_gamepad_mode()
	_place_player(Vector3(0, 0, 0), Vector3.RIGHT)
	await _ticks(20)
	await _single_rt_attack()
	var samples: Array[float] = []
	var max_vertical := 0.0
	while player.weapon.phase != WeaponController.Phase.RECOVERY:
		await _ticks(1)
		if player.weapon.phase == WeaponController.Phase.ACTIVE:
			await get_tree().process_frame  # Visual/Mount werden in _process aktualisiert
			var head := -player.weapon.mount.global_basis.z
			var flat := Vector3(head.x, 0, head.z).normalized()
			samples.append(-rad_to_deg(player.weapon.direction.signed_angle_to(flat, Vector3.UP)))
			max_vertical = maxf(max_vertical, absf(head.y))
	print("    Hammer-Gier in ACTIVE (rechts +): %s, max. |vertikal| %.2f" % [samples.map(func(a: float) -> String: return "%.0f" % a), max_vertical])
	_check(samples.size() >= 5, "Zu wenige ACTIVE-Samples")
	if samples.size() >= 2:
		_check(samples[0] > 20.0 and samples[samples.size() - 1] < -20.0, "Hammer überstreicht den Sektor nicht von rechts nach links")
	_check(max_vertical < 0.75, "Schlag überwiegend vertikal (|y| %.2f)" % max_vertical)



# --- M2A: Kampfbegegnung (Kampfmodus) ---------------------------------------------

## Gegner an Position mit Blickrichtung. Ohne Ziel bleibt die KI IDLE (für geometrische Regeltests).
func _place_enemy(pos: Vector3, facing: Vector3, with_target: bool) -> Scrapling:
	var e := arena.enemy
	e.weapon.cancel()
	e.target = player if with_target else null
	e.state = Scrapling.State.IDLE
	e.global_position = Vector3(pos.x, 0.0, pos.z)
	e.velocity = Vector3.ZERO
	e.rotation.y = PlayerController.yaw_for_direction(facing.normalized())
	return e


## Gezielter Angriff in fester Richtung (ohne Ziel keine Nachführung); wartet bis ACTIVE beginnt.
func _enemy_attack_until_active(e: Scrapling) -> void:
	e.start_attack()
	while e.weapon.phase == WeaponController.Phase.WINDUP:
		await _ticks(1)


func _await_enemy_weapon_idle(e: Scrapling) -> void:
	while e.weapon.is_busy():
		await _ticks(1)


func _enemy_label(e: Scrapling) -> String:
	if e.state == Scrapling.State.ATTACK:
		return WeaponController.Phase.keys()[e.weapon.phase]
	return Scrapling.State.keys()[e.state]


func test_e1_approach_and_attack_cycle() -> void:
	var e := _place_enemy(Vector3(3, 0, 0), Vector3.LEFT, true)
	_place_player(Vector3(-2, 0, 0), Vector3.RIGHT)
	var start_distance := e.global_position.distance_to(player.global_position)
	var sequence: Array[String] = []
	var ticks_in: Dictionary = {}
	var distance_at_windup := -1.0
	var attack_position := Vector3.ZERO
	var drift := 0.0
	for i in 300:
		await _ticks(1)
		var label := _enemy_label(e)
		if sequence.is_empty() or sequence[sequence.size() - 1] != label:
			sequence.append(label)
			if label == "WINDUP":
				distance_at_windup = e.global_position.distance_to(player.global_position)
		ticks_in[label] = int(ticks_in.get(label, 0)) + 1
		# Ab der Richtungsfestlegung: kein Verfolgen (Auslaufen aus dem Lauf davor ist erlaubt).
		if e.is_committed():
			if attack_position == Vector3.ZERO:
				attack_position = e.global_position
			drift = maxf(drift, e.global_position.distance_to(attack_position))
		else:
			attack_position = Vector3.ZERO
		if sequence.size() >= 2 and sequence[sequence.size() - 2] == "RECOVERY":
			break
	print("    Ablauf: %s · Ticks WINDUP %d / ACTIVE %d / RECOVERY %d" % [" → ".join(sequence),
			ticks_in.get("WINDUP", 0), ticks_in.get("ACTIVE", 0), ticks_in.get("RECOVERY", 0)])
	var joined := " ".join(sequence)
	_check(joined.contains("CHASE WINDUP ACTIVE RECOVERY"), "Ablauf Annäherung → Windup → Active → Recovery fehlt: %s" % joined)
	_check(start_distance > 4.0 and distance_at_windup <= e.tuning.attack_start_distance + 0.05, "Angriff nicht erst in Reichweite (%.2f m)" % distance_at_windup)
	var data := e.weapon.data
	_check(absi(int(ticks_in.get("WINDUP", 0)) - roundi(data.windup * 60)) <= 1, "Windup-Dauer weicht ab")
	_check(absi(int(ticks_in.get("ACTIVE", 0)) - roundi(data.active * 60)) <= 1, "Active-Dauer weicht ab")
	_check(absi(int(ticks_in.get("RECOVERY", 0)) - roundi(data.recovery * 60)) <= 1, "Recovery-Dauer weicht ab")
	_check(drift < 0.03, "Gegner bewegt sich nach der Festlegung (%.2f m)" % drift)


func test_e2_no_contact_damage_only_active() -> void:
	# Reiner Körperkontakt: Spieler drückt 1,5 s gegen den Gegner (KI ohne Ziel).
	var e := _place_enemy(Vector3(2.0, 0, 0), Vector3.LEFT, false)
	_gamepad_mode()
	_place_player(Vector3(-0.5, 0, 0), Vector3.RIGHT)
	_set_stick(_stick_for_world(Vector3.RIGHT))
	await _ticks(90)
	_check(player.global_position.distance_to(e.global_position) < 0.85, "Kein Körperkontakt hergestellt")
	_check(is_equal_approx(player.hp, player.tuning.max_hp), "Körperkontakt verursacht Schaden")
	# Mit aktiver KI 5 s im Nahkampf bleiben: Schaden ausschließlich während ACTIVE.
	var events: Array = []
	player.damaged.connect(func(hit: HitInfo) -> void: events.append([e.weapon.phase, hit.swing_id]))
	e.target = player
	for i in 300:
		var to := e.global_position - player.global_position
		to.y = 0
		_set_stick(_stick_for_world(to.normalized()) * 0.5 if to.length() > 0.9 else Vector2.ZERO)
		await _ticks(1)
		if player.state == PlayerController.State.DEAD:
			break
	_set_stick(Vector2.ZERO)
	_check(events.size() >= 2, "Zu wenige Gegnertreffer für die Prüfung (%d)" % events.size())
	var swing_ids := {}
	for ev: Array in events:
		_check(ev[0] == WeaponController.Phase.ACTIVE, "Schaden außerhalb von ACTIVE (Phase %s)" % WeaponController.Phase.keys()[ev[0]])
		swing_ids[ev[1]] = true
	_check(swing_ids.size() == events.size(), "Mehr als ein Treffer pro gegnerischem Angriff")


func test_e3_one_hit_per_enemy_attack() -> void:
	var e := _place_enemy(Vector3(0, 0, 0), Vector3.FORWARD, false)
	_place_player(Vector3(0, 0, -1.0), Vector3.BACK)
	await _ticks(2)
	var count := [0]
	player.damaged.connect(func(_hit: HitInfo) -> void: count[0] += 1)
	await _enemy_attack_until_active(e)
	# Spieler während des gesamten Trefferfensters im Sektor halten.
	while e.weapon.phase == WeaponController.Phase.ACTIVE:
		player.global_position = Vector3(0, 0, -1.0)
		await _ticks(1)
	await _await_enemy_weapon_idle(e)
	_check(count[0] == 1, "Ein gegnerischer Angriff trifft %d-mal" % count[0])
	_check(is_equal_approx(player.hp, player.tuning.max_hp - e.weapon.data.damage), "HP nach einem Treffer: %.0f" % player.hp)


func test_e4_no_retarget_after_commit() -> void:
	var e := _place_enemy(Vector3(1.3, 0, 0), Vector3.LEFT, true)
	_place_player(Vector3(0, 0, 0), Vector3.RIGHT)
	while e.state != Scrapling.State.ATTACK:
		await _ticks(1)
	var initial := e.weapon.direction
	# Vor der Festlegung seitlich versetzen: Richtung folgt noch.
	player.global_position = Vector3(0.5, 0, 0.9)
	while not e.is_committed():
		await _ticks(1)
	var committed := e.weapon.direction
	_check(rad_to_deg(committed.angle_to(initial)) > 10.0, "Windup verfolgt vor der Festlegung nicht (%.1f°)" % rad_to_deg(committed.angle_to(initial)))
	var yaw := e.rotation.y
	# Nach der Festlegung auf die andere Seite ausweichen: kein Nachdrehen, kein Verfolgen.
	var dodge_position := Vector3(0.5, 0, -0.9)
	player.global_position = dodge_position
	var position := e.global_position
	var expect_hit := WeaponController.is_in_sector(e.weapon.attack_origin.global_position, committed, dodge_position,
			player.hit_radius, e.weapon.data.attack_range, e.weapon.data.arc_degrees, e.weapon.data.max_height_difference)
	_check(not expect_hit, "Testaufbau: Ausweichposition liegt im festgelegten Sektor")
	while e.weapon.phase != WeaponController.Phase.RECOVERY:
		await _ticks(1)
		_check(e.weapon.direction.distance_to(committed) < 0.0001, "Gegnerischer Sektor dreht nach der Festlegung")
		_check(absf(angle_difference(e.rotation.y, yaw)) < 0.001, "Gegner dreht nach der Festlegung")
	_check(e.global_position.distance_to(position) < 0.02, "Gegner verfolgt während des Schlags")
	_check(is_equal_approx(player.hp, player.tuning.max_hp), "Ausgewichener Spieler dennoch getroffen")


## Führt einen festen Gegnerangriff (Gegner im Ursprung, Blick -Z) gegen einen Spieler an offset aus.
func _enemy_hits_player_at(offset: Vector3, height_at_active: float = 0.0) -> bool:
	var e := _place_enemy(Vector3.ZERO, Vector3.FORWARD, false)
	_place_player(offset, Vector3.BACK)
	player.hp = player.tuning.max_hp
	await _ticks(3)
	e.start_attack()
	# Der Gegner verarbeitet vor dem Spieler und prüft schon im Übergangstick: einen Tick vorher anheben.
	while e.weapon.phase == WeaponController.Phase.WINDUP and (1.0 - e.weapon.phase_progress()) * e.weapon.data.windup > 1.5 * DT:
		await _ticks(1)
	if height_at_active > 0.0:
		player.global_position = Vector3(offset.x, height_at_active, offset.z)
		player.velocity = Vector3.ZERO
	while e.weapon.phase == WeaponController.Phase.WINDUP:
		await _ticks(1)
	while e.weapon.phase == WeaponController.Phase.ACTIVE:
		await _ticks(1)
	var hit := player.hp < player.tuning.max_hp
	await _await_enemy_weapon_idle(e)
	await _ticks(40)
	return hit


func test_e5_enemy_range_angle_height() -> void:
	var data: WeaponData = arena.enemy.weapon.data
	var r := player.hit_radius
	var o := Vector3(0, 0.6, 0)
	var f := Vector3.FORWARD
	_check(WeaponController.is_in_sector(o, f, Vector3(0, 0, -1.5), r, data.attack_range, data.arc_degrees, data.max_height_difference), "Reichweite: 1,5 m nicht im Sektor")
	_check(not WeaponController.is_in_sector(o, f, Vector3(0, 0, -1.7), r, data.attack_range, data.arc_degrees, data.max_height_difference), "Reichweite: 1,7 m im Sektor")
	_check(not WeaponController.is_in_sector(o, f, Vector3(1.0, 0, 0), r, data.attack_range, data.arc_degrees, data.max_height_difference), "90°-Seite im Sektor")
	_check(not WeaponController.is_in_sector(o, f, Vector3(0, 2.0, -1.0), r, data.attack_range, data.arc_degrees, data.max_height_difference), "Höhenunterschied im Sektor")
	var cases: Array = [
		[Vector3(0, 0, -1.4), 0.0, true, "vorne innerhalb"],
		[Vector3(0.866, 0, -0.5), 0.0, true, "60° innerhalb"],
		[Vector3(0, 0, -1.75), 0.0, false, "vorne zu weit"],
		[Vector3(1.0, 0, 0), 0.0, false, "90° seitlich"],
		[Vector3(0, 0, 1.0), 0.0, false, "hinten"],
		[Vector3(0, 0, -1.0), 2.2, false, "zu hoch (in der Luft)"],
	]
	for c: Array in cases:
		var hit: bool = await _enemy_hits_player_at(c[0], c[1])
		_check(hit == c[2], "Gegnertreffer %s: %s (erwartet %s)" % [c[3], hit, c[2]])


func test_e6_dodge_iframes_block_damage_and_knockback() -> void:
	var e := _place_enemy(Vector3.ZERO, Vector3.FORWARD, false)
	_gamepad_mode()
	# Dodge auf der Stelle (nur für diesen Test), damit ausschließlich die iFrames wirken.
	player.tuning = player.tuning.duplicate()
	player.tuning.dodge_speed = 0.0
	_place_player(Vector3(0, 0, -1.0), Vector3.BACK)
	await _ticks(3)
	var evaded_speed: Array[float] = []
	var damage_elapsed: Array[float] = []
	player.hit_evaded.connect(func(_hit: HitInfo) -> void: evaded_speed.append(Vector2(player.velocity.x, player.velocity.z).length()))
	player.damaged.connect(func(_hit: HitInfo) -> void: damage_elapsed.append(player._dodge_elapsed))
	e.start_attack()
	while e.weapon.phase == WeaponController.Phase.WINDUP and (1.0 - e.weapon.phase_progress()) * e.weapon.data.windup > 5.0 * DT:
		await _ticks(1)
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await _ticks(2)
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	var hp_during_iframes := player.hp
	while e.weapon.phase != WeaponController.Phase.RECOVERY and e.weapon.is_busy():
		await _ticks(1)
		if player.is_invulnerable():
			_check(player.hp == hp_during_iframes, "Schaden während der iFrames")
	print("    Abgewehrte Trefferprüfungen: %d, Treffer nach iFrames bei Dodge-Zeit %s" % [evaded_speed.size(), damage_elapsed])
	_check(evaded_speed.size() >= 1, "iFrames haben keinen Treffer abgewehrt")
	for speed in evaded_speed:
		_check(speed < 0.01, "Knockback trotz iFrames")
	for elapsed in damage_elapsed:
		_check(elapsed > player.tuning.dodge_iframe_end or elapsed < player.tuning.dodge_iframe_start, "Treffer innerhalb des iFrame-Fensters")
	# Vergleich ohne Dodge in gleicher Lage: normaler Treffer.
	await _await_enemy_weapon_idle(e)
	await _ticks(20)
	var hit: bool = await _enemy_hits_player_at(Vector3(0, 0, -1.0))
	_check(hit, "Ohne Dodge kein Treffer (Vergleich)")


func test_e7_valid_hit_hp_and_knockback() -> void:
	var e := _place_enemy(Vector3.ZERO, Vector3.FORWARD, false)
	_gamepad_mode()
	_place_player(Vector3(0, 0, -1.0), Vector3.BACK)
	await _ticks(3)
	await _enemy_attack_until_active(e)
	# Spieler drückt während des Treffers weiter zum Gegner (+Z).
	_set_stick(_stick_for_world(Vector3.BACK))
	while player.state != PlayerController.State.HIT and e.weapon.phase == WeaponController.Phase.ACTIVE:
		await _ticks(1)
	_check(player.state == PlayerController.State.HIT, "Kein Trefferzustand")
	var start_z := player.global_position.z
	var last := player.global_position
	var max_step := 0.0
	var hit_ticks := 0
	while player.state == PlayerController.State.HIT:
		await _ticks(1)
		max_step = maxf(max_step, player.global_position.distance_to(last))
		last = player.global_position
		hit_ticks += 1
	var pushed := start_z - player.global_position.z
	print("    Spieler-Knockback: %.2f m in %d Ticks, max. %.3f m/Tick" % [pushed, hit_ticks, max_step])
	_check(is_equal_approx(player.hp, player.tuning.max_hp - e.weapon.data.damage), "HP nicht um den Schaden reduziert")
	_check(pushed > 0.3, "Knockback von Laufeingabe überschrieben (%.2f m)" % pushed)
	_check(max_step <= e.weapon.data.knockback_speed / 60.0 * 1.05, "Knockback-Sprung (Teleport?)")
	# Danach normale Steuerung: Spieler läuft wieder auf den Gegner zu (bis zum Körperkontakt).
	var after_hit_z := player.global_position.z
	await _ticks(20)
	_check(player.state == PlayerController.State.MOVE and player.global_position.z - after_hit_z > 0.3, "Nach dem Treffer keine normale Steuerung")
	_set_stick(Vector2.ZERO)


func test_e8_interrupted_attacks_never_hit_late() -> void:
	# a) Gegnerangriff im Windup durch Hammertreffer unterbrochen.
	var e := _place_enemy(Vector3.ZERO, Vector3.FORWARD, false)
	_place_player(Vector3(0, 0, -1.0), Vector3.BACK)
	await _ticks(3)
	e.start_attack()
	while e.weapon.phase_progress() < 0.5:
		await _ticks(1)
	var hit := HitInfo.new()
	hit.damage = 20.0
	hit.knockback_velocity = Vector3(0, 0, 0.5)
	hit.knockback_duration = 0.1
	e.receive_hit(hit)
	_check(not e.weapon.is_busy() and e.state == Scrapling.State.HIT, "Gegnerangriff nicht unterbrochen")
	for i in 90:
		player.global_position = Vector3(0, 0, -1.0)
		await _ticks(1)
	_check(is_equal_approx(player.hp, player.tuning.max_hp), "Unterbrochener Gegnerangriff trifft nachträglich")
	# b) Eigener Angriff durch Gegnertreffer unterbrochen: kein Treffer, kein früherer Folgeangriff.
	e = _place_enemy(Vector3.ZERO, Vector3.FORWARD, false)
	e.hp = e.tuning.max_hp
	_gamepad_mode()
	_place_player(Vector3(0, 0, -1.2), Vector3.BACK)
	await _ticks(3)
	var starts: Array[int] = []
	var tick := [0]
	player.weapon.swing_started.connect(func(_id: int, _dir: Vector3) -> void: starts.append(tick[0]))
	var enemy_hp_at_second_swing := [-1.0]
	e.start_attack()
	while (1.0 - e.weapon.phase_progress()) * e.weapon.data.windup > 0.1:
		await _ticks(1)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	for i in 72:
		tick[0] = i
		await _ticks(1)
		if starts.size() == 2 and enemy_hp_at_second_swing[0] < 0.0:
			enemy_hp_at_second_swing[0] = e.hp
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_check(player.hp < player.tuning.max_hp, "Testaufbau: Spieler wurde nicht getroffen")
	_check(starts.size() >= 2, "Kein Folgeangriff bei gehaltenem RT")
	if starts.size() >= 2:
		_check((starts[1] - starts[0]) * DT >= player.weapon.data.total_duration() - 0.0001, "Unterbrechung ermöglicht früheren Folgeangriff")
		_check(is_equal_approx(enemy_hp_at_second_swing[0], e.tuning.max_hp), "Unterbrochener Spielerangriff hat nachträglich getroffen")


func test_e9_enemy_defeat_once_hp_and_fall() -> void:
	var finished: Array[bool] = []
	arena.encounter_finished.connect(func(victory: bool) -> void: finished.append(victory))
	var e := _place_enemy(Vector3(0, 0, -2), Vector3.BACK, false)
	var hit := HitInfo.new()
	hit.damage = 20.0
	hit.knockback_duration = 0.01
	for i in 4:
		e.receive_hit(hit)
		await _ticks(5)
	_check(e.defeat_count == 1 and e.last_defeat_reason == Scrapling.DefeatReason.HP, "HP-Niederlage nicht genau einmal")
	_check(finished == [true] and arena.encounter == TrainingArena.Encounter.VICTORY, "Sieg nicht genau einmal gemeldet")
	_check(not e.receive_hit(hit), "Besiegter Gegner nimmt weitere Treffer")
	e.global_position = Vector3(0, arena.kill_height - 1.0, -2)
	await _ticks(2)
	_check(e.defeat_count == 1 and finished.size() == 1, "Tödlich getroffener Gegner zählt beim Fall doppelt")
	_check(not e.weapon.is_busy() and e.state == Scrapling.State.DEFEATED, "Besiegter Gegner handelt weiter")
	# Neue Runde: Gegner an der Kante trotz Bodenprüfung per Hammer herunterschlagen.
	arena.restart()
	await _ticks(2)
	e = _place_enemy(Vector3(5.9, 0, 0), Vector3.LEFT, true)
	_gamepad_mode()
	_place_player(Vector3(4.6, 0, 0), Vector3.RIGHT)
	await _single_rt_attack()
	for i in 150:
		await _ticks(1)
		if e.is_defeated:
			break
	_check(e.is_defeated and e.last_defeat_reason == Scrapling.DefeatReason.FALL, "Gegner nicht über die Kante besiegt")
	_check(e.defeat_count == 1 and finished == [true, true], "Kanten-Niederlage nicht genau einmal (%s)" % [finished])


func test_e10_edge_probe_stops_chase_only() -> void:
	var e := _place_enemy(Vector3(3, 0, 0), Vector3.RIGHT, true)
	# Spieler „schwebt“ eingefroren jenseits der Kante: Verfolgung darf nicht über den Rand führen.
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.global_position = Vector3(9.0, 0, 0)
	for i in 240:
		await _ticks(1)
	player.process_mode = Node.PROCESS_MODE_INHERIT
	print("    Gegner stoppt bei x = %.2f (Kante 6,5)" % e.global_position.x)
	_check(e.global_position.x > 5.0 and e.global_position.x < 6.5, "Gegner nicht bis vor die Kante gelaufen (x %.2f)" % e.global_position.x)
	_check(e.global_position.y > -0.05 and not e.is_defeated, "Gegner läuft bei Verfolgung über die Kante")
	_check(e.state == Scrapling.State.CHASE, "Gegner verlässt die Verfolgung")


func test_e11_player_death_and_clean_restart() -> void:
	var e := arena.enemy
	var overlay: EncounterOverlay = main.get("result_overlay")
	var deaths := [0]
	player.died.connect(func() -> void: deaths[0] += 1)
	player.hp = 10.0
	for i in 480:
		await _ticks(1)
		if player.state == PlayerController.State.DEAD:
			break
	_check(player.state == PlayerController.State.DEAD and deaths[0] == 1, "Spielertod nicht genau einmal")
	_check(arena.encounter == TrainingArena.Encounter.DEFEAT, "Niederlage nicht gesetzt")
	var attacked_after := false
	for i in 40:
		await _ticks(1)
		attacked_after = attacked_after or e.state == Scrapling.State.ATTACK or player.state != PlayerController.State.DEAD
	_check(not attacked_after and not e.weapon.is_busy(), "Kampf läuft nach Spielertod weiter")
	await _ticks(40)
	_check(overlay.is_open() and get_tree().paused, "Niederlage-Anzeige nicht sichtbar")
	# Neustart über den Button (Mausklick): kein Weltangriff durch den Klick.
	var swing_id := player.weapon.swing_id
	var button: Button = overlay.get_node("Dim/Center/Panel/Margin/VBox/RestartButton")
	var center := button.get_global_rect().get_center()
	_mouse_button(MOUSE_BUTTON_LEFT, true, center)
	_mouse_button(MOUSE_BUTTON_LEFT, false, center)
	await _ticks(10)
	_check(not overlay.is_open() and not get_tree().paused, "Neustart schließt die Anzeige nicht")
	_check(player.state == PlayerController.State.MOVE and is_equal_approx(player.hp, player.tuning.max_hp), "Spieler nicht zurückgesetzt")
	_check(player.global_position.distance_to(arena.combat_player_spawn.global_position) < 0.3, "Spieler nicht am Kampf-Spawn")
	_check(is_equal_approx(e.hp, e.tuning.max_hp) and not e.is_defeated and not e.weapon.is_busy(), "Gegner nicht zurückgesetzt")
	_check(e.global_position.distance_to(arena.enemy_spawn.global_position) < 0.3, "Gegner nicht am Start")
	_check(arena.encounter == TrainingArena.Encounter.RUNNING, "Begegnung läuft nicht wieder")
	_check(arena.effects.get_child_count() == 0, "Alte Effekte in der neuen Runde")
	_check(player.weapon.swing_id == swing_id and not InputRouter.attack_held, "Klick auf Neustart löst Angriff aus")


func test_e12_player_fall_resets_encounter() -> void:
	var e := arena.enemy
	var hit := HitInfo.new()
	hit.damage = 20.0
	hit.knockback_duration = 0.01
	e.receive_hit(hit)
	var restarts := [0]
	arena.restarted.connect(func() -> void: restarts[0] += 1)
	_gamepad_mode()
	_place_player(Vector3(5.5, 0, 3.0), Vector3.RIGHT)
	_set_stick(_stick_for_world(Vector3.RIGHT))
	for i in 200:
		await _ticks(1)
		if player.state == PlayerController.State.OUT:
			break
	_set_stick(Vector2.ZERO)
	_check(player.state == PlayerController.State.OUT, "Spieler nicht gefallen")
	while player.state == PlayerController.State.OUT:
		_check(e.state != Scrapling.State.ATTACK, "Gegner greift während des Spielerfalls an")
		await _ticks(1)
	await _ticks(2)
	_check(restarts[0] == 1, "Spielerfall setzt die Begegnung %d-mal zurück" % restarts[0])
	_check(is_equal_approx(e.hp, e.tuning.max_hp) and e.global_position.distance_to(arena.enemy_spawn.global_position) < 0.3, "Gegner nach Spielerfall nicht zurückgesetzt")
	_check(player.global_position.distance_to(arena.combat_player_spawn.global_position) < 0.3, "Spieler nicht am Kampf-Spawn")
	_check(arena.encounter == TrainingArena.Encounter.RUNNING, "Begegnung läuft nach Spielerfall nicht")


func test_e13_mode_switch_and_pause_release_inputs() -> void:
	_gamepad_mode()
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _ticks(3)
	_check(InputRouter.attack_held, "RT gehalten nicht erkannt")
	var swings := [0]
	player.weapon.swing_started.connect(func(_id: int, _dir: Vector3) -> void: swings[0] += 1)
	var pause_menu: PauseMenu = main.get("pause_menu")
	pause_menu.open()
	await get_tree().process_frame
	await get_tree().process_frame
	var mode_button: Button = pause_menu.get_node("Dim/Center/Panel/Margin/VBox/ModeButton")
	var center := mode_button.get_global_rect().get_center()
	_mouse_button(MOUSE_BUTTON_LEFT, true, center)
	_mouse_button(MOUSE_BUTTON_LEFT, false, center)
	var swings_before: int = swings[0]
	await _ticks(30)
	_check(arena.mode == TrainingArena.Mode.TRAINING, "Moduswahl per Button wechselt nicht")
	_check(not get_tree().paused and not pause_menu.is_open(), "Pause nach Moduswechsel nicht aufgehoben")
	_check(not InputRouter.attack_held and swings[0] == swings_before, "Moduswechsel hinterlässt gehaltene Eingaben / Klick greift an")
	var visible_dummies := 0
	for d in arena.dummies:
		if d.visible and d.collision_layer != 0:
			visible_dummies += 1
	_check(visible_dummies == 3, "Trainingsdummies im Training nicht aktiv (%d)" % visible_dummies)
	var e := arena.enemy
	_check(not e.visible and e.state == Scrapling.State.INACTIVE and e.collision_layer == 0, "Gegner im Training aktiv")
	_check(player.global_position.distance_to(arena.player_spawn.global_position) < 0.3, "Spieler nicht am Trainings-Spawn")
	main.call("toggle_mode")
	await _ticks(3)
	_check(arena.mode == TrainingArena.Mode.COMBAT and e.visible and e.state != Scrapling.State.INACTIVE, "Rückwechsel in den Kampf fehlt")
	for d in arena.dummies:
		_check(not d.visible and d.process_mode == Node.PROCESS_MODE_DISABLED, "Dummy steht im Kampfmodus herum")
	_check(is_equal_approx(e.hp, e.tuning.max_hp) and arena.encounter == TrainingArena.Encounter.RUNNING, "Begegnung nach Moduswechsel nicht frisch")


## Playtest-Messung (kein Balance-Urteil): Spieler hält RT und drückt Richtung Gegner.
## Dokumentiert, ob Dauerschlagen den Scrapling dauerhaft unterbricht.
func test_e14_probe_held_attack_pressure() -> void:
	var e := arena.enemy
	_gamepad_mode()
	var enemy_swings := [0]
	var enemy_actives := [0]
	var enemy_hits_taken := [0]
	var last_phase := [e.weapon.phase]
	e.weapon.swing_started.connect(func(_id: int, _dir: Vector3) -> void: enemy_swings[0] += 1)
	var player_damage := [0]
	player.damaged.connect(func(_hit: HitInfo) -> void: player_damage[0] += 1)
	player.hit_landed.connect(func(target: Node3D, _p: Vector3) -> void:
		if target == e:
			enemy_hits_taken[0] += 1)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	var ticks := 0
	for i in 1200:
		var to := e.global_position - player.global_position
		to.y = 0
		_set_stick(_stick_for_world(to.normalized()) if to.length() > 1.3 else Vector2.ZERO)
		await _ticks(1)
		ticks = i
		if e.weapon.phase == WeaponController.Phase.ACTIVE and last_phase[0] != WeaponController.Phase.ACTIVE:
			enemy_actives[0] += 1
		last_phase[0] = e.weapon.phase
		if arena.encounter != TrainingArena.Encounter.RUNNING:
			break
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_set_stick(Vector2.ZERO)
	print("    Dauerschlagen: Ergebnis %s nach %.1f s · Hammertreffer %d · Gegner-Windups %d, davon ACTIVE %d · Spielertreffer %d · Spieler-HP %d" % [
			TrainingArena.Encounter.keys()[arena.encounter], ticks * DT, enemy_hits_taken[0], enemy_swings[0],
			enemy_actives[0], player_damage[0], int(player.hp)])
	_check(arena.encounter != TrainingArena.Encounter.RUNNING, "Begegnung in 20 s nicht entschieden")
