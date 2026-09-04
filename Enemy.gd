extends Area2D

signal died(xp_reward: int)

@export var speed: float = 90.0
@export var max_hp: int = 8
@export var contact_damage: int = 2
@export var xp_reward: int = 5
@export var body_radius: float = 11.0

var hp: int
var player: Node2D


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	player = get_tree().get_first_node_in_group("player")


func _draw() -> void:
	var body := Color(0.55, 0.2, 0.55)
	draw_circle(Vector2(0, 9), 10.0, Color(0, 0, 0, 0.2))
	draw_circle(Vector2.ZERO, 12.0, body)
	draw_circle(Vector2(-4, -3), 3.0, Color(1, 1, 1))
	draw_circle(Vector2(4, -3), 3.0, Color(1, 1, 1))
	draw_circle(Vector2(-4, -3), 1.4, Color(0, 0, 0))
	draw_circle(Vector2(4, -3), 1.4, Color(0, 0, 0))

	var bar_width := 24.0
	var ratio: float = float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_width / 2.0, -22.0, bar_width, 4.0), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(-bar_width / 2.0, -22.0, bar_width * ratio, 4.0), Color(0.2, 0.9, 0.3))


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
	var direction: Vector2 = player.position - position
	var target_position := position
	if direction.length() > 1.0:
		target_position += direction.normalized() * speed * delta
	position = _resolve_obstacles(target_position)


func _resolve_obstacles(target_position: Vector2) -> Vector2:
	var resolved := target_position
	for obstacle: Node2D in get_tree().get_nodes_in_group("obstacles"):
		var offset: Vector2 = resolved - obstacle.position
		var min_dist: float = body_radius + obstacle.radius
		var dist := offset.length()
		if dist < min_dist and dist > 0.001:
			resolved = obstacle.position + offset.normalized() * min_dist
	return resolved


func get_contact_damage() -> int:
	return contact_damage


func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	queue_redraw()
	if hp <= 0:
		died.emit(xp_reward)
		queue_free()
