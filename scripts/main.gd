extends Node3D
## Hauptszene: verbindet Arena, Player, Kamera, HUD, Touchcontrols, Pausemenü und Ergebnisanzeige.
## Startet standardmäßig in den M2C-Mischkampf (2 Scraplings + Funkenwerfer) mit Profil B.
## Gruppe (M2B), Duell (M2A) und Training (M1) sind über das Pausemenü erreichbar.
## Startargumente: `-- --mode=mixed|group|combat|duel|training` und `-- --profile=a|b`.
## Rundenzusammenfassungen werden ausgegeben und lokal in user://encounter_log.txt angehängt;
## automatisierte Läufe (headless oder mit `log_tag`) werden dort gekennzeichnet.

const IMPACT_SCENE: PackedScene = preload("res://scenes/vfx/impact_burst.tscn")
const LOG_PATH: String = "user://encounter_log.txt"
const MODE_CYCLE: Array[TrainingArena.Mode] = [TrainingArena.Mode.MIXED, TrainingArena.Mode.GROUP, TrainingArena.Mode.COMBAT, TrainingArena.Mode.TRAINING]

## Startszenario/-profil; vor dem Einfügen in den Baum setzbar (Tests/QA).
@export var start_mode: TrainingArena.Mode = TrainingArena.Mode.MIXED
## Seit M2C ist Profil B (0.20 s) der normale Arbeitsstand; A bleibt explizit wählbar.
@export var start_profile: TrainingArena.StunProfile = TrainingArena.StunProfile.SHORT
## Verzögerung, bevor Sieg/Niederlage angezeigt wird (Pose/Umfallen bleibt sichtbar).
@export var result_delay: float = 0.9
## Rundenzusammenfassungen zusätzlich in LOG_PATH schreiben (Tests schalten das ab).
@export var write_log: bool = true
## Kennzeichnung automatisierter Läufe im Log (z. B. QA); headless wird automatisch gekennzeichnet.
@export var log_tag: String = ""

var _result_generation: int = 0

@onready var arena: TrainingArena = $TrainingArena
@onready var player: PlayerController = $Player
@onready var camera_rig: CameraRig = $CameraRig
@onready var hud: Hud = $HUD
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var result_overlay: EncounterOverlay = $EncounterOverlay


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		match arg:
			"--mode=training":
				start_mode = TrainingArena.Mode.TRAINING
			"--mode=combat", "--mode=duel":
				start_mode = TrainingArena.Mode.COMBAT
			"--mode=group":
				start_mode = TrainingArena.Mode.GROUP
			"--mode=mixed":
				start_mode = TrainingArena.Mode.MIXED
			"--profile=a", "--stun=base":
				start_profile = TrainingArena.StunProfile.BASE
			"--profile=b", "--stun=short":
				start_profile = TrainingArena.StunProfile.SHORT
	arena.mode = start_mode
	arena.stun_profile = start_profile
	arena.round_summarized.connect(_on_round_summarized)
	arena.setup(player)
	camera_rig.target = player
	camera_rig.snap_to_target()
	hud.bind(player, arena)
	hud.pause_pressed.connect(pause_menu.open)
	pause_menu.reset_requested.connect(_on_restart_requested)
	pause_menu.mode_toggle_requested.connect(toggle_mode)
	pause_menu.profile_toggle_requested.connect(toggle_profile)
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


func set_profile(profile: TrainingArena.StunProfile) -> void:
	arena.set_stun_profile(profile)


static func next_mode(mode: TrainingArena.Mode) -> TrainingArena.Mode:
	return MODE_CYCLE[(MODE_CYCLE.find(mode) + 1) % MODE_CYCLE.size()]


## Zyklus Gruppe → Duell → Training → Gruppe (jeweils mit vollständigem Neustart).
func toggle_mode() -> void:
	set_mode(next_mode(arena.mode))


func toggle_profile() -> void:
	var short := arena.stun_profile == TrainingArena.StunProfile.SHORT
	set_profile(TrainingArena.StunProfile.BASE if short else TrainingArena.StunProfile.SHORT)


func _on_restart_requested() -> void:
	restart()


func _on_arena_restarted() -> void:
	_result_generation += 1  # verwirft eine noch ausstehende Ergebnisanzeige
	result_overlay.hide_result()
	pause_menu.blocked = false
	pause_menu.close()
	get_tree().paused = false
	var next_name := TrainingArena.scenario_name(next_mode(arena.mode))
	pause_menu.set_labels(TrainingArena.scenario_name(arena.mode), next_name, arena.profile_name(), arena.is_combat_mode())
	result_overlay.set_next_scenario(next_name)
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
	var summary := arena.last_stats.to_line() if arena.last_stats != null else ""
	result_overlay.show_result(victory, TrainingArena.scenario_name(arena.mode), summary)


func _on_round_summarized(stats: EncounterStats) -> void:
	var tag := log_tag
	if tag.is_empty() and DisplayServer.get_name() == "headless":
		tag = "AUTOMATISIERT (headless)"
	var line := "[%s]%s %s" % [Time.get_datetime_string_from_system(), " [%s]" % tag if not tag.is_empty() else "", stats.to_line()]
	print("RUNDE ", line)
	if not write_log:
		return
	var file := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE if FileAccess.file_exists(LOG_PATH) else FileAccess.WRITE)
	if file != null:
		file.seek_end()
		file.store_line(line)


func _on_player_hit_landed(_target: Node3D, point: Vector3) -> void:
	arena.add_effect(IMPACT_SCENE.instantiate() as Node3D, point)
	camera_rig.add_shake(0.6, 0.09)


func _on_player_damaged(_hit: HitInfo) -> void:
	arena.add_effect(IMPACT_SCENE.instantiate() as Node3D, player.global_position + Vector3.UP * 0.8)
	camera_rig.add_shake(0.8, 0.1)
