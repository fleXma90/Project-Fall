class_name PauseMenu
extends CanvasLayer
## Pausemenü: per Touch, Maus/Tastatur (Esc) und Controller (Start, D-Pad/Stick + A, B = weiter) bedienbar.

signal reset_requested
signal mode_toggle_requested
signal profile_toggle_requested
signal shot_toggle_requested

## Solange ein anderes modales Overlay (Ergebnisanzeige) offen ist, öffnet die Pause nicht.
var blocked: bool = false

@onready var _resume_button: Button = $Dim/Center/Panel/Margin/VBox/ResumeButton
@onready var _reset_button: Button = $Dim/Center/Panel/Margin/VBox/ResetButton
@onready var _mode_button: Button = $Dim/Center/Panel/Margin/VBox/ModeButton
@onready var _profile_button: Button = $Dim/Center/Panel/Margin/VBox/ProfileButton
@onready var _shot_button: Button = $Dim/Center/Panel/Margin/VBox/ShotButton
@onready var _touch_button: Button = $Dim/Center/Panel/Margin/VBox/TouchTestButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_resume_button.pressed.connect(close)
	_reset_button.pressed.connect(reset_requested.emit)
	_mode_button.pressed.connect(mode_toggle_requested.emit)
	_profile_button.pressed.connect(profile_toggle_requested.emit)
	_shot_button.pressed.connect(shot_toggle_requested.emit)
	_touch_button.pressed.connect(_toggle_touch_test)


func is_open() -> bool:
	return visible


## Beschriftungen: Szenario-Button wechselt zyklisch ins nächste Szenario, Profil-Button zwischen A/B.
## Beide Wechsel starten die Begegnung vollständig neu.
func set_labels(scenario: String, next_scenario: String, profile: String, in_combat: bool, shot_profile: String = "") -> void:
	_mode_button.text = "Szenario: %s  ›  %s" % [scenario, next_scenario]
	_profile_button.text = "Benommenheit: Profil %s  ›  wechseln" % profile
	_shot_button.text = "Funkenwerfer: %s  ›  wechseln" % shot_profile
	_reset_button.text = "Kampf neu starten" if in_combat else "Training zurücksetzen"


func open() -> void:
	if visible or blocked:
		return
	InputRouter.release_all()
	get_tree().paused = true
	visible = true
	_update_touch_label()
	_resume_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	InputRouter.release_all()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not blocked:
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _toggle_touch_test() -> void:
	InputRouter.set_touch_test_mode(not InputRouter.touch_test_mode)
	_update_touch_label()


func _update_touch_label() -> void:
	_touch_button.text = "Touch-Testmodus: %s" % ("an" if InputRouter.touch_test_mode else "aus")
