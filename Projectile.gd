extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 160.0
var damage: int = 3

var screen_size: Vector2


func _ready() -> void:
	screen_size = get_viewport_rect().size
	area_entered.connect(_on_area_entered)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(0.9, 0.55, 0.15))
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.85, 0.4))


func _process(delta: float) -> void:
	position += direction * speed * delta
	if (
		position.x < -30.0
		or position.x > screen_size.x + 30.0
		or position.y < -30.0
		or position.y > screen_size.y + 30.0
	):
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player") and area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
