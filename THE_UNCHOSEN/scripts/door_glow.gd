extends Node2D
## Additive layer for the light that leaks around a closed door.

func _draw() -> void:
	get_parent().draw_glow(self)
