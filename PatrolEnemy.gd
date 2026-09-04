extends Area2D

@export var speed: float = 60.0
@export var patrol_distance: float = 100.0

var origin: Vector2
var direction: float = 1.0


func _ready() -> void:
	add_to_group("hazards")
	origin = position


func _draw() -> void:
	draw_circle(Vector2(0, 8), 10.0, Color(0, 0, 0, 0.2))
	draw_circle(Vector2.ZERO, 12.0, Color(0.55, 0.2, 0.55))
	draw_circle(Vector2(-4, -3), 3.0, Color(1, 1, 1))
	draw_circle(Vector2(4, -3), 3.0, Color(1, 1, 1))
	draw_circle(Vector2(-4, -3), 1.4, Color(0, 0, 0))
	draw_circle(Vector2(4, -3), 1.4, Color(0, 0, 0))


func _process(delta: float) -> void:
	position.x += direction * speed * delta
	if absf(position.x - origin.x) >= patrol_distance:
		direction *= -1.0
		position.x = origin.x + patrol_distance * direction
		queue_redraw()
