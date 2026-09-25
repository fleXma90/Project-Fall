class_name TouchControls
extends Control
## Geometrie und Darstellung der Touchcontrols. Finger-Besitz und Werte verwaltet der InputRouter;
## diese Control liefert nur Zonen (zone_at) und zeichnet den aktuellen Zustand.

@export var stick_radius: float = 90.0
@export var attack_radius: float = 96.0
@export var dodge_radius: float = 62.0
## Anteil der Bildschirmbreite (links), in dem ein Finger den dynamischen Stick startet.
@export var stick_zone_width: float = 0.45
## Oberer Anteil, der für HUD (HP/Pause) frei bleibt.
@export var top_reserved: float = 0.22

const COLOR_BASE := Color(1.0, 1.0, 1.0, 0.10)
const COLOR_RING := Color(1.0, 1.0, 1.0, 0.35)
const COLOR_ATTACK := Color(0.85, 0.28, 0.16, 0.55)
const COLOR_DODGE := Color(0.22, 0.42, 0.75, 0.55)
const COLOR_PRESSED := Color(1.0, 0.8, 0.45, 0.85)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	InputRouter.register_touch_layout(self)


func _exit_tree() -> void:
	InputRouter.unregister_touch_layout(self)


func _process(_delta: float) -> void:
	visible = InputRouter.touch_controls_wanted()
	if visible:
		queue_redraw()


func _safe_rect() -> Rect2:
	return SafeArea.canvas_rect(get_viewport())


func attack_center() -> Vector2:
	var r := _safe_rect()
	return r.end - Vector2(150.0, 140.0)


func dodge_center() -> Vector2:
	return attack_center() + Vector2(-190.0, 48.0)


func stick_rest_center() -> Vector2:
	var r := _safe_rect()
	return Vector2(r.position.x + 185.0, r.end.y - 165.0)


## Zone unter einem Touchpunkt (Viewport-Koordinaten). Rückgabe: InputRouter.TouchZone.
func zone_at(point: Vector2) -> int:
	if point.distance_to(attack_center()) <= attack_radius * 1.15:
		return InputRouter.TouchZone.ATTACK
	if point.distance_to(dodge_center()) <= dodge_radius * 1.25:
		return InputRouter.TouchZone.DODGE
	var r := _safe_rect()
	if point.x < r.position.x + r.size.x * stick_zone_width and point.y > r.position.y + r.size.y * top_reserved:
		return InputRouter.TouchZone.STICK
	return InputRouter.TouchZone.NONE


func _draw() -> void:
	var offset := -global_position
	var font := get_theme_default_font()

	# Stick: Ruheposition schwach, aktiv an Fingerposition.
	var stick_center := stick_rest_center()
	var knob := stick_center
	if InputRouter.touch_stick_active:
		stick_center = InputRouter.touch_stick_origin
		knob = stick_center + InputRouter.touch_stick_vector * stick_radius
	draw_circle(stick_center + offset, stick_radius, COLOR_BASE)
	draw_arc(stick_center + offset, stick_radius, 0.0, TAU, 48, COLOR_RING, 3.0, true)
	draw_circle(knob + offset, stick_radius * 0.42, COLOR_PRESSED if InputRouter.touch_stick_active else COLOR_RING)

	_draw_button(attack_center() + offset, attack_radius, COLOR_ATTACK, InputRouter.touch_attack_held, "ANGRIFF", font)
	_draw_button(dodge_center() + offset, dodge_radius, COLOR_DODGE, InputRouter.touch_dodge_held, "DODGE", font)


func _draw_button(center: Vector2, radius: float, color: Color, pressed: bool, label: String, font: Font) -> void:
	draw_circle(center, radius, COLOR_PRESSED if pressed else color)
	draw_arc(center, radius, 0.0, TAU, 48, COLOR_RING, 3.0, true)
	var font_size := 22 if radius > 80.0 else 17
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, center + Vector2(-text_size.x * 0.5, font_size * 0.35), label,
			HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1, 1, 1, 0.9))
