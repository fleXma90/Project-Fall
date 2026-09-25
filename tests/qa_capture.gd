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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-out="):
			_out_dir = "res://" + arg.trim_prefix("--qa-out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	main = MAIN_SCENE.instantiate()
	add_child(main)
	player = main.get("player")
	arena = main.get("arena")
	camera = (main.get("camera_rig") as CameraRig).camera
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
