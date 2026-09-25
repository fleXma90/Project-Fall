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
@onready var _encounter_label: Label = $SafeRoot/EncounterLabel


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
	_update_encounter_label()
	if not _debug_label.visible or _player == null:
		return
	var lines: PackedStringArray = []
	lines.append("Eingabe: %s  ·  Zustand: %s" % [InputRouter.source_name(), PlayerController.State.keys()[_player.state]])
	# Getrennte Richtungen als Bildschirmwinkel (0° = oben, 90° = rechts).
	var velocity := Vector3(_player.velocity.x, 0.0, _player.velocity.z)
	var weapon := _player.weapon
	var swing := "—"
	if weapon.is_busy():
		swing = "%s %s %d%%" % [_screen_angle(weapon.direction), WeaponController.Phase.keys()[weapon.phase], roundi(weapon.phase_progress() * 100.0)]
	lines.append("Bewegung %s %.1f m/s · Facing %s · Körper %s · Schlag %s" % [
			_screen_angle(velocity) if velocity.length() > 0.1 else "—", velocity.length(),
			_screen_angle(_player.facing_direction), _screen_angle(_player.body_forward()), swing])
	lines.append("FPS %d  ·  Physik %d/s" % [Engine.get_frames_per_second(), _physics_rate])
	if _arena != null and _arena.is_combat_mode():
		var parts: PackedStringArray = []
		for enemy in _arena.active_enemies:
			var phase: String = WeaponController.Phase.keys()[enemy.weapon.phase].substr(0, 3) if enemy.weapon.is_busy() else "-"
			parts.append("%s/%s%s" % [Scrapling.State.keys()[enemy.state].substr(0, 5), phase, "!" if enemy.is_committed() else ""])
		for shooter in _arena.active_shooters:
			parts.append("Funke %s%s %d%%" % [Sparker.State.keys()[shooter.state].substr(0, 5), "!" if shooter.is_committed() else "",
					roundi(shooter.charge_progress() * 100.0)])
		lines.append("Scraplings: %s  (! = Richtung festgelegt)" % "  ·  ".join(parts))
	elif _arena != null:
		lines.append("Dummies besiegt: HP %d · Kante %d  ·  Stürze: %d" % [
				_arena.dummy_hp_defeats, _arena.dummy_fall_defeats, _arena.player_fall_count])
	lines.append("F2 Touch-Test · F3 Debug · R Reset")
	_debug_label.text = "\n".join(lines)


func _update_encounter_label() -> void:
	if _arena == null:
		return
	if _arena.mode == TrainingArena.Mode.TRAINING:
		_encounter_label.text = "TRAINING"
		return
	var status := ""
	match _arena.encounter:
		TrainingArena.Encounter.VICTORY:
			status = "  ·  Sieg"
		TrainingArena.Encounter.DEFEAT:
			status = "  ·  Niederlage"
	var enemies_text := "Gegner %d/%d" % [_arena.enemies_remaining(), _arena.combatants().size()]
	if _arena.mode == TrainingArena.Mode.COMBAT:
		enemies_text = "Scrapling HP %d/%d" % [int(ceil(_arena.enemy.hp)), int(_arena.enemy.tuning.max_hp)]
	_encounter_label.text = "%s  ·  %s  ·  Profil %s%s" % [TrainingArena.scenario_name(_arena.mode).to_upper(),
			enemies_text, _arena.profile_name().substr(0, 1), status]


func _screen_angle(direction: Vector3) -> String:
	var cam := get_viewport().get_camera_3d()
	if cam == null or direction.length_squared() < 0.0001:
		return "—"
	var b := cam.global_basis
	var right := Vector3(b.x.x, 0.0, b.x.z).normalized()
	var up := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
	var degrees := rad_to_deg(atan2(direction.dot(right), direction.dot(up)))
	return "%d°" % (roundi(fposmod(degrees, 360.0)) % 360)
