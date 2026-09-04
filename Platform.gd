extends StaticBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _draw() -> void:
	var size: Vector2 = collision_shape.shape.size
	draw_rect(Rect2(-size / 2.0, size), Color(0.36, 0.27, 0.2))
	draw_rect(Rect2(-size / 2.0, Vector2(size.x, 6.0)), Color(0.25, 0.55, 0.28))
