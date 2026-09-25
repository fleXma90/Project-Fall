class_name Hud
extends CanvasLayer
## Minimal-HUD: HP oben links, Pause oben rechts, optionale Debuganzeige.

signal pause_pressed

var _player: PlayerController = null
var _arena: TrainingArena = null
var _physics_ticks: int = 0
var _physics_rate: int = 0
var _rate_timer: float = 0.0

@onready var _safe_root: Control = $SafeRoot
@onready var _hp_bar: ProgressBar = $SafeRoot/HpPanel/Margin/VBox/HpBar
@onready var _hp_label: Label = $SafeRoot/HpPanel/Margin/VBox/HpLabel
@onready var _pause_button: Button = $SafeRoot/PauseButton
@onready var _debug_label: Label = $SafeRoot/DebugLabel


func _ready() -> void:
	_pause_button.pressed.connect(pause_pressed.emit)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


func bind(player: PlayerController, arena: TrainingArena) -> void:
	_player = player
	_arena = arena
	player.health_changed.connect(_on_health_changed)
	_on_health_changed(player.hp, player.tuning.max_hp)


func toggle_debug() -> void:
	_debug_label.visible = not _debug_label.visible


func _apply_safe_area() -> void:
	var rect := SafeArea.canvas_rect(get_viewport())
	_safe_root.position = rect.position
	_safe_root.size = rect.size


func _on_health_changed(current: float, maximum: float) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_hp_label.text = "HP %d / %d" % [int(ceil(current)), int(maximum)]


func _physics_process(_delta: float) -> void:
	_physics_ticks += 1


func _process(delta: float) -> void:
	_rate_timer += delta
	if _rate_timer >= 1.0:
		_physics_rate = roundi(_physics_ticks / _rate_timer)
		_physics_ticks = 0
		_rate_timer = 0.0
	if not _debug_label.visible or _player == null:
		return
	var facing := _player.facing_direction
	var lines: PackedStringArray = []
	lines.append("Eingabe: %s" % InputRouter.source_name())
	lines.append("Facing: (%.2f, %.2f)  Zustand: %s" % [facing.x, facing.z, PlayerController.State.keys()[_player.state]])
	lines.append("FPS %d  ·  Physik %d/s" % [Engine.get_frames_per_second(), _physics_rate])
	if _arena != null:
		lines.append("Dummies besiegt: HP %d · Kante %d  ·  Stürze: %d" % [
				_arena.dummy_hp_defeats, _arena.dummy_fall_defeats, _arena.player_fall_count])
	lines.append("F2 Touch-Test · F3 Debug · R Reset")
	_debug_label.text = "\n".join(lines)
