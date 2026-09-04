extends Area2D

signal died
signal hp_changed(hp: int, max_hp: int)
signal xp_changed(xp: int, xp_to_level: int)
signal leveled_up(level: int)

@export var speed: float = 200.0
@export var attack_damage: int = 3
@export var attack_range: float = 28.0
@export var invincibility_time: float = 0.6
@export var attack_duration: float = 0.15
@export var attack_cooldown: float = 0.35
@export var body_radius: float = 12.0
@export var regen_amount: int = 1
@export var regen_interval: float = 1.5

var max_hp: int = 12
var hp: int = 12
var level: int = 1
var xp: int = 0
var xp_to_level: int = 10

var facing: Vector2 = Vector2.DOWN
var screen_size: Vector2
var invincible: bool = false
var attacking: bool = false
var can_act: bool = true
var overlapping_enemies: Array = []

@onready var attack_area: Area2D = $AttackArea
@onready var invincibility_timer: Timer = $InvincibilityTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var regen_timer: Timer = $RegenTimer


func _ready() -> void:
	screen_size = get_viewport_rect().size
	add_to_group("player")
	hide()
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	attack_area.area_entered.connect(_on_attack_area_entered)
	invincibility_timer.timeout.connect(_on_invincibility_timeout)
	attack_timer.timeout.connect(_end_attack)
	regen_timer.timeout.connect(_on_regen_timer_timeout)
	attack_area.monitoring = false


func _draw() -> void:
	var tunic := Color(0.16, 0.55, 0.25)
	var skin := Color(0.94, 0.76, 0.6)
	var cap := Color(0.11, 0.42, 0.18)
	if invincible:
		tunic.a = 0.5
		skin.a = 0.5
		cap.a = 0.5

	draw_circle(Vector2(0, 13), 9.0, Color(0, 0, 0, 0.2))
	draw_rect(Rect2(-9, -4, 18, 17), tunic)
	draw_rect(Rect2(-9, 10, 18, 4), Color(0.42, 0.28, 0.1))
	draw_circle(Vector2(0, -10), 8.0, skin)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-9, -12), Vector2(9, -12), Vector2(0, -23)]),
		cap
	)

	if attacking:
		var tip := facing * attack_range
		draw_line(Vector2.ZERO, tip, Color(0.85, 0.85, 0.92), 4.0)
		draw_circle(tip, 4.0, Color(0.85, 0.85, 0.92))


func _process(delta: float) -> void:
	if not visible or not can_act:
		return

	var direction := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	if direction.length() > 0.0:
		direction = direction.normalized()
		facing = direction

	var target_position := position + direction * speed * delta
	target_position.x = clamp(target_position.x, 16.0, screen_size.x - 16.0)
	target_position.y = clamp(target_position.y, 16.0, screen_size.y - 16.0)
	position = _resolve_obstacles(target_position)

	if Input.is_action_just_pressed("ui_accept") and attack_cooldown_timer.is_stopped():
		_start_attack()

	queue_redraw()


func _resolve_obstacles(target_position: Vector2) -> Vector2:
	var resolved := target_position
	for obstacle: Node2D in get_tree().get_nodes_in_group("obstacles"):
		var offset: Vector2 = resolved - obstacle.position
		var min_dist: float = body_radius + obstacle.radius
		var dist := offset.length()
		if dist < min_dist and dist > 0.001:
			resolved = obstacle.position + offset.normalized() * min_dist
	return resolved


func start(pos: Vector2) -> void:
	position = pos
	max_hp = 12
	hp = max_hp
	level = 1
	xp = 0
	xp_to_level = 10
	attack_damage = 3
	facing = Vector2.DOWN
	invincible = false
	attacking = false
	can_act = true
	overlapping_enemies.clear()
	show()
	monitoring = true
	regen_timer.start(regen_interval)
	hp_changed.emit(hp, max_hp)
	xp_changed.emit(xp, xp_to_level)
	leveled_up.emit(level)


func _start_attack() -> void:
	attacking = true
	attack_area.position = facing * attack_range
	attack_area.monitoring = true
	attack_timer.start(attack_duration)
	attack_cooldown_timer.start(attack_cooldown)


func _end_attack() -> void:
	attacking = false
	attack_area.monitoring = false


func _on_attack_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") and area.has_method("take_damage"):
		area.take_damage(attack_damage)


func take_damage(amount: int) -> void:
	if invincible or hp <= 0:
		return
	hp = max(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		hide()
		monitoring = false
		died.emit()
		return
	invincible = true
	invincibility_timer.start(invincibility_time)


func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_level:
		xp -= xp_to_level
		level += 1
		xp_to_level = int(xp_to_level * 1.3)
		max_hp += 5
		attack_damage += 1
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_to_level)
	hp_changed.emit(hp, max_hp)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		overlapping_enemies.append(area)
		_try_contact_damage()


func _on_area_exited(area: Area2D) -> void:
	overlapping_enemies.erase(area)


func _on_regen_timer_timeout() -> void:
	if hp <= 0 or hp >= max_hp:
		return
	hp = min(max_hp, hp + regen_amount)
	hp_changed.emit(hp, max_hp)


func _on_invincibility_timeout() -> void:
	invincible = false
	_try_contact_damage()


func _try_contact_damage() -> void:
	if invincible or overlapping_enemies.is_empty():
		return
	var total := 0
	for enemy in overlapping_enemies:
		if is_instance_valid(enemy) and enemy.has_method("get_contact_damage"):
			total += enemy.get_contact_damage()
	if total > 0:
		take_damage(total)
