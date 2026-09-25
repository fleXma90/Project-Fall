class_name SafeArea
extends RefCounted
## Liefert den sicheren UI-Bereich in Canvas-Koordinaten des Viewports.
## Auf Desktop ist das der ganze sichtbare Bereich; auf Mobilgeräten die Display-Safe-Area.


static func canvas_rect(viewport: Viewport) -> Rect2:
	var visible_rect := viewport.get_visible_rect()
	if not OS.has_feature("mobile"):
		return visible_rect
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return visible_rect
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var to_canvas := visible_rect.size / window_size
	var rect := Rect2(safe.position * to_canvas, safe.size * to_canvas)
	return rect.intersection(visible_rect) if rect.has_area() else visible_rect
