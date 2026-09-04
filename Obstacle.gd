extends Node2D

@export var radius: float = 18.0


func _ready() -> void:
	add_to_group("obstacles")


func _draw() -> void:
	draw_circle(Vector2(0, radius * 0.35), radius * 0.7, Color(0, 0, 0, 0.15))
	draw_rect(Rect2(-4, -2, 8, radius * 0.6), Color(0.36, 0.25, 0.14))
	draw_circle(Vector2(0, -radius * 0.35), radius, Color(0.13, 0.42, 0.19))
