extends CharacterBody2D

const GRAVITY: float = 900.0
const MAX_FALL_SPEED: float = 700.0
const MOVE_SPEED: float = 220.0
const ACCEL_GROUND: float = 1600.0
const ACCEL_AIR: float = 900.0
const FRICTION: float = 1400.0
const JUMP_VELOCITY: float = -420.0
const JUMP_CUT_MULTIPLIER: float = 0.5
const COYOTE_TIME: float = 0.1
const JUMP_BUFFER_TIME: float = 0.12
const DASH_SPEED: float = 480.0
const DASH_DURATION: float = 0.15
const DASH_COOLDOWN: float = 0.4
const WALL_SLIDE_SPEED: float = 90.0
const WALL_JUMP_VELOCITY: float = -380.0
const WALL_JUMP_PUSH: float = 260.0
const WALL_JUMP_LOCK_TIME: float = 0.15
const WALL_COYOTE_TIME: float = 0.1

@export var max_dashes: int = 1

var dashes_left: int = 1
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var wall_coyote_timer: float = 0.0
var wall_jump_lock_timer: float = 0.0
var wall_normal_cache: Vector2 = Vector2.ZERO
var facing: float = 1.0


func _draw() -> void:
	var color := Color(0.16, 0.55, 0.25)
	if is_dashing:
		color = Color(0.95, 0.85, 0.3)
	elif wall_coyote_timer > 0.0 and not is_on_floor():
		color = Color(0.25, 0.65, 0.75)
	draw_rect(Rect2(-10, -16, 20, 32), color)
	draw_circle(Vector2(facing * 6.0, -8.0), 3.0, Color(0.1, 0.1, 0.1))


func _physics_process(delta: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if Input.is_action_just_pressed("dash") and dashes_left > 0 and not is_dashing and dash_cooldown_timer <= 0.0:
		_start_dash()

	if is_dashing:
		_process_dash(delta)
	else:
		_process_movement(delta)

	move_and_slide()

	if is_on_floor():
		dashes_left = max_dashes
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	if is_on_wall_only():
		wall_coyote_timer = WALL_COYOTE_TIME
		wall_normal_cache = get_wall_normal()
		dashes_left = max_dashes
	else:
		wall_coyote_timer = max(0.0, wall_coyote_timer - delta)

	queue_redraw()


func _process_movement(delta: float) -> void:
	var input_dir := Input.get_axis("ui_left", "ui_right")

	if wall_jump_lock_timer > 0.0:
		wall_jump_lock_timer -= delta
	else:
		if input_dir != 0.0:
			facing = sign(input_dir)
		var accel: float = ACCEL_GROUND if is_on_floor() else ACCEL_AIR
		if input_dir != 0.0:
			velocity.x = move_toward(velocity.x, input_dir * MOVE_SPEED, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

	var pressing_into_wall: bool = (
		wall_coyote_timer > 0.0
		and not is_on_floor()
		and input_dir != 0.0
		and sign(input_dir) == -sign(wall_normal_cache.x)
	)
	if pressing_into_wall and velocity.y > WALL_SLIDE_SPEED:
		velocity.y = WALL_SLIDE_SPEED

	jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = JUMP_BUFFER_TIME

	if jump_buffer_timer > 0.0:
		if is_on_floor() or coyote_timer > 0.0:
			velocity.y = JUMP_VELOCITY
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
		elif wall_coyote_timer > 0.0:
			velocity.y = WALL_JUMP_VELOCITY
			velocity.x = wall_normal_cache.x * WALL_JUMP_PUSH
			if wall_normal_cache.x != 0.0:
				facing = sign(wall_normal_cache.x)
			wall_jump_lock_timer = WALL_JUMP_LOCK_TIME
			jump_buffer_timer = 0.0
			wall_coyote_timer = 0.0

	if Input.is_action_just_released("ui_accept") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER


func _start_dash() -> void:
	var input_vec := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	dash_direction = input_vec.normalized() if input_vec.length() > 0.0 else Vector2(facing, 0.0)
	is_dashing = true
	dash_timer = DASH_DURATION
	dashes_left -= 1
	dash_cooldown_timer = DASH_COOLDOWN
	velocity = dash_direction * DASH_SPEED


func _process_dash(delta: float) -> void:
	dash_timer -= delta
	velocity = dash_direction * DASH_SPEED
	if dash_timer <= 0.0:
		is_dashing = false
		velocity *= 0.5


func bounce(impulse: Vector2) -> void:
	velocity = impulse
	is_dashing = false
	dashes_left = max_dashes
	coyote_timer = 0.0
	wall_coyote_timer = 0.0
	wall_jump_lock_timer = 0.0


func respawn_at(pos: Vector2) -> void:
	position = pos
	velocity = Vector2.ZERO
	is_dashing = false
	dashes_left = max_dashes
	dash_cooldown_timer = 0.0
	wall_coyote_timer = 0.0
	wall_jump_lock_timer = 0.0
