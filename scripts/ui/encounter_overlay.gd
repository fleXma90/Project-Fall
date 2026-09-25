class_name EncounterOverlay
extends CanvasLayer
## Ergebnisanzeige der Kampfbegegnung (Sieg/Niederlage) mit Neustart und Moduswechsel.
## Per Touch/Maus, Tastatur (Enter/R) und Controller (A, Steuerkreuz) bedienbar.

signal restart_requested
signal mode_toggle_requested

@onready var _title: Label = $Dim/Center/Panel/Margin/VBox/Title
@onready var _subtitle: Label = $Dim/Center/Panel/Margin/VBox/Subtitle
@onready var _restart_button: Button = $Dim/Center/Panel/Margin/VBox/RestartButton
@onready var _mode_button: Button = $Dim/Center/Panel/Margin/VBox/ModeButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_restart_button.pressed.connect(restart_requested.emit)
	_mode_button.pressed.connect(mode_toggle_requested.emit)


func is_open() -> bool:
	return visible


func set_next_scenario(scenario: String) -> void:
	_mode_button.text = "Szenario wechseln: %s" % scenario


## Ergebnis mit kurzer Rundenzusammenfassung (Dauer, Schaden, Gegnerangriffe).
func show_result(victory: bool, scenario: String, summary: String) -> void:
	var victory_title := "Scrapling besiegt!"
	if scenario == "Gruppe":
		victory_title = "Alle Scraplings besiegt!"
	elif scenario == "Gemischt":
		victory_title = "Alle Gegner besiegt!"
	_title.text = victory_title if victory else "Niederlage"
	_subtitle.text = summary
	_title.modulate = Color(1.0, 0.8, 0.35) if victory else Color(1.0, 0.4, 0.3)
	visible = true
	_restart_button.grab_focus()


func hide_result() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("debug_reset"):
		restart_requested.emit()
		get_viewport().set_input_as_handled()
