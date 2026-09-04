extends Area2D

@export var bounce_strength: float = 680.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	var radius: float = collision_shape.shape.radius
	draw_circle(Vector2.ZERO, radius, Color(0.85, 0.55, 0.15))
	draw_circle(Vector2.ZERO, radius * 0.55, Color(0.95, 0.75, 0.25))


func _on_body_entered(body: Node) -> void:
	if not body.has_method("bounce"):
		return
	var direction: Vector2 = body.position - position
	if direction.length() < 1.0:
		direction = Vector2.UP
	direction = direction.normalized()
	if direction.y > -0.3:
		direction.y = -0.3
		direction = direction.normalized()
	body.bounce(direction * bounce_strength)
