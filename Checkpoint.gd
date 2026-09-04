extends Area2D

signal activated(pos: Vector2)

var used: bool = false


func _ready() -> void:
	add_to_group("checkpoints")
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	var flag_color := Color(0.9, 0.8, 0.2) if used else Color(0.3, 0.7, 0.9)
	draw_rect(Rect2(-2, -34, 4, 34), Color(0.5, 0.5, 0.55))
	draw_circle(Vector2(0, -30), 7.0, flag_color)


func _on_body_entered(body: Node) -> void:
	if used or not body.has_method("respawn_at"):
		return
	used = true
	queue_redraw()
	activated.emit(global_position)
