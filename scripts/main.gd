extends Node3D
## Hauptszene: verbindet Arena, Player, Kamera, HUD, Touchcontrols, Pausemenü und Ergebnisanzeige.
## Startet standardmäßig in die M2A-Kampfbegegnung; der M1-Trainingsmodus ist über das Pausemenü
## (oder `-- --mode=training`) erreichbar.

const IMPACT_SCENE: PackedScene = preload("res://scenes/vfx/impact_burst.tscn")

## Startmodus; vor dem Einfügen in den Baum setzbar (Tests/QA).
@export var start_mode: TrainingArena.Mode = TrainingArena.Mode.COMBAT
## Verzögerung, bevor Sieg/Niederlage angezeigt wird (Pose/Umfallen bleibt sichtbar).
@export var result_delay: float = 0.9

var _result_generation: int = 0

@onready var arena: TrainingArena = $TrainingArena
@onready var player: PlayerController = $Player
@onready var camera_rig: CameraRig = $CameraRig
@onready var hud: Hud = $HUD
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var result_overlay: EncounterOverlay = $EncounterOverlay


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--mode=training":
			start_mode = TrainingArena.Mode.TRAINING
		elif arg == "--mode=combat":
			start_mode = TrainingArena.Mode.COMBAT
	arena.mode = start_mode
	arena.setup(player)
	camera_rig.target = player
	camera_rig.snap_to_target()
	hud.bind(player, arena)
	hud.pause_pressed.connect(pause_menu.open)
	pause_menu.reset_requested.connect(_on_restart_requested)
	pause_menu.mode_toggle_requested.connect(toggle_mode)
	result_overlay.restart_requested.connect(_on_restart_requested)
	result_overlay.mode_toggle_requested.connect(toggle_mode)
	arena.encounter_finished.connect(_on_encounter_finished)
	arena.restarted.connect(_on_arena_restarted)
	player.hit_landed.connect(_on_player_hit_landed)
	player.damaged.connect(_on_player_damaged)
	InputRouter.active_gamepad_disconnected.connect(pause_menu.open)
	if OS.get_cmdline_user_args().has("--touch-test"):
		InputRouter.set_touch_test_mode(true)
	_on_arena_restarted()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_reset"):
		restart()
	elif event.is_action_pressed("debug_toggle_overlay"):
		hud.toggle_debug()
	elif event.is_action_pressed("debug_toggle_touch"):
		InputRouter.set_touch_test_mode(not InputRouter.touch_test_mode)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_node_ready():
		pause_menu.open()


## Neustart der aktuellen Begegnung bzw. des Trainings; schließt Menüs und hebt die Pause auf.
func restart() -> void:
	arena.restart()


func set_mode(mode: TrainingArena.Mode) -> void:
	arena.set_mode(mode)


func toggle_mode() -> void:
	var in_combat := arena.mode == TrainingArena.Mode.COMBAT
	set_mode(TrainingArena.Mode.TRAINING if in_combat else TrainingArena.Mode.COMBAT)


func _on_restart_requested() -> void:
	restart()


func _on_arena_restarted() -> void:
	_result_generation += 1  # verwirft eine noch ausstehende Ergebnisanzeige
	result_overlay.hide_result()
	pause_menu.blocked = false
	pause_menu.close()
	get_tree().paused = false
	pause_menu.set_mode_labels(arena.mode == TrainingArena.Mode.COMBAT)
	InputRouter.release_all()


func _on_encounter_finished(victory: bool) -> void:
	get_tree().create_timer(result_delay, false).timeout.connect(_show_result.bind(victory, _result_generation))


func _show_result(victory: bool, generation: int) -> void:
	if generation != _result_generation:
		return
	pause_menu.close()
	pause_menu.blocked = true
	InputRouter.release_all()
	get_tree().paused = true  # keine Welt-Eingaben hinter der Ergebnisanzeige
	result_overlay.show_result(victory)


func _on_player_hit_landed(_target: Node3D, point: Vector3) -> void:
	arena.add_effect(IMPACT_SCENE.instantiate() as Node3D, point)
	camera_rig.add_shake(0.6, 0.09)


func _on_player_damaged(_hit: HitInfo) -> void:
	arena.add_effect(IMPACT_SCENE.instantiate() as Node3D, player.global_position + Vector3.UP * 0.8)
	camera_rig.add_shake(0.8, 0.1)
