extends RefCounted
## Small shared helpers for the scenes, so fades are written once.


static func fade(c: CanvasItem, alpha: float, dur: float) -> Tween:
	var tw := c.create_tween()
	tw.tween_property(c, "modulate:a", alpha, dur)
	return tw


static func fade_all(items: Array, alpha: float, dur: float) -> void:
	for c: CanvasItem in items:
		fade(c, alpha, dur)
