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
	# Headless startet mit quadratischem Fenster; für Sichtbarkeitsregeln das Zielformat 16:9 verwenden.
	get_window().size = Vector2i(1280, 720)
	await get_tree().process_frame
	print("Testfenster: %s" % get_viewport().get_visible_rect().size)
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
		"test_g1_three_independent_enemies",
		"test_g2_stun_profiles_do_not_share_tuning",
		"test_g3_hammer_hits_multiple_enemies_once",
		"test_g4_simultaneous_enemy_hits_attributed_separately",
		"test_g5_victory_only_after_all_mixed_kills",
		"test_g6_death_fall_reset_mode_cleanup",
		"test_g7_no_damage_from_old_or_interrupted_attacks",
		"test_g8_edge_probe_with_separation_and_knockback_fall",
		"test_g9_player_movement_and_cadence_unchanged",
		"test_d1_diag_duel_hold_forward_a",
		"test_d2_diag_duel_hold_forward_b",
		"test_d3_diag_group_hold_forward_a",
		"test_d4_diag_group_hold_forward_b",
		"test_d5_diag_group_hold_forward_edge_aware_a",
		"test_d6_diag_group_hold_forward_edge_aware_b",
		"test_d7_diag_group_timing_sensitivity",
		"test_x1_mixed_start_and_default_profile",
		"test_x2_charge_fire_recover_cycle",
		"test_x3_no_retarget_after_commit",
		"test_x4_interrupted_charge_never_fires_late",
		"test_x5_fired_bolt_survives_shooter_defeat",
		"test_x6_projectile_contact_rules",
		"test_x7_defeats_and_victory_after_all_three",
		"test_x8_pause_restart_mode_cleanup",
		"test_x9_player_values_and_movement_unchanged",
		"test_x10_mixed_hit_chain_documented",
		"test_d8_diag_mixed_hold_forward_b",
		"test_d9_diag_mixed_shooter_first_b",
		"test_y1_sharp_shot_profile_values_and_cycle",
		"test_d10_diag_mixed_hold_forward_sharp_b",
		"test_d11_diag_mixed_dodge_reaction_window",
		"test_z1_descent_start_layout_and_cycle",
		"test_z2_hatch_opens_after_clear_and_walk_in_without_damage",
		"test_z3_edge_fall_skips_floor1_with_fall_damage",
		"test_z4_edge_fall_after_clear_still_damages",
		"test_z5_lethal_fall_damage_is_defeat",
		"test_z6_fall_on_floor2_is_defeat_and_restart_returns_to_floor1",
		"test_z7_floor2_victory_once_including_shaft_fall",
		"test_z8_lower_enemies_walk_around_shaft",
		"test_z9_upper_enemy_fall_never_reaches_floor2",
		"test_z10_diag_edge_fall_is_vertical",
	]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			tests = PackedStringArray(Array(tests).filter(func(t: String) -> bool: return t.contains(arg.trim_prefix("--only="))))
	for test_name in tests:
		_current = test_name
		var before := _failures.size()
		# M1/M1.1-Regressionen im Training, M2A-Tests (test_e…) im Duell mit Basisprofil A,
		# M2B-Tests (test_g…) in der Gruppe; Diagnosen (test_d…) nach Namen (duel/group, Endung _b = Profil B).
		# M2C-Tests (test_x…) im Mischkampf mit Profil B; test_x1 prüft den unveränderten Standard (kein Profil gesetzt).
		var mode := TrainingArena.Mode.TRAINING
		if test_name.begins_with("test_e") or test_name.contains("_duel_"):
			mode = TrainingArena.Mode.COMBAT
		elif test_name.begins_with("test_g") or test_name.contains("_group_"):
			mode = TrainingArena.Mode.GROUP
		elif test_name.begins_with("test_x") or test_name.begins_with("test_y") or test_name.contains("_mixed_"):
			mode = TrainingArena.Mode.MIXED
		elif test_name.begins_with("test_z"):
			mode = TrainingArena.Mode.DESCENT  # Abstieg mit dem aktuellen Standard (Profil B, Schuss scharf)
		var profile: int = TrainingArena.StunProfile.SHORT if test_name.ends_with("_b") or test_name.begins_with("test_x") or test_name.begins_with("test_z") else TrainingArena.StunProfile.BASE
		# Funkenwerfer-Schussprofil: bestehende Tests ausdrücklich Standard, test_y…/…_sharp… Scharf.
		var shot: int = TrainingArena.ShotProfile.SHARP if test_name.begins_with("test_y") or test_name.begins_with("test_z") or test_name.contains("_sharp") else TrainingArena.ShotProfile.STANDARD
		if test_name.contains("default_profile"):
			profile = -1
			shot = -1
		await _setup(mode, profile, shot)
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


## profile/shot < 0: nicht setzen (Standard der Hauptszene prüfen).
func _setup(mode: TrainingArena.Mode, profile: int, shot: int = TrainingArena.ShotProfile.STANDARD) -> void:
	get_tree().paused = false
	InputRouter.set_touch_test_mode(false)
	InputRouter._switch_source(InputRouter.Source.KEYBOARD_MOUSE)
	InputRouter.release_all()
	InputRouter.mouse_aim_valid = false
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)
	main = MAIN_SCENE.instantiate()
	main.set("start_mode", mode)
	if profile >= 0:
		main.set("start_profile", profile)
	if shot >= 0:
		main.set("start_shot_profile", shot)
	main.set("write_log", false)
	# Der Testläufer läuft immer (PROCESS_MODE_ALWAYS); die Hauptszene muss wie im echten Spiel pausierbar sein.
	main.process_mode = Node.PROCESS_MODE_PAUSABLE
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
	# Mindestbewegung relativ zur Fensterhöhe (unabhängig von der Testfenstergröße).
	_check(delta.y < -0.015 * get_viewport().get_visible_rect().size.y, "W bewegt nicht bildschirm-oben (dy=%.1f)" % delta.y)
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
	# Alle aktiven statischen Kollisionsformen liegen innerhalb der Plattform (Teilflächen + geschlossene Luke);
	# die untere Ebene des Abstiegs ist in den anderen Szenarien ohne Kollision.
	var shapes := arena.find_children("*", "CollisionShape3D", true, false).filter(
			func(s: Node) -> bool: return s.get_parent() is StaticBody3D and (s.get_parent() as StaticBody3D).collision_layer != 0)
	_check(shapes.size() > 0, "Keine Plattform-Collider")
	for node: CollisionShape3D in shapes:
		var box := node.shape as BoxShape3D
		var c := node.global_position
		_check(box != null and absf(c.x) + box.size.x * 0.5 <= 6.501 and absf(c.z) + box.size.z * 0.5 <= 5.001
				and c.y + box.size.y * 0.5 <= 0.001, "Collider außerhalb der Plattform: %s" % node.get_path())
	# Die Plattform ist lückenlos begehbar (auch über der geschlossenen Luke).
	var gaps := 0
	for gx in range(-12, 13):
		for gz in range(-9, 10):
			var p := Vector3(gx * 0.5, 0, gz * 0.5)
			var down := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 3, p + Vector3.DOWN * 3, world_mask))
			if down.is_empty() or absf(down["position"].y) > 0.01:
				gaps += 1
	_check(gaps == 0, "Plattform hat %d Lücken" % gaps)
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
	main.call("set_mode", TrainingArena.Mode.COMBAT)
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



# --- M2B: Gruppenkampf und Profile ------------------------------------------------

## Setzt einen beliebigen Gegner der Gruppe an eine Position (ohne Ziel: KI bleibt IDLE).
func _put_enemy(e: Scrapling, pos: Vector3, facing: Vector3, with_target: bool = false) -> void:
	e.weapon.cancel()
	e.target = player if with_target else null
	e.state = Scrapling.State.IDLE
	e.global_position = Vector3(pos.x, 0.0, pos.z)
	e.velocity = Vector3.ZERO
	e.rotation.y = PlayerController.yaw_for_direction(facing.normalized())


func _calm_all_enemies() -> void:
	for e in arena.active_enemies:
		e.stop_combat()


func _hammer_hit(direction: Vector3) -> HitInfo:
	var hit := HitInfo.new()
	hit.damage = player.weapon.data.damage
	hit.knockback_velocity = direction.normalized() * player.weapon.data.knockback_speed
	hit.knockback_duration = player.weapon.data.knockback_duration
	return hit


func test_g1_three_independent_enemies() -> void:
	_check(arena.active_enemies.size() == 3, "Gruppe hat %d aktive Gegner" % arena.active_enemies.size())
	var distances: Array[float] = []
	for e in arena.active_enemies:
		_check(e.visible and e.state != Scrapling.State.INACTIVE and e.target == player, "Gegner %s nicht aktiv" % e.name)
		_check(e.neighbors.size() == 2 and not e.neighbors.has(e), "Nachbarliste von %s falsch" % e.name)
		var d := e.global_position.distance_to(player.global_position)
		distances.append(d)
		_check(d > e.tuning.attack_start_distance + 1.5, "%s startet zu nah (%.2f m)" % [e.name, d])
		_check(absf(e.global_position.x) < 6.5 - 1.2 and absf(e.global_position.z) < 5.0 - 1.2, "%s startet an der Kante" % e.name)
		_check(camera.is_position_in_frustum(e.global_position + Vector3.UP * 0.6), "%s zu Beginn nicht im Kamerabild" % e.name)
	distances.sort()
	_check(distances[2] - distances[0] > 0.3, "Startdistanzen nicht unterschiedlich: %s" % [distances])
	var weapons := {}
	var swings := {}
	for e in arena.active_enemies:
		weapons[e.weapon.get_instance_id()] = true
		swings[e.name] = 0
		var enemy_name := e.name
		e.weapon.swing_started.connect(func(_id: int, _dir: Vector3) -> void: swings[enemy_name] += 1)
	_check(weapons.size() == 3, "Gegner teilen sich eine Waffe")
	player.hp = 100000.0  # Spieler überlebt die Beobachtung
	var min_pair := 100.0
	for i in 360:
		await _ticks(1)
		for a in 3:
			for b in range(a + 1, 3):
				var ea := arena.active_enemies[a]
				var eb := arena.active_enemies[b]
				min_pair = minf(min_pair, Vector2(ea.global_position.x - eb.global_position.x, ea.global_position.z - eb.global_position.z).length())
	print("    Angriffe je Gegner in 6 s: %s · minimaler Gegnerabstand %.2f m (Kapselkontakt 0,76 m)" % [swings, min_pair])
	for enemy_name in swings:
		_check(int(swings[enemy_name]) >= 1, "%s greift nicht eigenständig an" % enemy_name)
	_check(min_pair > 0.8, "Gegner überlagern sich (%.2f m)" % min_pair)
	# Duell: nur ein Gegner aktiv, keine Abstandshaltung.
	main.call("set_mode", TrainingArena.Mode.COMBAT)
	await _ticks(2)
	_check(arena.active_enemies.size() == 1 and arena.enemy.neighbors.is_empty(), "Duell nutzt Gruppenlogik")
	for e in arena.enemies:
		if e != arena.enemy:
			_check(not e.visible and e.state == Scrapling.State.INACTIVE and e.collision_layer == 0, "Zusätzlicher Gegner im Duell aktiv")


