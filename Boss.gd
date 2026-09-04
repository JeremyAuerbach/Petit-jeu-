extends "res://Enemy.gd"

const Projectile = preload("res://Projectile.tscn")

@export var attack_range: float = 260.0
@export var shoot_cooldown: float = 2.2
@export var projectile_speed: float = 160.0
@export var projectile_damage: int = 3

@onready var shoot_timer: Timer = $ShootTimer


func _ready() -> void:
	speed = 45.0
	max_hp = 60
	contact_damage = 4
	xp_reward = 25
	body_radius = 20.0

	super._ready()
	shoot_timer.wait_time = shoot_cooldown
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()


func _draw() -> void:
	var body := Color(0.6, 0.15, 0.15)
	draw_circle(Vector2(0, 14), 18.0, Color(0, 0, 0, 0.25))
	draw_circle(Vector2.ZERO, 22.0, body)
	draw_circle(Vector2(-7, -5), 5.0, Color(1, 1, 1))
	draw_circle(Vector2(7, -5), 5.0, Color(1, 1, 1))
	draw_circle(Vector2(-7, -5), 2.2, Color(0, 0, 0))
	draw_circle(Vector2(7, -5), 2.2, Color(0, 0, 0))
	draw_colored_polygon(
		PackedVector2Array(
			[Vector2(-14, -18), Vector2(-4, -30), Vector2(0, -20), Vector2(4, -30), Vector2(14, -18)]
		),
		Color(0.85, 0.7, 0.15)
	)

	var bar_width := 44.0
	var ratio: float = float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_width / 2.0, -38.0, bar_width, 6.0), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(-bar_width / 2.0, -38.0, bar_width * ratio, 6.0), Color(0.9, 0.25, 0.2))


func _on_shoot_timer_timeout() -> void:
	if not is_instance_valid(player):
		return
	if position.distance_to(player.position) > attack_range:
		return

	var projectile := Projectile.instantiate()
	projectile.position = position
	projectile.direction = (player.position - position).normalized()
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	get_parent().add_child(projectile)
