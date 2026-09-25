extends Node
## Gerenderte QA-Session: lädt die echte Hauptszene, fährt eine Eingabesequenz, speichert Screenshots
## und misst Render-FPS gegen Physikticks. Nicht headless starten.
## Start: godot --path . --resolution 1280x720 --max-fps 60 res://tests/qa_capture.tscn -- --qa-out=qa/output/x

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

var main: Node
var player: PlayerController
var arena: TrainingArena
var camera: Camera3D
var _out_dir: String = "res://qa/output/default"
## Nur ein skriptgesteuerter Gruppenkampf (für die Videoaufnahme mit --write-movie).
var _group_movie_only: bool = false
## Nur ein skriptgesteuerter Mischkampf (für die Videoaufnahme mit --write-movie).
var _mixed_movie_only: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-out="):
			_out_dir = "res://" + arg.trim_prefix("--qa-out=")
		elif arg == "--qa-group-movie":
			_group_movie_only = true
		elif arg == "--qa-mixed-movie":
			_mixed_movie_only = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	main = MAIN_SCENE.instantiate()
	# Die M1/M1.1-Sequenz läuft im Trainingsmodus, danach folgt die M2A-Kampfsequenz.
	main.set("start_mode", TrainingArena.Mode.TRAINING)
	main.set("log_tag", "AUTOMATISIERT (QA-Sequenz)")
	# Der QA-Knoten läuft immer; die Hauptszene muss wie im echten Spiel pausierbar sein.
	main.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(main)
	player = main.get("player")
	arena = main.get("arena")
	camera = (main.get("camera_rig") as CameraRig).camera
	# Quellenwechsel protokollieren: echte Maus-/Controllerereignisse des Systems stören sonst unbemerkt.
	InputRouter.source_changed.connect(func(_source: int) -> void:
		print("QA source_changed -> %s at %.2fs" % [InputRouter.source_name(), Time.get_ticks_msec() / 1000.0]))
	if _group_movie_only:
		await _group_movie()
	elif _mixed_movie_only:
		await _mixed_movie()
	else:
		await _run()
	get_tree().quit()