func test_g2_stun_profiles_do_not_share_tuning() -> void:
	var shared: ScraplingTuning = arena.enemy.tuning
	var fresh := ResourceLoader.load("res://resources/tuning/scrapling_tuning.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as ScraplingTuning
	for e in arena.active_enemies:
		_check(e.tuning == shared and is_equal_approx(e.hit_stun, 0.4), "Profil A: Benommenheit %.2f" % e.hit_stun)
	var restarts := [0]
	arena.restarted.connect(func() -> void: restarts[0] += 1)
	main.call("set_profile", TrainingArena.StunProfile.SHORT)
	await _ticks(2)
	_check(restarts[0] == 1, "Profilwechsel ohne Neustart")
	for e in arena.active_enemies:
		_check(is_equal_approx(e.hit_stun, 0.2), "Profil B: Benommenheit %.2f" % e.hit_stun)
	# Die geteilte Ressource ist unverändert und gleicht der Datei in allen Werten.
	for prop in shared.get_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			_check(shared.get(prop["name"]) == fresh.get(prop["name"]), "Tuningwert %s geändert" % prop["name"])
	var cleaver: WeaponData = arena.enemy.weapon.data
	_check(is_equal_approx(cleaver.windup, 0.55) and is_equal_approx(cleaver.active, 0.12) and is_equal_approx(cleaver.recovery, 0.85)
			and is_equal_approx(cleaver.damage, 15.0), "Gegnerangriff durch Profil verändert")
	# Knockback-Strecke unabhängig vom Profil; Profil B handelt wieder, solange Rest-Knockback wirkt.
	var result_b: Dictionary = await _measure_enemy_knockback()
	main.call("set_profile", TrainingArena.StunProfile.BASE)
	await _ticks(2)
	for e in arena.active_enemies:
		_check(is_equal_approx(e.hit_stun, 0.4), "Rückwechsel auf A: %.2f" % e.hit_stun)
	var result_a: Dictionary = await _measure_enemy_knockback()
	print("    Knockback A: %.3f m, Rest bei Handlungsbeginn %.2f s · B: %.3f m, Rest bei Handlungsbeginn %.2f s" % [
			result_a["distance"], result_a["remaining_at_action"], result_b["distance"], result_b["remaining_at_action"]])
	_check(absf(result_a["distance"] - result_b["distance"]) < 0.02, "Profil B verkürzt den Knockback")
	_check(result_b["remaining_at_action"] > 0.0 and is_zero_approx(result_a["remaining_at_action"]), "Erwartete Rest-Knockback-Überlappung nicht gemessen")


## Hammertreffer auf einen verfolgenden Gegner: Knockbackstrecke und Rest-Knockback beim Ende der Benommenheit.
func _measure_enemy_knockback() -> Dictionary:
	_calm_all_enemies()
	var e := arena.enemy
	_put_enemy(e, Vector3(-2.5, 0, -2.0), Vector3.RIGHT, true)
	_place_player(Vector3(2.5, 0, -2.0), Vector3.LEFT)
	player.process_mode = Node.PROCESS_MODE_DISABLED  # Spieler als ruhendes Ziel
	await _ticks(2)
	var start := e.global_position
	e.receive_hit(_hammer_hit(Vector3.LEFT))
	var remaining_at_action := -1.0
	var displacement_at_kb_end := 0.0
	for i in 40:
		await _ticks(1)
		if remaining_at_action < 0.0 and e.state != Scrapling.State.HIT:
			remaining_at_action = e.knockback_remaining()
		if displacement_at_kb_end == 0.0 and e.knockback_remaining() <= 0.0:
			displacement_at_kb_end = start.x - e.global_position.x
	player.process_mode = Node.PROCESS_MODE_INHERIT
	return {"distance": displacement_at_kb_end, "remaining_at_action": maxf(remaining_at_action, 0.0)}


func test_g3_hammer_hits_multiple_enemies_once() -> void:
	_calm_all_enemies()
	_gamepad_mode()
	_place_player(Vector3(0, 0, 0), Vector3.RIGHT)
	var e := arena.active_enemies
	_put_enemy(e[0], Vector3(1.5, 0, 0), Vector3.LEFT)
	_put_enemy(e[1], Vector3(1.1, 0, 0.75), Vector3.LEFT)
	_put_enemy(e[2], Vector3(1.1, 0, -0.75), Vector3.LEFT)
	await _ticks(3)
	var hits := {}
	player.hit_landed.connect(func(target: Node3D, _p: Vector3) -> void: hits[target.name] = int(hits.get(target.name, 0)) + 1)
	await _single_rt_attack()
	await _ticks(40)
	print("    Treffer je Gegner aus einem Schlag: %s" % [hits])
	_check(hits.size() == 3, "Nicht alle Gegner im Sektor getroffen")
	for target_name in hits:
		_check(int(hits[target_name]) == 1, "%s %d-mal getroffen" % [target_name, hits[target_name]])
	for enemy in e:
		_check(is_equal_approx(enemy.hp, enemy.tuning.max_hp - player.weapon.data.damage), "%s HP %.0f" % [enemy.name, enemy.hp])


func test_g4_simultaneous_enemy_hits_attributed_separately() -> void:
	_calm_all_enemies()
	_place_player(Vector3(0, 0, 0), Vector3.FORWARD)
	var e := arena.active_enemies
	_put_enemy(e[0], Vector3(1.0, 0, 0), Vector3.LEFT)
	_put_enemy(e[1], Vector3(-1.0, 0, 0), Vector3.RIGHT)
	_put_enemy(e[2], Vector3(0, 0, 1.0), Vector3.FORWARD)
	await _ticks(3)
	var tick := [0]
	var events: Array = []
	player.damaged.connect(func(hit: HitInfo) -> void: events.append([hit.source.name, hit.swing_id, tick[0], player.hp]))
	for enemy in e:
		enemy.start_attack()
	for i in 120:
		tick[0] = i
		await _ticks(1)
	print("    Gleichzeitige Gegnertreffer (Quelle, swing_id, Tick, HP danach): %s" % [events])
	_check(events.size() == 3, "%d statt 3 Treffer aus drei gleichzeitigen Angriffen" % events.size())
	var sources := {}
	for ev: Array in events:
		sources[ev[0]] = true
	_check(sources.size() == 3, "Treffer nicht je Gegnerangriff getrennt zugeordnet")
	_check(is_equal_approx(player.hp, player.tuning.max_hp - 3.0 * 15.0), "HP nach drei gleichzeitigen Treffern: %.0f" % player.hp)


func test_g5_victory_only_after_all_mixed_kills() -> void:
	_calm_all_enemies()
	var finished: Array[bool] = []
	arena.encounter_finished.connect(func(victory: bool) -> void: finished.append(victory))
	var summaries: Array[EncounterStats] = []
	arena.round_summarized.connect(func(st: EncounterStats) -> void: summaries.append(st))
	var e := arena.active_enemies
	var lethal := HitInfo.new()
	lethal.damage = 20.0
	for i in 4:
		e[0].receive_hit(lethal)
	await _ticks(2)
	_check(arena.encounter == TrainingArena.Encounter.RUNNING and finished.is_empty() and arena.enemies_remaining() == 2, "Sieg nach 1/3")
	e[1].global_position = Vector3(e[1].global_position.x, arena.kill_height - 1.0, e[1].global_position.z)
	await _ticks(2)
	_check(e[1].last_defeat_reason == Scrapling.DefeatReason.FALL and finished.is_empty() and arena.enemies_remaining() == 1, "Sieg nach 2/3")
	for i in 4:
		e[2].receive_hit(lethal)
	await _ticks(2)
	e[2].global_position = Vector3(e[2].global_position.x, arena.kill_height - 1.0, e[2].global_position.z)
	await _ticks(2)
	_check(finished == [true] and arena.encounter == TrainingArena.Encounter.VICTORY, "Sieg nicht genau einmal nach 3/3")
	for enemy in e:
		_check(enemy.defeat_count == 1, "%s doppelt besiegt" % enemy.name)
	_check(summaries.size() == 1 and summaries[0].enemies_hp_defeated == 2 and summaries[0].enemies_fall_defeated == 1,
			"Zusammenfassung HP/Kante falsch: %s" % [summaries[0].to_line() if not summaries.is_empty() else "-"])
	# Gleichzeitig besiegte Gegner (selber Tick): eine Ergebnisanzeige.
	arena.restart()
	await _ticks(2)
	_calm_all_enemies()
	finished.clear()
	for enemy in arena.active_enemies:
		for i in 4:
			enemy.receive_hit(lethal)
	await _ticks(90)
	_check(finished == [true], "Gleichzeitige Niederlagen erzeugen %d Ergebnisse" % finished.size())
	var overlay: EncounterOverlay = main.get("result_overlay")
	_check(overlay.is_open(), "Ergebnisanzeige fehlt")
	main.call("restart")


func test_g6_death_fall_reset_mode_cleanup() -> void:
	var summaries: Array[EncounterStats] = []
	arena.round_summarized.connect(func(st: EncounterStats) -> void: summaries.append(st))
	var overlay: EncounterOverlay = main.get("result_overlay")
	# a) Spielertod: alle Gegner stoppen, genau ein Abschluss.
	player.hp = 10.0
	for i in 600:
		await _ticks(1)
		if player.state == PlayerController.State.DEAD:
			break
	_check(player.state == PlayerController.State.DEAD, "Spieler nicht besiegt")
	var any_attack := false
	for i in 40:
		await _ticks(1)
		for e in arena.active_enemies:
			any_attack = any_attack or e.state == Scrapling.State.ATTACK or e.weapon.is_busy()
	_check(not any_attack, "Gegner kämpfen nach Spielertod weiter")
	_check(summaries.size() == 1 and summaries[0].outcome == EncounterStats.Outcome.DEFEAT, "Kein eindeutiger Niederlage-Abschluss")
	await _ticks(40)
	_check(overlay.is_open(), "Niederlage-Anzeige fehlt")
	main.call("restart")
	await _ticks(3)
	_assert_clean_group_round("nach Neustart")
	# b) Spielerfall: Zusammenfassung vor dem Reset, genau ein Reset, keine Treffer während des Falls.
	var restarts := [0]
	arena.restarted.connect(func() -> void: restarts[0] += 1)
	_gamepad_mode()
	_place_player(Vector3(5.8, 0, 3.0), Vector3.RIGHT)
	_set_stick(_stick_for_world(Vector3.RIGHT))
	for i in 200:
		await _ticks(1)
		if player.state == PlayerController.State.OUT:
			break
	_set_stick(Vector2.ZERO)
	_check(summaries.size() == 2 and summaries[1].outcome == EncounterStats.Outcome.PLAYER_FALL and restarts[0] == 0,
			"Spielerfall-Zusammenfassung nicht vor dem Reset gesichert")
	var hp_during_fall := player.hp
	while player.state == PlayerController.State.OUT:
		for e in arena.active_enemies:
			_check(e.state != Scrapling.State.ATTACK, "Gegner greift während des Spielerfalls an")
		await _ticks(1)
	await _ticks(3)
	_check(restarts[0] == 1, "Spielerfall setzt %d-mal zurück" % restarts[0])
	_check(hp_during_fall <= player.hp, "Schaden während des Spielerfalls")
	_assert_clean_group_round("nach Spielerfall")
	# c) Keine doppelten Signalverbindungen nach wiederholten Neustarts.
	for i in 3:
		main.call("restart")
		await _ticks(1)
	for e in arena.enemies:
		_check(e.defeated.get_connections().size() == 1 and e.attack_interrupted.get_connections().size() == 1, "Doppelte Signalverbindungen an %s" % e.name)
	# d) Szenariowechsel: Training deaktiviert alle Gegner, Gruppe aktiviert sie wieder.
	main.call("set_mode", TrainingArena.Mode.TRAINING)
	await _ticks(3)
	for e in arena.enemies:
		_check(not e.visible and e.state == Scrapling.State.INACTIVE and not e.weapon.is_busy(), "%s im Training aktiv" % e.name)
	main.call("set_mode", TrainingArena.Mode.GROUP)
	await _ticks(3)
	_assert_clean_group_round("nach Szenariowechsel")


func _assert_clean_group_round(context: String) -> void:
	_check(not get_tree().paused and arena.encounter == TrainingArena.Encounter.RUNNING, "Runde läuft nicht %s" % context)
	_check(arena.active_enemies.size() == 3 and arena.enemies_remaining() == 3, "Nicht alle Gegner zurück %s" % context)
	for i in 3:
		var e := arena.active_enemies[i]
		_check(is_equal_approx(e.hp, e.tuning.max_hp) and not e.is_defeated and not e.weapon.is_busy(), "%s nicht zurückgesetzt %s" % [e.name, context])
		_check(e.global_position.distance_to(arena.group_enemy_spawns[i].global_position) < 0.5, "%s nicht am Start %s" % [e.name, context])
	_check(player.state == PlayerController.State.MOVE and is_equal_approx(player.hp, player.tuning.max_hp), "Spieler nicht zurückgesetzt %s" % context)
	_check(player.global_position.distance_to(arena.group_player_spawn.global_position) < 0.3, "Spieler nicht am Gruppen-Spawn %s" % context)
	_check(arena.effects.get_child_count() == 0 and not InputRouter.attack_held, "Effekte/Eingaben nicht bereinigt %s" % context)


func test_g7_no_damage_from_old_or_interrupted_attacks() -> void:
	# a) Angriff der alten Runde wird durch Neustart verworfen.
	_calm_all_enemies()
	_place_player(Vector3(0, 0, -0.5), Vector3.FORWARD)
	var e := arena.active_enemies
	_put_enemy(e[0], Vector3(1.0, 0, -0.5), Vector3.LEFT)
	await _ticks(2)
	e[0].start_attack()
	while e[0].weapon.phase_progress() < 0.5:
		await _ticks(1)
	arena.restart()
	_check(not e[0].weapon.is_busy(), "Alter Angriff läuft nach Neustart weiter")
	for i in 60:
		await _ticks(1)
	_check(is_equal_approx(player.hp, player.tuning.max_hp), "Schaden aus altem Angriff")
	# b) Zwei gleichzeitige Angriffe, einer im Windup durch Hammertreffer unterbrochen: nur der andere trifft.
	_calm_all_enemies()
	_place_player(Vector3(0, 0, 0), Vector3.FORWARD)
	_put_enemy(e[0], Vector3(1.0, 0, 0), Vector3.LEFT)
	_put_enemy(e[1], Vector3(-1.0, 0, 0), Vector3.RIGHT)
	_put_enemy(e[2], Vector3(-4.0, 0, 3.0), Vector3.RIGHT)
	await _ticks(3)
	var sources: Array[String] = []
	player.damaged.connect(func(hit: HitInfo) -> void: sources.append(hit.source.name))
	var interrupted := [0]
	e[0].attack_interrupted.connect(func(_x: Scrapling) -> void: interrupted[0] += 1)
	e[0].start_attack()
	e[1].start_attack()
	while e[0].weapon.phase_progress() < 0.5:
		await _ticks(1)
	var small := _hammer_hit(Vector3.RIGHT)
	small.knockback_velocity = Vector3(0.3, 0, 0)
	e[0].receive_hit(small)
	for i in 90:
		await _ticks(1)
	_check(interrupted[0] == 1, "Abbruch vor ACTIVE nicht gemeldet")
	_check(sources == [String(e[1].name)], "Treffer aus unterbrochenem Angriff: %s" % [sources])


func test_g8_edge_probe_with_separation_and_knockback_fall() -> void:
	_calm_all_enemies()
	var e := arena.active_enemies
	var mover := e[0]
	_put_enemy(e[2], Vector3(-4.0, 0, 3.0), Vector3.RIGHT)
	_put_enemy(e[1], Vector3(5.3, 0, 0), Vector3.FORWARD)  # Nachbar drückt den Läufer Richtung Kante (+X)
	_put_enemy(mover, Vector3(6.0, 0, 0), Vector3.FORWARD, true)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.global_position = Vector3(6.0, 0, -4.4)
	await _ticks(1)
	var initial_push := mover.separation_push()
	var start_z := mover.global_position.z
	var max_x := mover.global_position.x
	for i in 240:
		await _ticks(1)
		max_x = maxf(max_x, mover.global_position.x)
	player.process_mode = Node.PROCESS_MODE_INHERIT
	print("    Abstandshaltung an der Kante: Anfangsdruck %s, max. x %.2f, Weg in -Z %.2f m" % [initial_push, max_x, start_z - mover.global_position.z])
	_check(initial_push.x > 0.1, "Testaufbau: kein Abstandsdruck zur Kante")
	_check(mover.global_position.y > -0.05 and not mover.is_defeated and max_x < 6.5, "Abstandshaltung führt über die Kante")
	_check(start_z - mover.global_position.z > 1.0, "Gegner blockiert statt weiterzulaufen")
	# Knockback bleibt echt: Hammertreffer Richtung Kante → Fall-Niederlage.
	_calm_all_enemies()
	_put_enemy(mover, Vector3(5.9, 0, 0), Vector3.LEFT)
	_put_enemy(e[1], Vector3(5.1, 0, 0.3), Vector3.FORWARD)
	await _ticks(2)
	mover.receive_hit(_hammer_hit(Vector3.RIGHT))
	for i in 120:
		await _ticks(1)
		if mover.is_defeated:
			break
	_check(mover.is_defeated and mover.last_defeat_reason == Scrapling.DefeatReason.FALL and mover.defeat_count == 1, "Knockback führt trotz Abstandshaltung nicht zum Fall")


func test_g9_player_movement_and_cadence_unchanged() -> void:
	_calm_all_enemies()
	_check(is_equal_approx(player.tuning.move_speed, 4.6) and is_equal_approx(player.tuning.attack_move_multiplier, 1.0)
			and is_equal_approx(player.tuning.dodge_speed, 10.0), "Spielerwerte verändert")
	var hammer := player.weapon.data
	_check(is_equal_approx(hammer.windup, 0.26) and is_equal_approx(hammer.active, 0.12) and is_equal_approx(hammer.recovery, 0.42)
			and is_equal_approx(hammer.damage, 20.0) and is_equal_approx(hammer.knockback_speed, 8.0), "Hammerwerte verändert")
	_gamepad_mode()
	var free: Array[Vector2] = await _record_sweep(false)
	var held: Array[Vector2] = await _record_sweep(true)
	var worst := 0.0
	for i in SWEEP_TICKS:
		worst = maxf(worst, free[i].distance_to(held[i]))
	_check(worst < 0.05, "Bewegung mit gehaltenem RT in der Gruppe abweichend (%.2f m/s)" % worst)
	var starts: Array[int] = []
	var tick := [0]
	player.weapon.swing_started.connect(func(_id: int, _dir: Vector3) -> void: starts.append(tick[0]))
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	for i in 120:
		tick[0] = i
		await _ticks(1)
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_check(starts.size() == 3, "Gehaltenes RT in der Gruppe: %d statt 3 Swings" % starts.size())


# --- Diagnose: RT halten + Vorwärtslaufen (Skript, kein menschlicher Spieler) ---------

func _nearest_living_enemy() -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for e in arena.combatants():
		if bool(e.get("is_defeated")) or not e.visible:
			continue
		var d := e.global_position.distance_to(player.global_position)
		if d < best_distance:
			best_distance = d
			best = e
	return best


## Diagnoseskript. edge_aware: läuft nicht weiter, wenn der nächste Schritt in Kantennähe führt
## (1,2 m Sicherheitsabstand); sonst identisch.
func _diag_hold_forward(label: String, edge_aware: bool = false, start_delay: float = 0.0, prefer_shooter: bool = false) -> EncounterStats:
	var summaries: Array[EncounterStats] = []
	arena.round_summarized.connect(func(st: EncounterStats) -> void: summaries.append(st))
	_gamepad_mode()
	await _ticks(roundi(start_delay * 60.0))  # Spieler wartet, Gegner laufen bereits an
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	for i in 1800:  # höchstens 30 s
		var target := _nearest_living_enemy()
		if prefer_shooter and not arena.active_shooters.is_empty() and not arena.sparker.is_defeated and arena.sparker.visible:
			target = arena.sparker
		if target != null:
			var to := target.global_position - player.global_position
			to.y = 0
			var step := player.global_position + to.normalized() * 1.2
			var near_edge := absf(step.x) > 6.5 - 0.6 or absf(step.z) > 5.0 - 0.6
			var walk := to.length() > 1.3 and not (edge_aware and near_edge)
			_set_stick(_stick_for_world(to.normalized()) if walk else Vector2.ZERO)
		await _ticks(1)
		if not summaries.is_empty():
			break
	_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_set_stick(Vector2.ZERO)
	if summaries.is_empty():
		arena.restart()  # Zeitlimit: als Abbruch zusammenfassen
	_check(not summaries.is_empty(), "Keine Rundenzusammenfassung")
	if not summaries.is_empty():
		print("    DIAG %s: %s · Spieler-HP am Ende %d" % [label, summaries[0].to_line(), int(player.hp)])
		return summaries[0]
	return null


func test_d1_diag_duel_hold_forward_a() -> void:
	await _diag_hold_forward("Duell/A")


func test_d2_diag_duel_hold_forward_b() -> void:
	await _diag_hold_forward("Duell/B")


func test_d3_diag_group_hold_forward_a() -> void:
	await _diag_hold_forward("Gruppe/A")


func test_d4_diag_group_hold_forward_b() -> void:
	await _diag_hold_forward("Gruppe/B")


func test_d5_diag_group_hold_forward_edge_aware_a() -> void:
	await _diag_hold_forward("Gruppe/A kantenvorsichtig", true)


func test_d6_diag_group_hold_forward_edge_aware_b() -> void:
	await _diag_hold_forward("Gruppe/B kantenvorsichtig", true)


## Gleiche kantenvorsichtige RT-Strategie mit unterschiedlicher Startverzögerung (0–1,2 s), je Profil A/B.
## Jede Runde beginnt mit vollständigem Neustart (identische Ausgangslage bis auf die Verzögerung).
func test_d7_diag_group_timing_sensitivity() -> void:
	var table: PackedStringArray = []
	for profile in [TrainingArena.StunProfile.BASE, TrainingArena.StunProfile.SHORT]:
		for delay in [0.0, 0.25, 0.5, 0.8, 1.2]:
			main.call("set_profile", profile)
			await _ticks(2)
			var st: EncounterStats = await _diag_hold_forward("Gruppe/%s Verzögerung %.2f s" % ["A" if profile == TrainingArena.StunProfile.BASE else "B", delay], true, delay)
			if st != null:
				table.append("%s %.2fs: %s %.1fs Schaden %d, ACTIVE %d/%d" % ["A" if profile == TrainingArena.StunProfile.BASE else "B",
						delay, st.outcome_name(), st.duration, int(st.damage_taken), st.enemy_attacks_active, st.enemy_attacks_started])
			arena.restart()
			await _ticks(2)
	print("    Sensitivität: " + " | ".join(table))
	_check(table.size() == 10, "Nicht alle Diagnoseläufe zusammengefasst")



# --- M2C: Mischkampf mit Funkenwerfer ----------------------------------------------

func _calm_mixed() -> void:
	for c in arena.combatants():
		c.call("stop_combat")


func _put_sparker(pos: Vector3, facing: Vector3, with_target: bool = false) -> Sparker:
	var s := arena.sparker
	s.stop_combat()
	s.target = player if with_target else null
	s.global_position = Vector3(pos.x, 0.0, pos.z)
	s.velocity = Vector3.ZERO
	s.rotation.y = PlayerController.yaw_for_direction(facing.normalized())
	return s


## Scraplings aus dem Weg, Funkenwerfer isoliert.
func _isolate_sparker() -> void:
	_calm_mixed()
	_put_enemy(arena.active_enemies[0], Vector3(5.0, 0, -4.0), Vector3.LEFT)
	_put_enemy(arena.active_enemies[1], Vector3(-5.5, 0, -4.0), Vector3.RIGHT)


func _lethal(amount: float) -> HitInfo:
	var hit := HitInfo.new()
	hit.damage = amount
	return hit


func test_x1_mixed_start_and_default_profile() -> void:
	_check(arena.mode == TrainingArena.Mode.MIXED, "Standardszenario ist nicht Gemischt")
	_check(arena.stun_profile == TrainingArena.StunProfile.SHORT, "Standardprofil ist nicht B")
	_check(arena.shot_profile == TrainingArena.ShotProfile.SHARP and is_equal_approx(arena.sparker.tuning.commit_time, 0.55),
			"Standard-Schussprofil ist nicht Scharf")
	_check(arena.active_enemies.size() == 2 and arena.active_shooters.size() == 1 and arena.combatants().size() == 3, "Zusammensetzung falsch")
	_check(not arena.enemies[2].visible and arena.enemies[2].state == Scrapling.State.INACTIVE, "Dritter Scrapling aktiv")
	for d in arena.dummies:
		_check(not d.visible, "Dummy im Mischkampf sichtbar")
	for e in arena.active_enemies:
		_check(is_equal_approx(e.hit_stun, 0.2) and is_equal_approx(e.tuning.hit_stun, 0.4), "Profil B nicht auf Scraplings / Ressource verändert")
		_check(e.global_position.distance_to(player.global_position) > e.tuning.attack_start_distance + 1.5, "%s startet zu nah" % e.name)
	var s := arena.sparker
	_check(is_equal_approx(s.hit_stun, 0.2) and is_equal_approx(s.hp, 60.0), "Funkenwerfer-Startwerte falsch")
	_check(s.global_position.distance_to(player.global_position) > s.tuning.fire_distance, "Funkenwerfer startet in Schussdistanz")
	for c in arena.combatants():
		_check(absf(c.global_position.x) < 6.5 - 1.2 and absf(c.global_position.z) < 5.0 - 1.2, "%s startet an der Kante" % c.name)
		_check(camera.is_position_in_frustum(c.global_position + Vector3.UP * 0.6), "%s zu Beginn nicht im Bild (Viewport %s, Bildpunkt %s)" % [
				c.name, get_viewport().get_visible_rect().size, camera.unproject_position(c.global_position + Vector3.UP * 0.6)])
	# Profil A bleibt explizit erreichbar und betrifft nur die Scraplings.
	main.call("set_profile", TrainingArena.StunProfile.BASE)
	await _ticks(2)
	for e in arena.active_enemies:
		_check(is_equal_approx(e.hit_stun, 0.4), "Profil A nicht erreichbar")
	_check(is_equal_approx(arena.sparker.hit_stun, 0.2), "Profil verändert Funkenwerfer")
	var next: int = main.call("next_mode", TrainingArena.Mode.MIXED)
	_check(next == TrainingArena.Mode.GROUP, "Szenariozyklus beginnt nicht bei Gemischt → Gruppe")


func test_x2_charge_fire_recover_cycle() -> void:
	_isolate_sparker()
	_place_player(Vector3(1.0, 0, 0), Vector3.LEFT)
	var s := _put_sparker(Vector3(-3.0, 0, 0), Vector3.RIGHT, true)
	var spawned: Array[SparkBolt] = []
	arena.projectile_spawned.connect(func(bolt: SparkBolt) -> void: spawned.append(bolt))
	var ticks_in := {}
	var sequence: Array[String] = []
	var commit_tick := -1
	var charge_start_tick := -1
	var fire_tick := -1
	var start_pos := Vector3.ZERO
	var drift := 0.0
	for i in 200:
		await _ticks(1)
		var label: String = Sparker.State.keys()[s.state]
		if sequence.is_empty() or sequence[sequence.size() - 1] != label:
			sequence.append(label)
			if label == "CHARGE" and charge_start_tick < 0:
				charge_start_tick = i
				start_pos = s.global_position
		ticks_in[label] = int(ticks_in.get(label, 0)) + 1
		if commit_tick < 0 and s.is_committed():
			commit_tick = i
		if fire_tick < 0 and not spawned.is_empty():
			fire_tick = i
		if charge_start_tick >= 0 and (s.state == Sparker.State.CHARGE or s.state == Sparker.State.RECOVER):
			drift = maxf(drift, s.global_position.distance_to(start_pos))
		if sequence.size() >= 4 and sequence[sequence.size() - 2] == "RECOVER":
			break
	print("    Funkenwerfer: %s · Aufladen %d Ticks, Festlegung nach %d, Schuss nach %d, Erholung %d Ticks" % [
			" → ".join(sequence), ticks_in.get("CHARGE", 0), commit_tick - charge_start_tick, fire_tick - charge_start_tick, ticks_in.get("RECOVER", 0)])
	_check(" ".join(sequence).contains("CHARGE RECOVER"), "Ablauf Aufladen → Erholung fehlt")
	_check(absi(int(ticks_in.get("CHARGE", 0)) - 39) <= 1, "Aufladedauer weicht ab")
	_check(absi(commit_tick - charge_start_tick - 27) <= 1, "Festlegung nicht nach 0,45 s")
	_check(absi(int(ticks_in.get("RECOVER", 0)) - 60) <= 1, "Erholung nicht 1,0 s")
	_check(spawned.size() == 1, "%d Projektile aus einem Schuss" % spawned.size())
	_check(drift < 0.03, "Funkenwerfer bewegt sich beim Aufladen/Erholen (%.2f m)" % drift)
	s.stop_combat()  # kein zweiter Schuss in der Messung
	await _ticks(40)
	_check(is_equal_approx(player.hp, player.tuning.max_hp - s.tuning.projectile_damage), "Stehender Spieler nicht vom Bolzen getroffen (HP %.0f)" % player.hp)


func test_x3_no_retarget_after_commit() -> void:
	_isolate_sparker()
	_place_player(Vector3(1.0, 0, 0), Vector3.LEFT)
	var s := _put_sparker(Vector3(-3.0, 0, 0), Vector3.RIGHT, true)
	var spawned: Array[SparkBolt] = []
	arena.projectile_spawned.connect(func(bolt: SparkBolt) -> void: spawned.append(bolt))
	while s.state != Sparker.State.CHARGE:
		await _ticks(1)
	var initial := s.fire_direction
	player.global_position = Vector3(1.0, 0, 1.6)  # vor der Festlegung: Drehen folgt
	while not s.is_committed():
		await _ticks(1)
	var committed := s.fire_direction
	var yaw := s.rotation.y
	var pos := s.global_position
	_check(rad_to_deg(committed.angle_to(initial)) > 8.0, "Kein Nachdrehen vor der Festlegung (%.1f°)" % rad_to_deg(committed.angle_to(initial)))
	player.global_position = Vector3(1.0, 0, -2.2)  # nach der Festlegung: kein Nachführen
	while spawned.is_empty():
		_check(s.fire_direction.distance_to(committed) < 0.0001 and absf(angle_difference(s.rotation.y, yaw)) < 0.001, "Nachführen nach der Festlegung")
		await _ticks(1)
	_check(s.global_position.distance_to(pos) < 0.02, "Funkenwerfer läuft beim Aufladen")
	_check(spawned[0].direction.distance_to(committed) < 0.001, "Schussrichtung weicht von der Festlegung ab")
	s.stop_combat()  # kein zweiter Schuss in der Messung
	await _ticks(150)
	_check(is_equal_approx(player.hp, player.tuning.max_hp), "Ausgewichener Spieler dennoch getroffen (Homing?)")


func test_x4_interrupted_charge_never_fires_late() -> void:
	for interrupt_at in [0.3, 0.55]:
		arena.restart()
		await _ticks(2)
		_isolate_sparker()
		_place_player(Vector3(1.0, 0, 0), Vector3.LEFT)
		var s := _put_sparker(Vector3(-3.0, 0, 0), Vector3.RIGHT, true)
		var spawned := [0]
		arena.projectile_spawned.connect(func(_bolt: SparkBolt) -> void: spawned[0] += 1)
		var interrupted := [0]
		s.attack_interrupted.connect(func(_x: Sparker) -> void: interrupted[0] += 1)
		while s.state != Sparker.State.CHARGE or s.state_time() < interrupt_at:
			await _ticks(1)
		var hit := _hammer_hit(Vector3.LEFT)
		hit.knockback_velocity = Vector3(-0.5, 0, 0)
		s.receive_hit(hit)
		_check(s.state == Sparker.State.HIT and interrupted[0] == 1, "Aufladen bei %.2f s nicht abgebrochen" % interrupt_at)
		for i in 36:  # 0,6 s: länger als der Rest des alten Aufladens, kürzer als Benommenheit + neues Aufladen
			await _ticks(1)
		_check(spawned[0] == 0, "Abgebrochenes Aufladen (%.2f s) erzeugt spätes Projektil" % interrupt_at)


func test_x5_fired_bolt_survives_shooter_defeat() -> void:
	_isolate_sparker()
	_place_player(Vector3(1.0, 0, 0), Vector3.LEFT)
	var s := _put_sparker(Vector3(-3.0, 0, 0), Vector3.RIGHT, true)
	var spawned: Array[SparkBolt] = []
	arena.projectile_spawned.connect(func(bolt: SparkBolt) -> void: spawned.append(bolt))
	var sources: Array[String] = []
	player.damaged.connect(func(hit: HitInfo) -> void: sources.append(hit.source_name))
	while spawned.is_empty():
		await _ticks(1)
	s.receive_hit(_lethal(100.0))
	_check(s.is_defeated and arena.encounter == TrainingArena.Encounter.RUNNING, "Begegnung endet mit dem Schützen")
	for i in 60:
		await _ticks(1)
	_check(sources.size() == 1 and sources[0].begins_with("Funkenbolzen"), "Abgefeuerter Bolzen nach Schützentod verloren: %s" % [sources])
	_check(arena.projectiles.get_child_count() == 0, "Bolzen nach Treffer nicht verbraucht")


func _bolt_toward_player(from: Vector3, speed: float = -1.0) -> SparkBolt:
	var tuning: SparkerTuning = arena.sparker.tuning
	if speed > 0.0:
		tuning = tuning.duplicate()
		tuning.projectile_speed = speed
	var target := player.global_position + Vector3.UP * tuning.muzzle_height
	return arena.spawn_projectile(from, target - from, tuning, "Test")


func test_x6_projectile_contact_rules() -> void:
	_isolate_sparker()
	_put_sparker(Vector3(-5.0, 0, 3.8), Vector3.RIGHT)
	var damaged: Array[HitInfo] = []
	player.damaged.connect(func(hit: HitInfo) -> void: damaged.append(hit))
	var evaded := [0]
	player.hit_evaded.connect(func(_hit: HitInfo) -> void: evaded[0] += 1)
	var h := arena.sparker.tuning.muzzle_height
	# a) Ein Treffer, danach verbraucht; kleiner Knockback.
	_place_player(Vector3(0, 0, 0), Vector3.FORWARD)
	await _ticks(2)
	_bolt_toward_player(Vector3(3.0, h, 0))
	var start := player.global_position
	for i in 60:
		await _ticks(1)
	_check(damaged.size() == 1 and is_equal_approx(player.hp, 90.0), "Bolzen trifft %d-mal" % damaged.size())
	_check(arena.projectiles.get_child_count() == 0, "Bolzen nach Treffer nicht verbraucht")
	var pushed := Vector2(player.global_position.x - start.x, player.global_position.z - start.z).length()
	print("    Bolzen-Knockback: %.2f m" % pushed)
	_check(pushed > 0.1 and pushed < 0.4, "Bolzen-Knockback unplausibel (%.2f m)" % pushed)
	# b) Dodge-Kontakt: verbraucht, kein Schaden, kein Knockback.
	damaged.clear()
	_gamepad_mode()
	player.tuning = player.tuning.duplicate()
	player.tuning.dodge_speed = 0.0
	_place_player(Vector3(0, 0, 0), Vector3.FORWARD)
	await _ticks(50)  # Dodge-Cooldown frei
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await _ticks(1)
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	_bolt_toward_player(Vector3(1.25, h, 0))
	var contact_speed := [-1.0]
	player.hit_evaded.connect(func(_hit: HitInfo) -> void: contact_speed[0] = Vector2(player.velocity.x, player.velocity.z).length())
	for i in 30:
		await _ticks(1)
	_check(evaded[0] == 1 and damaged.is_empty(), "Dodge-Kontakt: %d abgewehrt, %d Schaden" % [evaded[0], damaged.size()])
	_check(arena.projectiles.get_child_count() == 0, "Dodge-Kontakt verbraucht den Bolzen nicht")
	_check(contact_speed[0] >= 0.0 and contact_speed[0] < 0.01 and Vector2(player.velocity.x, player.velocity.z).length() < 0.01, "Knockback trotz iFrames")
	player.tuning = load("res://resources/tuning/player_tuning.tres")
	# c) Kein Friendly Fire: Scrapling zwischen Schuss und Spieler.
	damaged.clear()
	player.hp = player.tuning.max_hp
	_place_player(Vector3(0, 0, 0), Vector3.FORWARD)
	var blocker := arena.active_enemies[0]
	_put_enemy(blocker, Vector3(1.5, 0, 0), Vector3.LEFT)
	await _ticks(2)
	_bolt_toward_player(Vector3(3.2, h, 0))
	for i in 60:
		await _ticks(1)
	_check(is_equal_approx(blocker.hp, blocker.tuning.max_hp) and damaged.size() == 1, "Friendly Fire oder Bolzen blockiert")
	_put_enemy(blocker, Vector3(5.0, 0, -4.0), Vector3.LEFT)
	# d) Wegprüfung: 3 m pro Tick, keine Abtastposition läge im Spieler – trotzdem ein Treffer.
	damaged.clear()
	_place_player(Vector3(0, 0, 0), Vector3.FORWARD)
	await _ticks(2)
	_bolt_toward_player(Vector3(-7.2, h, 0.0), 180.0)
	for i in 10:
		await _ticks(1)
	_check(damaged.size() == 1, "Schneller Bolzen springt durch den Spieler (%d Treffer)" % damaged.size())
	# e) Startüberlappung: Abschuss im Spieler trifft genau einmal.
	damaged.clear()
	await _ticks(20)
	arena.spawn_projectile(player.global_position + Vector3.UP * h, Vector3.RIGHT, arena.sparker.tuning, "Test")
	for i in 10:
		await _ticks(1)
	_check(damaged.size() == 1, "Startüberlappung: %d Treffer" % damaged.size())
	# f) Höhenunterschied: Spieler weit unter der Plattform wird nicht wegen gleicher XZ-Position getroffen.
	damaged.clear()
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.global_position = Vector3(0.5, -3.5, 0)
	var high := arena.spawn_projectile(Vector3(-3.0, h, 0), Vector3.RIGHT, arena.sparker.tuning, "Test")
	var passed := false
	for i in 90:
		await _ticks(1)
		if is_instance_valid(high) and high.global_position.x > 1.5:
			passed = true
	player.process_mode = Node.PROCESS_MODE_INHERIT
	_check(passed and damaged.is_empty(), "Bolzen trifft Spieler unterhalb der Plattform")


func test_x7_defeats_and_victory_after_all_three() -> void:
	_calm_mixed()
	var finished: Array[bool] = []
	arena.encounter_finished.connect(func(victory: bool) -> void: finished.append(victory))
	var summaries: Array[EncounterStats] = []
	arena.round_summarized.connect(func(st: EncounterStats) -> void: summaries.append(st))
	var s := arena.sparker
	# Funkenwerfer per HP (3 Hammertreffer à 20).
	for i in 3:
		s.receive_hit(_hammer_hit(Vector3.LEFT))
		await _ticks(15)
	_check(s.is_defeated and s.defeat_count == 1 and s.last_defeat_reason == Sparker.DefeatReason.HP, "Funkenwerfer nicht per HP besiegt")
	_check(finished.is_empty() and arena.enemies_remaining() == 2, "Sieg vor allen Gegnern")
	# Scrapling per Fall, zweiter per HP; kurz vor dem letzten Treffer ein Bolzen im Flug.
	var e := arena.active_enemies
	e[0].global_position = Vector3(e[0].global_position.x, arena.kill_height - 1.0, e[0].global_position.z)
	await _ticks(2)
	_check(finished.is_empty() and arena.enemies_remaining() == 1, "Sieg nach 2/3")
	arena.spawn_projectile(Vector3(-5.0, 0.85, 4.0), Vector3.RIGHT, s.tuning, "Test")
	for i in 4:
		e[1].receive_hit(_lethal(20.0))
	await _ticks(2)
	_check(finished == [true] and arena.encounter == TrainingArena.Encounter.VICTORY, "Sieg nicht genau einmal nach 3/3")
	_check(arena.projectiles.get_child_count() == 0, "Projektile nach Sieg nicht entfernt")
	_check(summaries.size() == 1 and summaries[0].enemies_hp_defeated == 2 and summaries[0].enemies_fall_defeated == 1, "Zusammenfassung HP/Kante falsch")
	s.global_position = Vector3(s.global_position.x, arena.kill_height - 1.0, s.global_position.z)
	await _ticks(2)
	_check(s.defeat_count == 1, "Funkenwerfer doppelt besiegt")
	# Neue Runde: Funkenwerfer mit echtem Hammerschlag über die Kante.
	main.call("restart")
	await _ticks(2)
	_isolate_sparker()
	s = _put_sparker(Vector3(5.9, 0, 0), Vector3.LEFT)
	_gamepad_mode()
	_place_player(Vector3(4.6, 0, 0), Vector3.RIGHT)
	await _single_rt_attack()
	for i in 120:
		await _ticks(1)
		if s.is_defeated:
			break
	_check(s.is_defeated and s.last_defeat_reason == Sparker.DefeatReason.FALL and s.defeat_count == 1, "Funkenwerfer nicht über die Kante besiegt")


func test_x8_pause_restart_mode_cleanup() -> void:
	_isolate_sparker()
	_place_player(Vector3(0, 0, 0), Vector3.FORWARD)
	await _ticks(2)
	var tuning: SparkerTuning = arena.sparker.tuning.duplicate()
	tuning.projectile_lifetime = 10.0
	var bolt := arena.spawn_projectile(Vector3(-5.5, 0.85, 3.0), Vector3.FORWARD, tuning, "Test")
	await _ticks(5)
	# Pause hält Bolzen und Lebensdauer an, löscht ihn aber nicht.
	var pause_menu: PauseMenu = main.get("pause_menu")
	pause_menu.open()
	var pos := bolt.global_position
	var age := bolt.age
	for i in 30:
		await _ticks(1)
	_check(is_instance_valid(bolt) and bolt.global_position == pos and is_equal_approx(bolt.age, age), "Bolzen fliegt hinter der Pause weiter")
	pause_menu.close()
	await _ticks(3)
	_check(is_instance_valid(bolt) and bolt.global_position != pos, "Bolzen nach Pause nicht fortgesetzt")
	# Laufendes Aufladen + Bolzen → Neustart bereinigt.
	var s := _put_sparker(Vector3(-3.0, 0, 0), Vector3.RIGHT, true)
	while s.state != Sparker.State.CHARGE:
		await _ticks(1)
	arena.spawn_projectile(Vector3(-5.5, 0.85, 3.0), Vector3.FORWARD, tuning, "Test")
	main.call("restart")
	await _ticks(2)
	_check(arena.projectiles.get_child_count() == 0 and s.state != Sparker.State.CHARGE, "Neustart hinterlässt Projektile/Aufladung")
	_check(not (s.get_node("AimIndicator") as Node3D).visible, "Richtungsanzeige nach Neustart sichtbar")
	# Profilwechsel und Szenariowechsel bereinigen.
	arena.spawn_projectile(Vector3(-5.5, 0.85, 3.0), Vector3.FORWARD, tuning, "Test")
	main.call("set_profile", TrainingArena.StunProfile.BASE)
	await _ticks(2)
	_check(arena.projectiles.get_child_count() == 0, "Profilwechsel hinterlässt Projektile")
	arena.spawn_projectile(Vector3(-5.5, 0.85, 3.0), Vector3.FORWARD, tuning, "Test")
	main.call("set_mode", TrainingArena.Mode.GROUP)
	await _ticks(2)
	_check(arena.projectiles.get_child_count() == 0 and not s.visible and s.state == Sparker.State.INACTIVE and s.collision_layer == 0, "Gruppe: Funkenwerfer/Projektile nicht bereinigt")
	_check(arena.active_enemies.size() == 3 and arena.active_shooters.is_empty(), "Gruppe falsch zusammengesetzt")
	main.call("set_mode", TrainingArena.Mode.MIXED)
	await _ticks(2)
	_check(s.visible and s.state != Sparker.State.INACTIVE and is_equal_approx(s.hp, 60.0), "Mischkampf nach Rückwechsel nicht frisch")
	# Spielertod und Spielerfall entfernen Projektile sofort.
	arena.spawn_projectile(Vector3(-5.5, 0.85, 3.0), Vector3.FORWARD, tuning, "Test")
	var lethal := HitInfo.new()
	lethal.damage = 1000.0
	player.receive_hit(lethal)
	await _ticks(1)
	_check(arena.projectiles.get_child_count() == 0 and s.state == Sparker.State.IDLE, "Spielertod bereinigt nicht")
	main.call("restart")
	await _ticks(2)
	arena.spawn_projectile(Vector3(-5.5, 0.85, 3.0), Vector3.FORWARD, tuning, "Test")
	player.global_position = Vector3(0, arena.kill_height - 1.0, 0)
	await _ticks(2)
	_check(arena.projectiles.get_child_count() == 0, "Spielerfall entfernt Projektile nicht")
	# Keine doppelten Signalverbindungen.
	for i in 3:
		main.call("restart")
		await _ticks(1)
	_check(s.fired.get_connections().size() == 1 and s.defeated.get_connections().size() == 1, "Doppelte Signalverbindungen am Funkenwerfer")


func test_x9_player_values_and_movement_unchanged() -> void:
	_calm_mixed()
	_check(is_equal_approx(player.tuning.move_speed, 4.6) and is_equal_approx(player.tuning.attack_move_multiplier, 1.0)
			and is_equal_approx(player.tuning.dodge_speed, 10.0) and is_equal_approx(player.tuning.dodge_iframe_end, 0.14), "Spielerwerte verändert")
	var hammer := player.weapon.data
	_check(is_equal_approx(hammer.windup, 0.26) and is_equal_approx(hammer.active, 0.12) and is_equal_approx(hammer.recovery, 0.42)
			and is_equal_approx(hammer.damage, 20.0) and is_equal_approx(hammer.attack_range, 1.9) and is_equal_approx(hammer.knockback_speed, 8.0), "Hammerwerte verändert")
	_isolate_sparker()
	_put_sparker(Vector3(-5.0, 0, 3.8), Vector3.RIGHT)
	_gamepad_mode()
	var free: Array[Vector2] = await _record_sweep(false)
	var held: Array[Vector2] = await _record_sweep(true)
	var worst := 0.0
	for i in SWEEP_TICKS:
		worst = maxf(worst, free[i].distance_to(held[i]))
	_check(worst < 0.05, "Bewegung mit gehaltenem RT im Mischkampf abweichend (%.2f m/s)" % worst)


func test_x10_mixed_hit_chain_documented() -> void:
	_isolate_sparker()
	_place_player(Vector3(0, 0, 0), Vector3.FORWARD)
	var e := arena.active_enemies[0]
	_put_enemy(e, Vector3(1.0, 0, 0), Vector3.LEFT)
	await _ticks(2)
	var events: Array = []
	var tick := [0]
	player.damaged.connect(func(hit: HitInfo) -> void:
		events.append([hit.source_name, hit.damage, tick[0], player.hp, Vector2(hit.knockback_velocity.x, hit.knockback_velocity.z).length(), hit.knockback_duration]))
	e.start_attack()
	# Bolzen so abschießen, dass er etwa gleichzeitig mit dem ACTIVE-Fenster ankommt.
	var windup_ticks := roundi(e.weapon.data.windup * 60.0)
	var travel_ticks := roundi((3.2 - player.hit_radius - arena.sparker.tuning.projectile_radius) / arena.sparker.tuning.projectile_speed * 60.0)
	var spawn_tick := windup_ticks + 2 - travel_ticks
	for i in spawn_tick:
		tick[0] = i
		await _ticks(1)
	_bolt_toward_player(Vector3(0, arena.sparker.tuning.muzzle_height, -3.2))
	for i in 60:
		tick[0] = spawn_tick + i
		await _ticks(1)
	print("    Gemischte Trefferkette (Quelle, Schaden, Tick, HP danach, Knockback m/s, Dauer s): %s · Endzustand %s" % [events, PlayerController.State.keys()[player.state]])
	var names := {}
	for ev: Array in events:
		names[String(ev[0]).get_slice(" ", 0)] = true
	_check(events.size() == 2 and names.size() == 2, "Beide Quellen (Nahkampf + Bolzen) nicht angewendet: %s" % [events])


func test_d8_diag_mixed_hold_forward_b() -> void:
	await _diag_hold_forward("Gemischt/B nächster Gegner, kantenvorsichtig", true)


func test_d9_diag_mixed_shooter_first_b() -> void:
	await _diag_hold_forward("Gemischt/B Schütze zuerst, kantenvorsichtig", true, 0.0, true)



# --- M2C-Nachtrag: Schussprofil „Scharf“ -------------------------------------------

func test_y1_sharp_shot_profile_values_and_cycle() -> void:
	var s := arena.sparker
	var fresh := ResourceLoader.load("res://resources/tuning/sparker_tuning.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as SparkerTuning
	_check(arena.shot_profile == TrainingArena.ShotProfile.SHARP, "Schussprofil nicht Scharf")
	_check(is_equal_approx(s.tuning.charge_time, 0.70) and is_equal_approx(s.tuning.commit_time, 0.55)
			and is_equal_approx(s.tuning.projectile_speed, 11.0), "Scharf-Werte falsch")
	# Nur die drei Werte weichen ab; die geteilte Ressource bleibt gleich der Datei.
	var shared: SparkerTuning = arena._base_sparker_tuning
	for prop in shared.get_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var n: String = prop["name"]
			_check(shared.get(n) == fresh.get(n), "Geteilte Funkenwerfer-Ressource verändert: %s" % n)
			if not n in ["charge_time", "commit_time", "projectile_speed"]:
				_check(s.tuning.get(n) == fresh.get(n), "Scharf verändert zusätzlich %s" % n)
	# Zyklus: Aufladen 42 Ticks, Festlegung nach 33, genau ein Bolzen mit 11 m/s.
	_isolate_sparker()
	_place_player(Vector3(1.0, 0, 0), Vector3.LEFT)
	_put_sparker(Vector3(-3.0, 0, 0), Vector3.RIGHT, true)
	var spawned: Array[SparkBolt] = []
	arena.projectile_spawned.connect(func(bolt: SparkBolt) -> void: spawned.append(bolt))
	var tick := [0]
	var charge_start := -1
	var commit_tick := -1
	var fire_tick := -1
	var hit_tick := [-1]
	player.damaged.connect(func(_hit: HitInfo) -> void:
		if hit_tick[0] < 0:
			hit_tick[0] = tick[0])
	var bolt_start := Vector3.ZERO
	var bolt_speed := 0.0
	for i in 150:
		tick[0] = i
		await _ticks(1)
		if charge_start < 0 and s.state == Sparker.State.CHARGE:
			charge_start = i
		if commit_tick < 0 and s.is_committed():
			commit_tick = i
		if fire_tick < 0 and not spawned.is_empty():
			fire_tick = i
			bolt_start = spawned[0].global_position
		elif fire_tick >= 0 and i == fire_tick + 1 and is_instance_valid(spawned[0]):
			bolt_speed = spawned[0].global_position.distance_to(bolt_start) * 60.0
		if hit_tick[0] >= 0:
			break
	s.stop_combat()
	print("    Scharf: Festlegung nach %d Ticks, Schuss nach %d, Bolzen %.1f m/s, Treffer %d Ticks (%.2f s) nach der Festlegung" % [
			commit_tick - charge_start, fire_tick - charge_start, bolt_speed, hit_tick[0] - commit_tick, (hit_tick[0] - commit_tick) / 60.0])
	_check(absi(commit_tick - charge_start - 33) <= 1 and absi(fire_tick - charge_start - 42) <= 1, "Scharf-Timing weicht ab")
	_check(spawned.size() == 1 and absf(bolt_speed - 11.0) < 0.3, "Scharf: Bolzen %d / %.1f m/s" % [spawned.size(), bolt_speed])
	# Wechsel auf Standard und zurück: vollständiger Neustart, Werte korrekt.
	var restarts := [0]
	arena.restarted.connect(func() -> void: restarts[0] += 1)
	main.call("set_shot_profile", TrainingArena.ShotProfile.STANDARD)
	await _ticks(2)
	_check(restarts[0] == 1 and s.tuning == arena._base_sparker_tuning and is_equal_approx(s.tuning.commit_time, 0.45), "Wechsel auf Standard fehlerhaft")
	main.call("set_shot_profile", TrainingArena.ShotProfile.SHARP)
	await _ticks(2)
	_check(restarts[0] == 2 and is_equal_approx(s.tuning.commit_time, 0.55), "Rückwechsel auf Scharf fehlerhaft")


func test_d10_diag_mixed_hold_forward_sharp_b() -> void:
	await _diag_hold_forward("Gemischt/B Schuss scharf, nächster Gegner, kantenvorsichtig", true)


## Diagnose: Wie spät darf man nach der Richtungsfestlegung seitlich loslaufen und weicht noch aus?
## Funkenwerfer isoliert, Spieler steht 5 m entfernt und läuft nach der Verzögerung voll seitlich.
func test_d11_diag_mixed_dodge_reaction_window() -> void:
	var table: PackedStringArray = []
	for profile in [TrainingArena.ShotProfile.STANDARD, TrainingArena.ShotProfile.SHARP]:
		var row: PackedStringArray = []
		for delay in [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.8]:
			main.call("set_shot_profile", profile)
			await _ticks(2)
			_isolate_sparker()
			_gamepad_mode()
			_place_player(Vector3(2.0, 0, 0), Vector3.LEFT)
			var s := _put_sparker(Vector3(-3.0, 0, 0), Vector3.RIGHT, true)
			var hits := [0]
			player.damaged.connect(func(_hit: HitInfo) -> void: hits[0] += 1)
			var waited := 0
			while not s.is_committed() and waited < 300:
				waited += 1
				await _ticks(1)
			_check(s.is_committed(), "Diagnose: keine Richtungsfestlegung")
			await _ticks(roundi(delay * 60.0))
			_set_stick(_stick_for_world(Vector3.BACK))
			for i in 90:
				await _ticks(1)
			_set_stick(Vector2.ZERO)
			s.stop_combat()
			row.append("%.1fs:%s" % [delay, "getroffen" if hits[0] > 0 else "ausgewichen"])
			arena.restart()
			await _ticks(2)
		table.append("%s → %s" % ["Standard" if profile == TrainingArena.ShotProfile.STANDARD else "Scharf", " ".join(row)])
	print("    Reaktionsfenster (Verzögerung nach Festlegung bis zum seitlichen Loslaufen, 5 m Abstand):")
	for line in table:
		print("      " + line)
	_check(table.size() == 2, "Diagnose unvollständig")


# --- Abstieg: zwei Ebenen (test_z…) ---------------------------------------------------------

func _kill_upper_floor() -> void:
	for c in arena.combatants():
		c.call("receive_hit", _lethal(200.0))
	await _ticks(2)


func _await_descent(target: TrainingArena.Descent, max_ticks: int = 240) -> bool:
	for i in max_ticks:
		if arena.descent == target:
			return true
		await _ticks(1)
	return arena.descent == target


## Direkt über die Kante auf Ebene 2 (ohne Eingabe), wartet auf die Landung.
func _drop_off_edge() -> void:
	player.global_position = Vector3(7.2, 0.05, 0.0)
	player.velocity = Vector3.ZERO
	await _await_descent(TrainingArena.Descent.FLOOR_2)
	await _ticks(2)


func _drop_through_hatch() -> void:
	await _kill_upper_floor()
	await _ticks(2)
	player.global_position = arena.hatch.global_position + Vector3.UP * 0.05
	player.velocity = Vector3.ZERO
	await _await_descent(TrainingArena.Descent.FLOOR_2)
	await _ticks(2)


func test_z1_descent_start_layout_and_cycle() -> void:
	var fresh: Node = MAIN_SCENE.instantiate()
	_check(fresh.get("start_mode") == TrainingArena.Mode.DESCENT, "Standardstart ist nicht der Abstieg")
	fresh.free()
	_check(arena.mode == TrainingArena.Mode.DESCENT and arena.descent == TrainingArena.Descent.FLOOR_1 and arena.floor_index() == 1,
			"Abstieg startet nicht auf Ebene 1")
	_check(arena.stun_profile == TrainingArena.StunProfile.SHORT and arena.shot_profile == TrainingArena.ShotProfile.SHARP,
			"Abstieg nicht mit Profil B / Schuss scharf")
	_check(arena.active_enemies.size() == 2 and arena.active_shooters.size() == 1, "Ebene 1 nicht 2 Scraplings + 1 Funkenwerfer")
	_check(arena.active_enemies[0] == arena.enemies[0] and arena.active_shooters[0] == arena.sparker, "Ebene 1 nutzt nicht die Mischkampf-Gegner")
	_check(not arena.enemies[2].visible, "Dritter Scrapling im Abstieg aktiv")
	# M2D.1: Nur die aktuelle Ebene ist sichtbar; Ebene 2 existiert physisch, bleibt aber verborgen.
	_check(not arena.lower_floor.visible and arena.lower_floor.collision_layer == 1, "Ebene 2 im Kampf auf Ebene 1 sichtbar oder ohne Kollision")
	_check(arena.upper_floor.visible and is_zero_approx(arena.depth_backdrop.position.y), "Tiefendarstellung nicht unter Ebene 1")
	_check(is_equal_approx(arena.lower_floor_height(), -10.0), "Ebene 2 nicht 10 m tiefer")
	_check(arena.lower_enemies.size() == 2 and arena.lower_shooters.size() == 1, "Ebene 2 nicht 2 Scraplings + 1 Funkenwerfer")
	for c in arena.lower_combatants():
		# Bis zum Abstieg verborgen (ihre HP-Anzeigen würden sonst durch Ebene 1 scheinen), aber zurückgesetzt und wartend.
		_check(not c.visible and c.get("target") == null and bool(c.get("gap_detour")) and not bool(c.get("is_defeated")),
				"%s auf Ebene 2 nicht wartend" % c.name)
		var local: Vector3 = arena.lower_floor.to_local(c.global_position)
		_check(arena.lower_floor.is_safe_point(Vector2(local.x, local.z), 1.0), "%s steht auf Ebene 2 an einer Kante" % c.name)
	for c in arena.combatants():
		_check(not bool(c.get("gap_detour")), "Ebene-1-Gegner mit Lückenumweg (Verhalten weicht vom Mischkampf ab)")
	# Neue Form: Schacht in der Mitte von Ebene 2.
	_check(not arena.lower_floor.contains(Vector2(0, -1)) and arena.lower_floor.contains(Vector2(0, 3)) and arena.lower_floor.contains(Vector2(-6, -1)),
			"Ebene 2 hat keinen Schacht in der Mitte")
	# Geschlossene Luke trägt: Spieler steht darauf, fällt nicht.
	_calm_mixed()
	_place_player(arena.hatch.global_position, Vector3.FORWARD)
	player.global_position.y = 0.05
	await _ticks(30)
	_check(not arena.hatch.is_open and player.is_on_floor() and player.global_position.y > -0.1, "Geschlossene Luke trägt nicht")
	_check(arena.descent == TrainingArena.Descent.FLOOR_1, "Abstieg ohne Öffnung ausgelöst")
	# Szenariozyklus: Abstieg → Gemischt → … → Training → Abstieg.
	_check(main.call("next_mode", TrainingArena.Mode.DESCENT) == TrainingArena.Mode.MIXED
			and main.call("next_mode", TrainingArena.Mode.TRAINING) == TrainingArena.Mode.DESCENT, "Szenariozyklus falsch")
	# Andere Szenarien: keine zweite Ebene, keine Ebene-2-Gegner.
	for m in [TrainingArena.Mode.MIXED, TrainingArena.Mode.GROUP, TrainingArena.Mode.COMBAT, TrainingArena.Mode.TRAINING]:
		main.call("set_mode", m)
		await _ticks(2)
		_check(not arena.lower_floor.visible and arena.lower_floor.collision_layer == 0 and arena.descent == TrainingArena.Descent.NONE,
				"Ebene 2 in %s aktiv" % TrainingArena.scenario_name(m))
		for c in arena.lower_combatants():
			_check(not c.visible and int(c.get("collision_layer")) == 0, "Ebene-2-Gegner in %s aktiv" % TrainingArena.scenario_name(m))


func test_z2_hatch_opens_after_clear_and_walk_in_without_damage() -> void:
	var summaries: Array[EncounterStats] = []
	arena.round_summarized.connect(func(st: EncounterStats) -> void: summaries.append(st))
	var finished: Array[bool] = []
	arena.encounter_finished.connect(func(victory: bool) -> void: finished.append(victory))
	var starts: Array = []
	arena.descent_started.connect(func(regular: bool, point: Vector3) -> void: starts.append([regular, point]))
	var landings: Array[float] = []
	arena.floor_landed.connect(func(damage: float) -> void: landings.append(damage))
	_calm_mixed()
	arena.combatants()[0].call("receive_hit", _lethal(200.0))
	arena.combatants()[1].call("receive_hit", _lethal(200.0))
	await _ticks(2)
	_check(not arena.hatch.is_open, "Luke vor dem Räumen offen")
	arena.combatants()[2].call("receive_hit", _lethal(200.0))
	await _ticks(2)
	_check(arena.hatch.is_open and arena.descent == TrainingArena.Descent.FLOOR_1_CLEARED, "Luke öffnet nach dem Räumen nicht")
	_check(finished.is_empty() and arena.encounter == TrainingArena.Encounter.RUNNING, "Räumen von Ebene 1 beendet die Begegnung")
	_check(summaries.size() == 1 and summaries[0].outcome == EncounterStats.Outcome.CLEARED and summaries[0].scenario == "Abstieg · Ebene 1",
			"Zusammenfassung Ebene 1 nicht „geräumt“")
	# Echte Eingabe: Controller-Stick läuft von vorn in die Luke (kein Interact-Button).
	_gamepad_mode()
	var hatch_pos := arena.hatch.global_position
	_place_player(hatch_pos + Vector3(0, 0, -2.0), Vector3.BACK)
	await _ticks(10)
	_set_stick(_stick_for_world(Vector3.BACK))
	var ys: Array[float] = []
	var max_step := 0.0
	var last := player.global_position
	var transition := _new_transition_record()
	for i in 240:
		await _ticks(1)
		var step := Vector2(player.global_position.x - last.x, player.global_position.z - last.z).length()
		max_step = maxf(max_step, step)
		last = player.global_position
		_record_transition(transition, i)
		if arena.descent == TrainingArena.Descent.DROPPING:
			ys.append(player.global_position.y)
		if arena.descent == TrainingArena.Descent.FLOOR_2:
			break
	_set_stick(Vector2.ZERO)
	_check_transition(transition, "Luke")
	_check(starts.size() == 1 and bool(starts[0][0]), "Abstieg durch die Luke nicht als regulär erkannt")
	_check(arena.descent == TrainingArena.Descent.FLOOR_2 and landings == [0.0], "Keine schadensfreie Landung auf Ebene 2")
	_check(is_equal_approx(player.hp, player.tuning.max_hp), "Regulärer Abstieg verursacht Schaden (HP %.0f)" % player.hp)
	_check(max_step < player.tuning.dodge_speed / 60.0 + 0.02, "Sprung in der Fallbewegung (%.2f m/Tick)" % max_step)
	var monotonic := true
	for i in range(1, ys.size()):
		monotonic = monotonic and ys[i] <= ys[i - 1] + 0.001
	_check(ys.size() > 20 and monotonic, "Fall nicht sichtbar/stetig (%d Ticks)" % ys.size())
	var local := arena.lower_floor.to_local(player.global_position)
	_check(arena.lower_floor.is_safe_point(Vector2(local.x, local.z), arena.landing_edge_margin - 0.2), "Landung nicht an sicherem Punkt")
	_check(Vector2(player.global_position.x - hatch_pos.x, player.global_position.z - hatch_pos.z).length() < 1.5,
			"Landung nicht unter der Luke (%s)" % player.global_position)
	_check(finished.is_empty() and summaries.size() == 1, "Landung beendet/fasst Runde falsch zusammen")
	for c in arena.combatants():
		_check(c.get("target") == player and c.visible, "%s greift nach der Landung nicht an" % c.name)
	_check(not arena.upper_floor.visible and not arena.enemies[0].visible and not arena.sparker.visible, "Ebene 1 bei der Landung nicht ausgeblendet")
	_check(is_equal_approx(arena.depth_backdrop.position.y, arena.lower_floor_height()) or arena.depth_backdrop.position.y < -5.0,
			"Tiefendarstellung folgt nicht nach unten")


func test_z3_edge_fall_skips_floor1_with_fall_damage() -> void:
	var summaries: Array[EncounterStats] = []
	arena.round_summarized.connect(func(st: EncounterStats) -> void: summaries.append(st))
	var finished: Array[bool] = []
	arena.encounter_finished.connect(func(victory: bool) -> void: finished.append(victory))
	var starts: Array = []
	arena.descent_started.connect(func(regular: bool, point: Vector3) -> void: starts.append([regular, point]))
	# Ebene 1 läuft: Gegner haben ein Ziel, ein Bolzen ist unterwegs.
	arena.spawn_projectile(Vector3(-5.0, 0.85, 4.0), Vector3.RIGHT, arena.sparker.tuning, "Test")
	_gamepad_mode()
	_place_player(Vector3(5.2, 0, 0.5), Vector3.RIGHT)
	await _ticks(2)
	_set_stick(_stick_for_world(Vector3.RIGHT))
	var fall_xz := Vector3.ZERO
	var max_step := 0.0
	var last := player.global_position
	var transition := _new_transition_record()
	for i in 300:
		await _ticks(1)
		max_step = maxf(max_step, Vector2(player.global_position.x - last.x, player.global_position.z - last.z).length())
		last = player.global_position
		_record_transition(transition, i)
		if arena.descent == TrainingArena.Descent.DROPPING and fall_xz == Vector3.ZERO:
			fall_xz = player.global_position
			_set_stick(Vector2.ZERO)
		if arena.descent == TrainingArena.Descent.FLOOR_2:
			break
	_set_stick(Vector2.ZERO)
	_check_transition(transition, "Kante")
	_check(starts.size() == 1 and not bool(starts[0][0]), "Kantensturz als regulärer Abstieg gewertet")
	_check(summaries.size() >= 1 and summaries[0].outcome == EncounterStats.Outcome.SKIPPED, "Ebene 1 nicht als übersprungen zusammengefasst")
	_check(arena.projectiles.get_child_count() == 0, "Projektile nach dem Verlassen von Ebene 1 nicht entfernt")
	for c in arena.upper_combatants():
		_check(c.get("target") == null, "%s verfolgt nach dem Sturz weiter" % c.name)
	_check(arena.descent == TrainingArena.Descent.FLOOR_2 and player.state != PlayerController.State.OUT, "Nicht auf Ebene 2 gelandet")
	var expected := maxf(ceilf(player.tuning.max_hp * 0.12), 1.0)
	_check(is_equal_approx(player.hp, player.tuning.max_hp - expected), "Sturzschaden nicht 12 %% (HP %.0f)" % player.hp)
	_check(arena.stats != null and is_equal_approx(arena.stats.fall_damage, expected) and is_equal_approx(arena.stats.damage_taken, expected)
			and arena.stats.hits_taken == 0 and arena.stats.scenario == "Abstieg · Ebene 2", "Ebene-2-Auswertung ohne Sturzschaden")
	_check(max_step < player.tuning.dodge_speed / 60.0 + 0.02, "Sprung in der Fallbewegung (%.2f m/Tick)" % max_step)
	var local := arena.lower_floor.to_local(player.global_position)
	_check(arena.lower_floor.is_safe_point(Vector2(local.x, local.z), arena.landing_edge_margin - 0.2), "Landung nicht an sicherem Punkt")
	# Senkrechter Fall wie durch die Luke: nur der kurz abklingende Schwung, kein seitliches Lenken.
	_check(Vector2(player.global_position.x - fall_xz.x, player.global_position.z - fall_xz.z).length() < 1.0,
			"Landepunkt nicht nahe der Sturzstelle (%s → %s)" % [fall_xz, player.global_position])
	for c in arena.lower_combatants():
		var d: Vector3 = c.global_position - player.global_position
		_check(Vector2(d.x, d.z).length() >= arena.landing_enemy_clearance - 0.3, "Landung zu nah an %s" % c.name)
	_check(finished.is_empty(), "Sturz beendet die Begegnung")
	# Landeschutz nur gegen Kampftreffer, dann wieder verwundbar.
	_check(not player.receive_hit(_lethal(5.0)), "Kein Landeschutz direkt nach der Landung")
	await _ticks(roundi(arena.landing_protection * 60.0) + 2)
	_check(player.receive_hit(_lethal(5.0)), "Landeschutz endet nicht")


func test_z4_edge_fall_after_clear_still_damages() -> void:
	await _kill_upper_floor()
	_check(arena.hatch.is_open, "Luke nicht offen")
	var landings: Array[float] = []
	arena.floor_landed.connect(func(damage: float) -> void: landings.append(damage))
	player.global_position = Vector3(-7.2, 0.05, -1.0)
	player.velocity = Vector3.ZERO
	await _await_descent(TrainingArena.Descent.FLOOR_2)
	_check(landings == [12.0] and is_equal_approx(player.hp, 88.0), "Kantensturz nach dem Räumen ohne Sturzschaden (%s)" % [landings])
	_check(not arena.descent_regular, "Kantensturz als regulär gewertet")


func test_z5_lethal_fall_damage_is_defeat() -> void:
	var finished: Array[bool] = []
	arena.encounter_finished.connect(func(victory: bool) -> void: finished.append(victory))
	var summaries: Array[EncounterStats] = []
	arena.round_summarized.connect(func(st: EncounterStats) -> void: summaries.append(st))
	_calm_mixed()
	player.receive_hit(_lethal(92.0))
	await _ticks(30)
	_check(is_equal_approx(player.hp, 8.0), "Vorbereitung: HP nicht 8")
	await _drop_off_edge()
	_check(player.state == PlayerController.State.DEAD and is_equal_approx(player.hp, 0.0), "Tödlicher Sturzschaden tötet nicht")
	_check(finished == [false] and arena.encounter == TrainingArena.Encounter.DEFEAT, "Tödlicher Sturz keine Niederlage")
	_check(summaries.size() == 2 and summaries[1].outcome == EncounterStats.Outcome.DEFEAT and is_equal_approx(summaries[1].fall_damage, 12.0),
			"Zusammenfassung des tödlichen Sturzes falsch")
	for c in arena.combatants():
		_check(c.get("target") == null, "%s greift den besiegten Spieler an" % c.name)


func test_z6_fall_on_floor2_is_defeat_and_restart_returns_to_floor1() -> void:
	await _drop_through_hatch()
	_check(arena.descent == TrainingArena.Descent.FLOOR_2, "Vorbereitung: nicht auf Ebene 2")
	var finished: Array[bool] = []
	arena.encounter_finished.connect(func(victory: bool) -> void: finished.append(victory))
	var summaries: Array[EncounterStats] = []
	arena.round_summarized.connect(func(st: EncounterStats) -> void: summaries.append(st))
	for c in arena.combatants():
		c.call("stop_combat")
	# In den Schacht laufen (echter fehlender Boden, keine Barriere).
	_gamepad_mode()
	_place_player(arena.lower_floor.to_global(Vector3(0.0, 0, 2.2)), Vector3.FORWARD)
	player.global_position.y = arena.lower_floor_height() + 0.05
	await _ticks(10)
	_set_stick(_stick_for_world(Vector3.FORWARD))
	for i in 240:
		await _ticks(1)
		if not finished.is_empty():
			break
	_set_stick(Vector2.ZERO)
	_check(finished == [false] and arena.encounter == TrainingArena.Encounter.DEFEAT and player.state == PlayerController.State.OUT,
			"Sturz von Ebene 2 ist keine Niederlage")
	_check(summaries.size() == 1 and summaries[0].outcome == EncounterStats.Outcome.PLAYER_FALL, "Zusammenfassung Ebene 2 nicht „Spielerfall“")
	await _ticks(90)  # Ergebnisanzeige erscheint und pausiert
	_check(get_tree().paused and (main.get("result_overlay") as EncounterOverlay).is_open(), "Keine Ergebnisanzeige nach dem Sturz")
	main.call("restart")
	await _ticks(3)
	_check(not get_tree().paused and arena.descent == TrainingArena.Descent.FLOOR_1 and arena.floor_index() == 1, "Neustart nicht auf Ebene 1")
	_check(player.global_position.distance_to(arena.mixed_player_spawn.global_position) < 0.2 and is_equal_approx(player.hp, 100.0),
			"Spieler nicht am Start von Ebene 1")
	_check(arena.upper_floor.visible and not arena.hatch.is_open and arena.enemies[0].visible and arena.sparker.visible, "Ebene 1 nicht wiederhergestellt")
	var opaque := true
	for node in arena.upper_floor.find_children("*", "GeometryInstance3D", true, false):
		opaque = opaque and is_zero_approx((node as GeometryInstance3D).transparency)
	_check(opaque, "Ebene 1 bleibt transparent")
	_check(arena.active_enemies[0] == arena.enemies[0] and arena.active_shooters[0] == arena.sparker, "Aktive Gegner nicht Ebene 1")
	for c in arena.lower_combatants():
		_check(not c.visible and c.get("target") == null and not bool(c.get("is_defeated")), "%s auf Ebene 2 nicht zurückgesetzt" % c.name)
	var rig := main.get("camera_rig") as CameraRig
	_check(is_equal_approx(rig.min_follow_height, -1.5), "Kamera-Folgegrenze nicht zurückgesetzt")
	_check(not arena.lower_floor.visible and arena.lower_floor.collision_layer == 1 and is_zero_approx(arena.depth_backdrop.position.y),
			"Ebene 2 nach dem Neustart sichtbar / Tiefe nicht zurückgesetzt")
	_check(is_equal_approx(arena.environment.fog_height, -2.0), "Nebelhöhe nicht zurückgesetzt")
	# Die Luke trägt nach dem Neustart wieder.
	_calm_mixed()
	_place_player(arena.hatch.global_position, Vector3.FORWARD)
	player.global_position.y = 0.05
	await _ticks(30)
	_check(player.is_on_floor() and player.global_position.y > -0.1, "Luke nach dem Neustart nicht geschlossen")


func test_z7_floor2_victory_once_including_shaft_fall() -> void:
	await _drop_off_edge()
	_check(arena.descent == TrainingArena.Descent.FLOOR_2, "Vorbereitung: nicht auf Ebene 2")
	var finished: Array[bool] = []
	arena.encounter_finished.connect(func(victory: bool) -> void: finished.append(victory))
	var summaries: Array[EncounterStats] = []
	arena.round_summarized.connect(func(st: EncounterStats) -> void: summaries.append(st))
	for c in arena.combatants():
		c.call("stop_combat")
	var a := arena.lower_enemies[0]
	# In den Schacht gestoßen: Kantensieg auf Ebene 2.
	a.global_position = arena.lower_floor.to_global(Vector3(0.0, 0.05, -1.0))
	await _ticks(120)
	_check(a.is_defeated and a.last_defeat_reason == Scrapling.DefeatReason.FALL and a.defeat_count == 1, "Schachtsturz nicht als Kantensieg")
	_check(finished.is_empty(), "Sieg vor allen Gegnern der Ebene 2")
	arena.lower_enemies[1].receive_hit(_lethal(200.0))
	await _ticks(2)
	_check(finished.is_empty(), "Sieg nach 2/3")
	arena.lower_shooters[0].receive_hit(_lethal(200.0))
	await _ticks(2)
	_check(finished == [true] and arena.encounter == TrainingArena.Encounter.VICTORY, "Kein Sieg nach Ebene 2")
	_check(summaries.size() == 1 and summaries[0].outcome == EncounterStats.Outcome.VICTORY and summaries[0].enemies_fall_defeated == 1
			and summaries[0].enemies_hp_defeated == 2 and summaries[0].to_line().contains("Sturzschaden 12"), "Siegeszusammenfassung Ebene 2 falsch")
	await _ticks(90)
	var overlay := main.get("result_overlay") as EncounterOverlay
	_check(overlay.is_open() and (overlay.get_node("Dim/Center/Panel/Margin/VBox/Title") as Label).text.begins_with("Abstieg geschafft"),
			"Siegesanzeige des Abstiegs fehlt")


func test_z8_lower_enemies_walk_around_shaft() -> void:
	await _drop_through_hatch()
	for c in arena.combatants():
		c.call("stop_combat")
	var y := arena.lower_floor_height()
	_place_player(arena.lower_floor.to_global(Vector3(0.0, 0, 3.0)), Vector3.FORWARD)
	player.global_position.y = y + 0.05
	arena.lower_shooters[0].set_active(false)  # nur Laufwege prüfen
	var a := arena.lower_enemies[0]
	var b := arena.lower_enemies[1]
	b.set_active(false)
	# Direkter Weg führt durch den Schacht (Norden → Süden).
	a.global_position = arena.lower_floor.to_global(Vector3(-1.0, 0.02, -5.0))
	a.velocity = Vector3.ZERO
	a.target = player
	a.state = Scrapling.State.IDLE
	var reached := false
	for i in 600:
		await _ticks(1)
		player.velocity = Vector3.ZERO
		if a.is_defeated:
			break
		if a.state == Scrapling.State.ATTACK:
			reached = true
			break
	_check(not a.is_defeated, "Scrapling fällt in den Schacht")
	_check(reached, "Scrapling findet nicht um den Schacht herum (Position %s)" % a.global_position)
	# Ohne Umweg (Ebene-1-Verhalten) bleibt er an der Lücke stehen statt hineinzulaufen.
	main.call("restart")
	await _ticks(2)
	await _drop_through_hatch()
	for c in arena.combatants():
		c.call("stop_combat")
	a = arena.lower_enemies[0]
	a.gap_detour = false
	_place_player(arena.lower_floor.to_global(Vector3(0.0, 0, 3.0)), Vector3.FORWARD)
	player.global_position.y = y + 0.05
	a.global_position = arena.lower_floor.to_global(Vector3(0.0, 0.02, -5.0))
	a.target = player
	a.state = Scrapling.State.IDLE
	await _ticks(300)
	_check(not a.is_defeated and arena.lower_floor.to_local(a.global_position).z < -2.5, "Ohne Umweg läuft der Scrapling in den Schacht")
	a.gap_detour = true


func test_z9_upper_enemy_fall_never_reaches_floor2() -> void:
	_calm_mixed()
	var e := arena.active_enemies[0]
	e.global_position = Vector3(7.5, 0.02, 0.0)
	var landed := false
	for i in 120:
		await _ticks(1)
		if e.is_on_floor() and e.global_position.y < -5.0:
			landed = true
	_check(e.is_defeated and e.last_defeat_reason == Scrapling.DefeatReason.FALL and not e.visible, "Gestürzter Gegner nicht besiegt")
	_check(not landed and e.global_position.y > arena.lower_floor_height() + 1.0, "Gegner der Ebene 1 erreicht Ebene 2")
	_check(arena.descent == TrainingArena.Descent.FLOOR_1 and arena.enemies_remaining() == 2, "Gegnersturz verändert den Abstieg")


# --- M2D.1: eine Ebene sichtbar, Übergang im Fall ---------------------------------------------

func _new_transition_record() -> Dictionary:
	return {"leave": -1, "reveal": -1, "upper_gone": -1, "lower_full": -1, "land": -1, "fade_at_reveal": -1.0,
			"max_jump": 0.0, "last_upper": 0.0, "last_lower": 0.0, "enemies_early": 0}


## Pro Tick: Blenden der beiden Ebenen (Übergang an die Fallhöhe gekoppelt, stetige Überblendung).
func _record_transition(r: Dictionary, tick: int) -> void:
	var dropping := arena.descent == TrainingArena.Descent.DROPPING
	if r["leave"] < 0 and dropping:
		r["leave"] = tick
	if r["leave"] >= 0 and r["land"] < 0:
		r["max_jump"] = maxf(r["max_jump"], maxf(absf(arena.upper_fade - r["last_upper"]), absf(arena.lower_reveal - r["last_lower"])))
	r["last_upper"] = arena.upper_fade
	r["last_lower"] = arena.lower_reveal
	if r["reveal"] < 0 and arena.lower_floor.visible:
		r["reveal"] = tick
		r["fade_at_reveal"] = arena.upper_fade
	if r["upper_gone"] < 0 and r["leave"] >= 0 and not arena.upper_floor.visible:
		r["upper_gone"] = tick
	if r["lower_full"] < 0 and arena.lower_reveal >= 1.0:
		r["lower_full"] = tick
	if r["land"] < 0 and arena.descent == TrainingArena.Descent.FLOOR_2:
		r["land"] = tick
	if not arena.lower_floor.visible:
		for c in arena.lower_combatants():
			if c.visible:
				r["enemies_early"] += 1


func _check_transition(r: Dictionary, label: String) -> void:
	print("    Übergang %s: verlassen %d · Ebene 2 taucht auf %d (Ebene 1 zu %d%% aufgelöst) · Ebene 1 weg %d · Ebene 2 voll %d · Landung %d (Ticks), größter Blendsprung %.2f/Tick" % [
			label, r["leave"], r["reveal"], roundi(r["fade_at_reveal"] * 100.0), r["upper_gone"], r["lower_full"], r["land"], r["max_jump"]])
	_check(r["leave"] >= 0 and r["reveal"] > r["leave"] and r["upper_gone"] > r["leave"] and r["lower_full"] <= r["land"] and r["land"] > r["reveal"],
			"%s: Ablauf verlassen → Überblendung → Landung verletzt" % label)
	# Eine Ebene im Vordergrund: Ebene 2 taucht erst auf, wenn Ebene 1 schon überwiegend aufgelöst ist.
	_check(r["fade_at_reveal"] >= 0.5, "%s: Ebene 2 erscheint, solange Ebene 1 noch deutlich sichtbar ist" % label)
	# Stetig statt Schnitt: keine großen Blendsprünge pro Tick, Ebene 2 vor der Landung vollständig da.
	_check(r["max_jump"] <= 0.2, "%s: Blendsprung %.2f pro Tick (Schnitt)" % [label, r["max_jump"]])
	_check(r["land"] - r["lower_full"] >= 3, "%s: Ebene 2 erst bei der Landung vollständig" % label)
	_check(r["enemies_early"] == 0, "%s: Gegner der Ebene 2 vor ihrer Ebene sichtbar" % label)
	var total := float(r["land"] - r["leave"]) / 60.0
	_check(total > 0.6 and total < 1.4, "%s: Übergang dauert %.2f s" % [label, total])


## Diagnose: Nach Lauf bzw. weitem Dodge über die Kante fällt der Spieler senkrecht (nur abklingender Schwung);
## der sichere Landepunkt entsteht durch Versetzen der noch verborgenen Ebene 2, nicht durch Lenken.
func test_z10_diag_edge_fall_is_vertical() -> void:
	var rows: PackedStringArray = []
	for variant in ["Laufen", "Dodge"]:
		arena.restart()
		await _ticks(2)
		_calm_mixed()
		_gamepad_mode()
		_place_player(Vector3(5.0, 0, 0.5), Vector3.RIGHT)
		await _ticks(5)
		var leave_xz: Array[Vector3] = []
		var on_start := func(_regular: bool, _point: Vector3) -> void:
			leave_xz.append(player.global_position)
		arena.descent_started.connect(on_start)
		_set_stick(_stick_for_world(Vector3.RIGHT))
		var dodged := false
		var late_speed := 0.0
		for i in 300:
			await _ticks(1)
			if variant == "Dodge" and not dodged and player.global_position.x > 5.8:
				_joy_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
				dodged = true
			elif dodged:
				_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
			if arena.descent == TrainingArena.Descent.DROPPING:
				_set_stick(Vector2.ZERO)
				if arena.transition_progress > 0.3:
					late_speed = maxf(late_speed, Vector2(player.velocity.x, player.velocity.z).length())
			if arena.descent == TrainingArena.Descent.FLOOR_2:
				break
		_set_stick(Vector2.ZERO)
		arena.descent_started.disconnect(on_start)
		_check(arena.descent == TrainingArena.Descent.FLOOR_2 and leave_xz.size() == 1, "%s: keine Landung auf Ebene 2" % variant)
		if leave_xz.is_empty():
			continue
		var drift := Vector2(player.global_position.x - leave_xz[0].x, player.global_position.z - leave_xz[0].z).length()
		var shift := arena.lower_floor.global_position - Vector3(0, arena.lower_floor_height(), 0)
		var local := arena.lower_floor.to_local(player.global_position)
		_check(arena.lower_floor.is_safe_point(Vector2(local.x, local.z), arena.landing_edge_margin - 0.2), "%s: Landung nicht sicher" % variant)
		_check(drift < 1.5 and late_speed < 0.3, "%s: Fall nicht senkrecht (Drift %.2f m, später %.2f m/s)" % [variant, drift, late_speed])
		_check(player.global_position.distance_to(arena.landing_point) < 0.3, "%s: Landung weicht vom Landepunkt ab" % variant)
		rows.append("%s: verlassen bei (%.1f, %.1f) → gelandet (%.1f, %.1f), Drift %.2f m, Horizontaltempo ab 30 %% Fall ≤ %.2f m/s, Ebene 2 versetzt um (%.1f, %.1f)" % [
				variant, leave_xz[0].x, leave_xz[0].z, player.global_position.x, player.global_position.z, drift, late_speed, shift.x, shift.z])
	print("    Kantensturz (Diagnose):")
	for row in rows:
		print("      " + row)
