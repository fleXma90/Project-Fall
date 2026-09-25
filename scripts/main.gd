extends Node3D
## Hauptszene: verbindet Arena, Player, Kamera, HUD, Touchcontrols und Pausemenü.

const IMPACT_SCENE: PackedScene = preload("res://scenes/vfx/impact_burst.tscn")

@onready var arena: TrainingArena = $TrainingArena
@onready var player: PlayerController = $Player
@onready var camera_rig: CameraRig = $CameraRig
@onready var hud: Hud = $HUD
@onready var pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	arena.setup(player)
	camera_rig.target = player
	camera_rig.snap_to_target()
	hud.bind(player, arena)
	hud.pause_pressed.connect(pause_menu.open)
	pause_menu.reset_requested.connect(_on_reset_requested)
	player.hit_landed.connect(_on_player_hit_landed)
	InputRouter.active_gamepad_disconnected.connect(pause_menu.open)
	if OS.get_cmdline_user_args().has("--touch-test"):
		InputRouter.set_touch_test_mode(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_reset"):
		arena.reset_training()
	elif event.is_action_pressed("debug_toggle_overlay"):
		hud.toggle_debug()
	elif event.is_action_pressed("debug_toggle_touch"):
		InputRouter.set_touch_test_mode(not InputRouter.touch_test_mode)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_node_ready():
		pause_menu.open()


func _on_reset_requested() -> void:
	arena.reset_training()
	pause_menu.close()


func _on_player_hit_landed(_target: Node3D, point: Vector3) -> void:
	var impact := IMPACT_SCENE.instantiate() as Node3D
	# Position vor add_child setzen: die Partikel starten in _ready.
	impact.position = arena.to_local(point)
	arena.add_child(impact)
	camera_rig.add_shake(0.6, 0.09)