func _run() -> void:
	var vp_size := get_viewport().get_visible_rect().size
	var win_size := DisplayServer.window_get_size()
	print("QA window=%s visible_rect=%s renderer=%s adapter=%s" % [win_size, vp_size,
			ProjectSettings.get_setting("rendering/renderer/rendering_method"), RenderingServer.get_video_adapter_name()])
	print("QA rendering_driver=%s physics_engine=%s" % [RenderingServer.get_current_rendering_driver_name(),
			ProjectSettings.get_setting("physics/3d/physics_engine")])
	await _seconds(0.8)
	await _shot("01_start")

	# FPS/Physik-Messung über 3 s Echtzeit bei ruhigem Spiel.
	await _measure_rates(3.0)

	# Maus-Facing: Maus rechts unten neben den Player bewegen.
	var mouse_world := player.global_position + Vector3(2.5, 0, 2.0)
	_mouse_move(camera.unproject_position(mouse_world))
	await _seconds(0.3)
	print("QA mouse_facing target_dir=%s facing=%s" % [(mouse_world - player.global_position).normalized(), player.facing_direction])
	await _shot("02_mouse_facing")

	# Swing auf Dummy nahe der rechten Kante.
	_set_stick(Vector2(0.9, 0))
	_set_stick(Vector2.ZERO)
	var dummy: TrainingDummy = arena.dummies[0]
	player.global_position = dummy.global_position + Vector3(-1.3, 0, 0)
	player.facing_direction = Vector3.RIGHT
	await _seconds(0.6)
	_joy(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _until(func() -> bool: return player.weapon.phase == WeaponController.Phase.WINDUP and player.weapon.phase_progress() > 0.7)
	await _shot("03_swing_windup")
	_joy(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _until(func() -> bool: return player.weapon.phase == WeaponController.Phase.ACTIVE and player.weapon.phase_progress() > 0.4)
	await _shot("04_swing_active")
	await _until(func() -> bool: return player.weapon.phase == WeaponController.Phase.RECOVERY)
	await _shot("05_impact_recovery")
	await _seconds(0.6)
	await _shot("06_after_knockback")
	print("QA dummy_after_hit hp=%.0f pos=%s" % [dummy.hp, dummy.global_position])

	# Zweiter Schlag Richtung Kante → Dummy fällt.
	player.global_position = dummy.global_position + Vector3(-1.3, 0, 0)
	player.facing_direction = Vector3.RIGHT
	await _seconds(0.3)
	_joy(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _seconds(0.1)
	_joy(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _seconds(0.45)
	await _shot("07_dummy_over_edge")
	await _seconds(0.8)
	print("QA dummy_edge hp=%.0f pos=%s" % [dummy.hp, dummy.global_position])
	print("QA dummy_edge defeated=%s count=%d fall_defeats=%d" % [dummy.is_defeated, dummy.defeat_count, arena.dummy_fall_defeats])

	# Dodge im Stand.
	player.global_position = Vector3(-1, 0, 1)
	player.facing_direction = Vector3.LEFT
	await _seconds(0.4)
	_joy(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await _until(func() -> bool: return player.state == PlayerController.State.DODGE)
	await _seconds(0.06)
	await _shot("08_dodge")
	_joy(JOY_AXIS_TRIGGER_LEFT, 0.0)
	await _seconds(0.8)

	# Spieler läuft über die vordere Kante.
	player.global_position = Vector3(2.0, 0, 4.0)
	await _seconds(0.3)
	var out := Vector3(0, 0, 1)
	var b := camera.global_basis
	var right := Vector3(b.x.x, 0, b.x.z).normalized()
	var forward := Vector3(-b.z.x, 0, -b.z.z).normalized()
	_set_stick(Vector2(out.dot(right), -out.dot(forward)))
	await _until(func() -> bool: return player.state == PlayerController.State.FALLING)
	await _seconds(0.12)
	await _shot("09_player_falling")
	_set_stick(Vector2.ZERO)
	await _until(func() -> bool: return player.state == PlayerController.State.OUT)
	await _until(func() -> bool: return player.state == PlayerController.State.MOVE)
	await _seconds(0.1)
	await _shot("10_respawned")
	print("QA player_fall count=%d arena=%d pos=%s" % [player.fall_count, arena.player_fall_count, player.global_position])

	# Touch-HUD (Testmodus) mit simuliertem Multitouch.
	InputRouter.set_touch_test_mode(true)
	var tc: TouchControls = main.get_node("TouchLayer/TouchControls")
	_touch(0, true, tc.stick_rest_center())
	_drag(0, tc.stick_rest_center() + Vector2(60, -40))
	_touch(1, true, tc.attack_center())
	await _seconds(0.25)
	await _shot("11_touch_hud")
	_touch(0, false, tc.stick_rest_center())
	_touch(1, false, tc.attack_center())
	InputRouter.set_touch_test_mode(false)

	# M1.1: Swing-Verlauf und RT gehalten + 360°-Stick als Zeitreihen-Kontaktabzug.
	InputRouter._switch_source(InputRouter.Source.KEYBOARD_MOUSE)
	player.global_position = Vector3(-1.5, 0, 0.5)
	player.facing_direction = Vector3.RIGHT
	_set_stick(Vector2(0.9, 0))
	_set_stick(Vector2.ZERO)
	await _seconds(0.6)
	_joy(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _contact_sheet("13_single_swing_sheet", player.weapon.data.total_duration(), 24, func(_t: float) -> void: pass)
	_joy(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _seconds(0.6)
	var sweep := 2.4
	_joy(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _contact_sheet("14_held_rt_360_sheet", sweep, 32, func(t: float) -> void:
		_set_stick(Vector2(cos(TAU * t / sweep), -sin(TAU * t / sweep)) * 0.8))
	_joy(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_set_stick(Vector2.ZERO)
	await _seconds(0.3)

	await _combat_sequence()
	await _group_sequence()
	await _mixed_sequence()

	# Pausemenü.
	(main.get("pause_menu") as PauseMenu).open()
	await _seconds(0.3)
	await _shot("12_pause")
	(main.get("pause_menu") as PauseMenu).close()
	await _seconds(0.2)


func _measure_rates(duration: float) -> void:
	var frames := [0]
	var ticks := [0]
	var on_frame := func() -> void: frames[0] += 1
	var on_tick := func() -> void: ticks[0] += 1
	get_tree().process_frame.connect(on_frame)
	get_tree().physics_frame.connect(on_tick)
	var start := Time.get_ticks_usec()
	await _seconds(duration)
	var elapsed := (Time.get_ticks_usec() - start) / 1000000.0
	get_tree().process_frame.disconnect(on_frame)
	get_tree().physics_frame.disconnect(on_tick)
	print("QA rates elapsed=%.2fs render_fps=%.1f physics_tps=%.1f (Engine.max_fps=%d, physics_ticks_per_second=%d)" % [
			elapsed, frames[0] / elapsed, ticks[0] / elapsed, Engine.max_fps, Engine.physics_ticks_per_second])


func _seconds(duration: float) -> void:
	await get_tree().create_timer(duration, true).timeout


func _until(condition: Callable, timeout: float = 3.0) -> void:
	var start := Time.get_ticks_msec()
	while not condition.call():
		if (Time.get_ticks_msec() - start) / 1000.0 > timeout:
			print("QA WARN timeout waiting for condition")
			return
		await get_tree().physics_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [_out_dir, shot_name]
	image.save_png(ProjectSettings.globalize_path(path))
	print("QA shot %s (%dx%d)" % [path, image.get_width(), image.get_height()])


## Zeitreihe: count gleichmäßig über duration verteilte Ausschnitte um den Player, zeilenweise
## von links oben nach rechts unten. drive(t) wird jedes Frame mit der verstrichenen Zeit aufgerufen.
func _contact_sheet(sheet_name: String, duration: float, count: int, drive: Callable, focus: Node3D = null) -> void:
	const TILE := 200
	const CROP := 320.0
	const COLUMNS := 8
	var rows := ceili(count / float(COLUMNS))
	var sheet := Image.create(TILE * COLUMNS, TILE * rows, false, Image.FORMAT_RGBA8)
	var start := Time.get_ticks_usec()
	var index := 0
	var phases: PackedStringArray = []
	while index < count:
		var t := (Time.get_ticks_usec() - start) / 1000000.0
		drive.call(t)
		await RenderingServer.frame_post_draw
		if t < index * duration / count:
			continue
		var image := get_viewport().get_texture().get_image()
		var to_pixels := image.get_width() / get_viewport().get_visible_rect().size.x
		var focus_node: Node3D = focus if focus != null else player
		var center := camera.unproject_position(focus_node.global_position + Vector3.UP * 0.7) * to_pixels
		var size := int(CROP * to_pixels)
		var origin := Vector2i(clampi(int(center.x) - size / 2, 0, image.get_width() - size),
				clampi(int(center.y) - size / 2, 0, image.get_height() - size))
		var part := image.get_region(Rect2i(origin, Vector2i(size, size)))
		part.convert(Image.FORMAT_RGBA8)
		part.resize(TILE, TILE)
		sheet.blit_rect(part, Rect2i(0, 0, TILE, TILE), Vector2i((index % COLUMNS) * TILE, (index / COLUMNS) * TILE))
		var phase := "-"
		var focus_weapon: WeaponController = focus_node.get("weapon")
		if focus_weapon != null and focus_weapon.is_busy():
			phase = WeaponController.Phase.keys()[focus_weapon.phase].substr(0, 3)
		elif focus_node is Sparker:
			phase = Sparker.State.keys()[(focus_node as Sparker).state].substr(0, 3) + ("!" if (focus_node as Sparker).is_committed() else "")
		phases.append("%d:%s" % [index, phase])
		index += 1
	var path := "%s/%s.png" % [_out_dir, sheet_name]
	sheet.save_png(ProjectSettings.globalize_path(path))
	print("QA sheet %s over %.2fs: %s" % [path, duration, " ".join(phases)])


func _push(event: InputEvent) -> void:
	get_viewport().push_input(event, true)


func _joy(axis: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = 0
	e.axis = axis
	e.axis_value = value
	_push(e)


func _set_stick(axes: Vector2) -> void:
	_joy(JOY_AXIS_LEFT_X, axes.x)
	_joy(JOY_AXIS_LEFT_Y, axes.y)


func _mouse_move(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.device = 0
	e.position = pos
	e.global_position = pos
	e.relative = Vector2(20, 0)
	_push(e)


func _touch(index: int, pressed: bool, pos: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.pressed = pressed
	e.position = pos
	_push(e)


func _drag(index: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = pos
	_push(e)


# --- M2A-Kampfsequenz ----------------------------------------------------------------

func _combat_sequence() -> void:
	main.call("set_mode", TrainingArena.Mode.COMBAT)
	var enemy: Scrapling = arena.enemy
	await _seconds(0.6)
	await _shot("15_combat_start")
	print("QA combat start player=%s enemy=%s" % [player.global_position, enemy.global_position])
	await _measure_rates(3.0)

	# Annäherung und vollständiger Angriffszyklus als Zeitreihe um den Gegner (Spieler steht).
	await _contact_sheet("16_enemy_cycle_sheet", 3.6, 40, func(_t: float) -> void: pass, enemy)
	main.call("restart")
	await _seconds(0.3)

	# Einzelphasen: Gegner nahe am Spieler, Spieler steht.
	_place_enemy_near_player(1.35)
	await _until(func() -> bool: return enemy.state == Scrapling.State.ATTACK and enemy.weapon.phase_progress() > 0.25)
	await _shot("17_enemy_windup_tracking")
	await _until(func() -> bool: return enemy.is_committed() and enemy.weapon.phase_progress() > 0.8)
	await _shot("18_enemy_committed_marker")
	await _until(func() -> bool: return enemy.weapon.phase == WeaponController.Phase.ACTIVE and enemy.weapon.phase_progress() > 0.3)
	await _shot("19_enemy_active_hit")
	await _until(func() -> bool: return enemy.weapon.phase == WeaponController.Phase.RECOVERY and enemy.weapon.phase_progress() > 0.35)
	await _shot("20_enemy_recovery")
	print("QA enemy_hit player_hp=%d" % int(player.hp))

	# Ausweichen nach der Festlegung: Dodge seitlich aus dem Sektor.
	main.call("restart")
	await _seconds(0.3)
	_place_enemy_near_player(1.35)
	await _until(func() -> bool: return enemy.is_committed())
	var to_enemy := enemy.global_position - player.global_position
	var side := Vector3(-to_enemy.z, 0, to_enemy.x).normalized()
	_set_stick(_stick_axes_for_world(side))
	_joy(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await _seconds(0.08)
	await _shot("21_player_dodge_evade")
	_joy(JOY_AXIS_TRIGGER_LEFT, 0.0)
	_set_stick(Vector2.ZERO)
	await _until(func() -> bool: return enemy.weapon.phase == WeaponController.Phase.RECOVERY)
	print("QA dodge_evade player_hp=%d" % int(player.hp))
	# Zurückschlagen während der Erholung.
	var back := enemy.global_position - player.global_position
	back.y = 0
	player.facing_direction = back.normalized()
	_set_stick(_stick_axes_for_world(back.normalized()) * 0.6)
	await _seconds(0.25)
	_set_stick(Vector2.ZERO)
	_joy(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _until(func() -> bool: return player.weapon.phase == WeaponController.Phase.ACTIVE)
	await _seconds(0.05)
	await _shot("22_player_counter_hit")
	_joy(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _seconds(0.5)
	print("QA counter enemy_hp=%d enemy_state=%s" % [int(enemy.hp), Scrapling.State.keys()[enemy.state]])

	# Gegner über die Kante schlagen → Sieg.
	main.call("restart")
	await _seconds(0.3)
	enemy.target = null
	enemy.global_position = Vector3(5.9, 0, 0)
	enemy.rotation.y = PlayerController.yaw_for_direction(Vector3.LEFT)
	player.global_position = Vector3(4.6, 0, 0)
	player.facing_direction = Vector3.RIGHT
	await _seconds(0.5)
	_joy(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _seconds(0.1)
	_joy(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _seconds(0.5)
	await _shot("23_enemy_over_edge")
	await _until(func() -> bool: return (main.get("result_overlay") as EncounterOverlay).is_open())
	await _shot("24_victory_overlay")
	print("QA victory enemy_defeats=%d reason=%s" % [enemy.defeat_count, Scrapling.DefeatReason.keys()[enemy.last_defeat_reason]])
	await _click_restart()
	await _seconds(0.3)
	await _shot("25_after_restart")

	# Spielertod → Niederlage-Anzeige → Neustart.
	player.hp = 10.0
	_place_enemy_near_player(1.35)
	await _until(func() -> bool: return player.state == PlayerController.State.DEAD, 4.0)
	await _seconds(0.5)
	await _shot("26_player_defeated")
	await _until(func() -> bool: return (main.get("result_overlay") as EncounterOverlay).is_open())
	await _shot("27_defeat_overlay")
	await _click_restart()
	await _seconds(0.3)
	print("QA restart player_hp=%d enemy_hp=%d encounter=%s" % [int(player.hp), int(enemy.hp), TrainingArena.Encounter.keys()[arena.encounter]])
	(main.get("pause_menu") as PauseMenu).open()
	await _seconds(0.3)
	await _shot("28_pause_combat")
	(main.get("pause_menu") as PauseMenu).close()
	await _seconds(0.2)


func _place_enemy_near_player(distance: float) -> void:
	var enemy: Scrapling = arena.enemy
	var dir := Vector3(1, 0, -0.6).normalized()
	enemy.global_position = player.global_position + dir * distance
	enemy.rotation.y = PlayerController.yaw_for_direction(-dir)
	enemy.velocity = Vector3.ZERO
	enemy.target = player
	player.facing_direction = dir


func _stick_axes_for_world(direction: Vector3) -> Vector2:
	var b := camera.global_basis
	var right := Vector3(b.x.x, 0, b.x.z).normalized()
	var forward := Vector3(-b.z.x, 0, -b.z.z).normalized()
	return Vector2(direction.dot(right), -direction.dot(forward))


func _click_restart() -> void:
	var overlay := main.get("result_overlay") as EncounterOverlay
	var button: Button = overlay.get_node("Dim/Center/Panel/Margin/VBox/RestartButton")
	var center := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = center
		e.global_position = center
		_push(e)


# --- M2B-Gruppensequenz --------------------------------------------------------------

func _group_sequence() -> void:
	main.call("set_mode", TrainingArena.Mode.GROUP)
	await _seconds(0.4)
	await _shot("29_group_start")
	print("QA group start remaining=%d profile=%s" % [arena.enemies_remaining(), arena.profile_name()])
	await _measure_rates(2.0)
	# Skriptkampf: RT gehalten, zum nächsten Gegner laufen (mit Kantenvorsicht) – als Zeitreihe.
	main.call("restart")
	await _seconds(0.3)
	player.hp = 1000.0
	var multi_windup_shot := [false]
	_joy(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _contact_sheet("30_group_fight_sheet", 4.0, 40, func(_t: float) -> void:
		_drive_hold_forward()
		if not multi_windup_shot[0] and _enemies_in_windup() >= 2:
			multi_windup_shot[0] = true
			print("QA multiple windups visible"))
	_joy(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_set_stick(Vector2.ZERO)
	# Gleichzeitige Ankündigungen: Spieler steht, alle drei holen gleichzeitig aus.
	main.call("restart")
	await _seconds(0.3)
	_arrange_three_around_player(1.3)
	await _until(func() -> bool: return _enemies_committed() >= 3)
	await _seconds(0.1)
	await _shot("31_group_three_telegraphs")
	await _until(func() -> bool: return arena.enemy.weapon.phase == WeaponController.Phase.ACTIVE)
	await _seconds(0.03)
	await _shot("32_group_three_hits")
	print("QA group simultaneous player_hp=%d" % int(player.hp))
	# Profilwechsel per Klick im Pausemenü.
	var pause := main.get("pause_menu") as PauseMenu
	pause.open()
	await _seconds(0.3)
	await _click_button(pause.get_node("Dim/Center/Panel/Margin/VBox/ProfileButton"))
	await _seconds(0.3)
	pause.open()
	await _seconds(0.3)
	await _shot("33_pause_group_profile_b")
	print("QA profile after click=%s paused=%s" % [arena.profile_name(), get_tree().paused])
	pause.close()
	await _seconds(0.3)
	await _shot("34_group_profile_b_hud")
	# Sieg: zwei Gegner per HP, der dritte per Kante.
	for e in arena.active_enemies:
		e.stop_combat()
	var lethal := HitInfo.new()
	lethal.damage = 80.0
	arena.active_enemies[0].receive_hit(lethal)
	arena.active_enemies[1].receive_hit(lethal)
	var last: Scrapling = arena.active_enemies[2]
	last.global_position = Vector3(5.9, 0, 0)
	player.global_position = Vector3(4.6, 0, 0)
	player.facing_direction = Vector3.RIGHT
	await _seconds(0.4)
	_joy(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _seconds(0.1)
	_joy(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _until(func() -> bool: return (main.get("result_overlay") as EncounterOverlay).is_open(), 4.0)
	await _shot("35_group_victory")
	await _click_restart()
	await _seconds(0.3)
	# Niederlage in der Gruppe.
	player.hp = 20.0
	await _until(func() -> bool: return (main.get("result_overlay") as EncounterOverlay).is_open(), 8.0)
	await _shot("36_group_defeat")
	await _click_restart()
	await _seconds(0.3)
	# Spielerfall in der Gruppe → Reset.
	player.global_position = Vector3(5.8, 0, 3.0)
	_set_stick(_stick_axes_for_world(Vector3.RIGHT))
	await _until(func() -> bool: return player.state == PlayerController.State.FALLING)
	await _seconds(0.15)
	await _shot("37_group_player_fall")
	_set_stick(Vector2.ZERO)
	await _until(func() -> bool: return player.state == PlayerController.State.MOVE and player.global_position.y > -0.5)
	await _seconds(0.3)
	await _shot("38_group_after_fall_reset")
	if arena.last_stats != null:
		print("QA last summary: %s" % arena.last_stats.to_line())


func _group_movie() -> void:
	main.call("set_mode", TrainingArena.Mode.GROUP)
	await _seconds(0.8)
	_joy(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	var start := Time.get_ticks_msec()
	while (Time.get_ticks_msec() - start) < 14000 and arena.encounter == TrainingArena.Encounter.RUNNING:
		_drive_hold_forward()
		await get_tree().physics_frame
	_joy(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_set_stick(Vector2.ZERO)
	await _seconds(1.5)
	if arena.last_stats != null:
		print("QA movie summary: %s" % arena.last_stats.to_line())


## Skript: zum nächsten lebenden Gegner laufen, nicht in Kantennähe (1,2 m Sicherheitsabstand).
func _drive_hold_forward() -> void:
	var best: Node3D = null
	for e in arena.combatants():
		if not bool(e.get("is_defeated")) and e.visible and (best == null or e.global_position.distance_to(player.global_position) < best.global_position.distance_to(player.global_position)):
			best = e
	if best == null:
		_set_stick(Vector2.ZERO)
		return
	var to := best.global_position - player.global_position
	to.y = 0
	var step := player.global_position + to.normalized() * 1.2
	var near_edge := absf(step.x) > 5.9 or absf(step.z) > 4.4
	_set_stick(_stick_axes_for_world(to.normalized()) if to.length() > 1.3 and not near_edge else Vector2.ZERO)


func _enemies_in_windup() -> int:
	var count := 0
	for e in arena.active_enemies:
		if e.weapon.phase == WeaponController.Phase.WINDUP:
			count += 1
	return count


func _enemies_committed() -> int:
	var count := 0
	for e in arena.active_enemies:
		if e.is_committed():
			count += 1
	return count


func _arrange_three_around_player(distance: float) -> void:
	player.global_position = Vector3(0, 0, -0.5)
	for i in arena.active_enemies.size():
		var e := arena.active_enemies[i]
		var angle := TAU * i / 3.0 + 0.4
		var dir := Vector3(cos(angle), 0, sin(angle))
		e.global_position = player.global_position + dir * distance
		e.rotation.y = PlayerController.yaw_for_direction(-dir)
		e.velocity = Vector3.ZERO
		e.target = player


func _click_button(button: Button) -> void:
	var center := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = center
		e.global_position = center
		_push(e)
	await get_tree().process_frame


# --- M2C-Mischkampf ----------------------------------------------------------------

func _mixed_sequence() -> void:
	main.call("set_mode", TrainingArena.Mode.MIXED)
	main.call("set_profile", TrainingArena.StunProfile.SHORT)
	await _seconds(0.4)
	await _shot("39_mixed_start")
	var in_view := 0
	for c in arena.combatants():
		if camera.is_position_in_frustum(c.global_position + Vector3.UP * 0.6):
			in_view += 1
	print("QA mixed start in_view=%d/%d profile=%s" % [in_view, arena.combatants().size(), arena.profile_name()])
	await _measure_rates(2.0)
	# Aufladezyklus des Funkenwerfers als Zeitreihe (Scraplings ruhen abseits).
	main.call("restart")
	await _seconds(0.2)
	_mixed_isolate_sparker()
	var s: Sparker = arena.sparker
	await _contact_sheet("40_sparker_charge_sheet", 2.2, 32, func(_t: float) -> void: pass, s)
	main.call("restart")
	await _seconds(0.2)
	_mixed_isolate_sparker()
	await _until(func() -> bool: return s.state == Sparker.State.CHARGE and s.charge_progress() > 0.3)
	await _shot("41_sparker_charging")
	await _until(func() -> bool: return s.is_committed() and s.charge_progress() > 0.85)
	await _shot("42_sparker_committed")
	await _until(func() -> bool: return arena.projectiles.get_child_count() > 0)
	await _seconds(0.2)
	await _shot("43_bolt_in_flight")
	await _seconds(0.6)
	print("QA bolt player_hp=%d" % int(player.hp))
	# Ausweichen per Dodge durch den Bolzen, danach Annäherung und Hammer.
	await _until(func() -> bool: return s.is_committed(), 4.0)
	await _until(func() -> bool: return arena.projectiles.get_child_count() > 0)
	var bolt := arena.projectiles.get_child(0) as SparkBolt
	var hp_before := player.hp
	await _until(func() -> bool: return not is_instance_valid(bolt) or bolt.global_position.distance_to(player.global_position + Vector3.UP * 0.85) < 1.4)
	var side := Vector3(-bolt.direction.z, 0, bolt.direction.x) if is_instance_valid(bolt) else Vector3.RIGHT
	_set_stick(_stick_axes_for_world(side))
	_joy(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await _seconds(0.07)
	await _shot("44_dodge_bolt")
	_joy(JOY_AXIS_TRIGGER_LEFT, 0.0)
	_set_stick(Vector2.ZERO)
	await _seconds(0.5)
	print("QA dodge bolt hp_before=%d hp_after=%d" % [int(hp_before), int(player.hp)])
	var to := s.global_position - player.global_position
	to.y = 0
	_set_stick(_stick_axes_for_world(to.normalized()))
	await _until(func() -> bool: return player.global_position.distance_to(s.global_position) < 1.5, 3.0)
	_set_stick(Vector2.ZERO)
	_joy(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _until(func() -> bool: return s.state == Sparker.State.HIT or s.is_defeated, 2.0)
	await _seconds(0.05)
	await _shot("45_sparker_hit")
	_joy(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	print("QA sparker after hammer hp=%d state=%s" % [int(s.hp), Sparker.State.keys()[s.state]])
	# Funkenwerfer über die Kante.
	main.call("restart")
	await _seconds(0.2)
	for c in arena.combatants():
		c.call("stop_combat")
	s.global_position = Vector3(5.9, 0, 0)
	s.rotation.y = PlayerController.yaw_for_direction(Vector3.LEFT)
	player.global_position = Vector3(4.6, 0, 0)
	await _seconds(0.4)
	# Facing erst unmittelbar vor dem Controller-Druck setzen (sonst überschreibt eine aktive Mausquelle es).
	player.facing_direction = Vector3.RIGHT
	player.rotation.y = PlayerController.yaw_for_direction(Vector3.RIGHT)
	_joy(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _seconds(0.1)
	_joy(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _seconds(0.5)
	await _shot("46_sparker_over_edge")
	await _until(func() -> bool: return s.is_defeated, 2.0)  # Fall bis zur Killhöhe dauert ≈0,75 s
	print("QA sparker edge defeated=%s reason=%s" % [s.is_defeated, Sparker.DefeatReason.keys()[s.last_defeat_reason]])
	# Skriptkampf als Zeitreihe um den Spieler (RT gehalten, nächster Gegner, Kantenvorsicht).
	main.call("restart")
	await _seconds(0.3)
	_joy(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _contact_sheet("47_mixed_fight_sheet", 5.0, 40, func(_t: float) -> void: _drive_hold_forward())
	_joy(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_set_stick(Vector2.ZERO)
	# Sieg, Niederlage, Spielerfall.
	main.call("restart")
	await _seconds(0.3)
	for c in arena.combatants():
		c.call("stop_combat")
	var lethal := HitInfo.new()
	lethal.damage = 200.0
	arena.active_enemies[0].receive_hit(lethal)
	arena.active_enemies[1].receive_hit(lethal)
	s.receive_hit(lethal)
	await _until(func() -> bool: return (main.get("result_overlay") as EncounterOverlay).is_open(), 3.0)
	await _shot("48_mixed_victory")
	await _click_restart()
	await _seconds(0.3)
	player.hp = 15.0
	await _until(func() -> bool: return (main.get("result_overlay") as EncounterOverlay).is_open(), 10.0)
	await _shot("49_mixed_defeat")
	await _click_restart()
	await _seconds(0.3)
	player.global_position = Vector3(5.8, 0, 3.0)
	_set_stick(_stick_axes_for_world(Vector3.RIGHT))
	await _until(func() -> bool: return player.state == PlayerController.State.FALLING)
	await _seconds(0.15)
	await _shot("50_mixed_player_fall")
	_set_stick(Vector2.ZERO)
	await _until(func() -> bool: return player.state == PlayerController.State.MOVE and player.global_position.y > -0.5)
	await _seconds(0.3)
	await _shot("51_mixed_after_fall_reset")
	var pause := main.get("pause_menu") as PauseMenu
	pause.open()
	await _seconds(0.3)
	await _shot("52_pause_mixed")
	pause.close()
	await _seconds(0.2)


func _mixed_isolate_sparker() -> void:
	for c in arena.combatants():
		c.call("stop_combat")
	arena.active_enemies[0].global_position = Vector3(5.0, 0, -4.0)
	arena.active_enemies[1].global_position = Vector3(-5.5, 0, -4.0)
	var s: Sparker = arena.sparker
	player.global_position = Vector3(1.0, 0, 0.5)
	s.global_position = Vector3(-3.0, 0, 0.5)
	s.rotation.y = PlayerController.yaw_for_direction(Vector3.RIGHT)
	s.target = player


func _mixed_movie() -> void:
	main.call("set_mode", TrainingArena.Mode.MIXED)
	main.call("set_profile", TrainingArena.StunProfile.SHORT)
	await _seconds(0.8)
	_joy(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	var start := Time.get_ticks_msec()
	while (Time.get_ticks_msec() - start) < 30000 and arena.encounter == TrainingArena.Encounter.RUNNING:
		_drive_hold_forward()
		await get_tree().physics_frame
	_joy(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_set_stick(Vector2.ZERO)
	await _seconds(1.5)
	if arena.last_stats != null:
		print("QA movie summary: %s" % arena.last_stats.to_line())
