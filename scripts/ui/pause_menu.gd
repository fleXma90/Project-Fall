class_name PauseMenu
extends CanvasLayer
## Pausemenü: per Touch, Maus/Tastatur (Esc) und Controller (Start, D-Pad/Stick + A, B = weiter) bedienbar.

signal reset_requested

@onready var _resume_button: Button = $Dim/Center/Panel/Margin/VBox/ResumeButton
@onready var _reset_button: Button = $Dim/Center/Panel/Margin/VBox/ResetButton
@onready var _touch_button: Button = $Dim/Center/Panel/Margin/VBox/TouchTestButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_resume_button.pressed.connect(close)
	_reset_button.pressed.connect(reset_requested.emit)
	_touch_button.pressed.connect(_toggle_touch_test)


func is_open() -> bool:
	return visible


func open() -> void:
	if visible:
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
	if event.is_action_pressed("pause"):
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
