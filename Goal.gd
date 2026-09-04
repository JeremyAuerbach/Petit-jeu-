extends Area2D


func _draw() -> void:
	draw_rect(Rect2(-2, -50, 4, 50), Color(0.4, 0.3, 0.2))
	draw_colored_polygon(
		PackedVector2Array([Vector2(2, -50), Vector2(30, -40), Vector2(2, -30)]),
		Color(0.9, 0.8, 0.1)
	)
