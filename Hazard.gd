extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("hazards")


func _draw() -> void:
	var size: Vector2 = collision_shape.shape.size
	var spike_count: int = max(1, int(size.x / 16.0))
	var spike_width: float = size.x / float(spike_count)
	for i in range(spike_count):
		var x: float = -size.x / 2.0 + i * spike_width
		draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(x, size.y / 2.0),
					Vector2(x + spike_width / 2.0, -size.y / 2.0),
					Vector2(x + spike_width, size.y / 2.0)
				]
			),
			Color(0.7, 0.1, 0.1)
		)
