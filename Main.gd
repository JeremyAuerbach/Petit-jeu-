extends Node2D

const Enemy = preload("res://Enemy.tscn")
const Boss = preload("res://Boss.tscn")

@export var max_enemies: int = 10
@export var enemy_min_speed: float = 70.0
@export var enemy_max_speed: float = 140.0
@export var tile_size: int = 32
@export var boss_level: int = 6

var kills: int = 0
var game_running: bool = false
var spawn_interval: float = 2.0
var boss_spawned: bool = false

var npc_nearby: bool = false
var dialogue_active: bool = false
var dialogue_lines: PackedStringArray = []
var dialogue_index: int = 0

@onready var player: Area2D = $Player
@onready var npc: Area2D = $NPC
@onready var spawn_timer: Timer = $SpawnTimer
@onready var hp_label: Label = $CanvasLayer/HPLabel
@onready var level_label: Label = $CanvasLayer/LevelLabel
@onready var xp_label: Label = $CanvasLayer/XPLabel
@onready var message_label: Label = $CanvasLayer/MessageLabel
@onready var dialogue_panel: Panel = $CanvasLayer/DialoguePanel
@onready var dialogue_label: Label = $CanvasLayer/DialoguePanel/DialogueLabel
@onready var screen_size: Vector2 = get_viewport_rect().size


func _ready() -> void:
	player.died.connect(_on_player_died)
	player.hp_changed.connect(_on_hp_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.leveled_up.connect(_on_leveled_up)
	npc.player_nearby_changed.connect(_on_npc_nearby_changed)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	message_label.text = "DONJON\n\nAppuie sur ENTREE pour jouer\nFleches pour bouger, ENTREE pour attaquer"
	hp_label.text = ""
	level_label.text = ""
	xp_label.text = ""
	dialogue_panel.hide()


func _draw() -> void:
	var cols := int(ceil(screen_size.x / tile_size)) + 1
	var rows := int(ceil(screen_size.y / tile_size)) + 1
	for y in range(rows):
		for x in range(cols):
			var shade: Color = Color(0.30, 0.55, 0.27) if (x + y) % 2 == 0 else Color(0.27, 0.51, 0.24)
			draw_rect(Rect2(x * tile_size, y * tile_size, tile_size, tile_size), shade)


func _process(_delta: float) -> void:
	if dialogue_active:
		if Input.is_action_just_pressed("ui_accept"):
			_advance_dialogue()
		return

	if not game_running:
		if Input.is_action_just_pressed("ui_accept"):
			start_game()
		return

	if npc_nearby and Input.is_action_just_pressed("ui_accept"):
		_start_dialogue(npc.dialogue)


func start_game() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()

	game_running = true
	kills = 0
	boss_spawned = false
	spawn_interval = 2.0
	spawn_timer.wait_time = spawn_interval
	message_label.text = ""

	player.start(screen_size / 2)
	spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return

	var enemy := Enemy.instantiate()
	enemy.speed = randf_range(enemy_min_speed, enemy_max_speed)
	enemy.died.connect(_on_enemy_died)
	enemy.position = _random_edge_position()
	add_child(enemy)

	spawn_interval = max(0.6, spawn_interval - 0.03)
	spawn_timer.wait_time = spawn_interval


func _random_edge_position() -> Vector2:
	var side := randi() % 4
	match side:
		0:
			return Vector2(randf_range(0.0, screen_size.x), -20.0)
		1:
			return Vector2(randf_range(0.0, screen_size.x), screen_size.y + 20.0)
		2:
			return Vector2(-20.0, randf_range(0.0, screen_size.y))
		_:
			return Vector2(screen_size.x + 20.0, randf_range(0.0, screen_size.y))


func _on_enemy_died(xp_reward: int) -> void:
	kills += 1
	player.gain_xp(xp_reward)


func _on_hp_changed(hp: int, max_hp: int) -> void:
	hp_label.text = "PV : %d / %d" % [hp, max_hp]


func _on_xp_changed(xp: int, xp_to_level: int) -> void:
	xp_label.text = "XP : %d / %d" % [xp, xp_to_level]


func _on_leveled_up(level: int) -> void:
	level_label.text = "Niveau %d" % level
	if level >= boss_level and not boss_spawned:
		_spawn_boss()


func _spawn_boss() -> void:
	boss_spawned = true
	var boss := Boss.instantiate()
	boss.died.connect(_on_boss_died)
	boss.position = _random_edge_position()
	add_child(boss)
	message_label.text = "Un mini-boss apparait !"
	get_tree().create_timer(2.5).timeout.connect(
		func():
			if game_running:
				message_label.text = ""
	)


func _on_boss_died(xp_reward: int) -> void:
	kills += 1
	player.gain_xp(xp_reward)
	game_running = false
	spawn_timer.stop()
	message_label.text = "MINI-BOSS VAINCU !\n\nLe donjon s'effondre..."

	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()

	get_tree().create_timer(2.0).timeout.connect(
		func(): get_tree().change_scene_to_file("res://Platformer.tscn")
	)


func _on_npc_nearby_changed(nearby: bool) -> void:
	npc_nearby = nearby


func _start_dialogue(lines: PackedStringArray) -> void:
	if lines.is_empty():
		return
	dialogue_lines = lines
	dialogue_index = 0
	dialogue_active = true
	player.can_act = false
	dialogue_label.text = dialogue_lines[0]
	dialogue_panel.show()


func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		dialogue_active = false
		dialogue_panel.hide()
		player.can_act = true
	else:
		dialogue_label.text = dialogue_lines[dialogue_index]


func _on_player_died() -> void:
	game_running = false
	spawn_timer.stop()
	message_label.text = "DEFAITE\nNiveau atteint : %d\nEnnemis vaincus : %d\n\nAppuie sur ENTREE pour rejouer" % [player.level, kills]

	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
