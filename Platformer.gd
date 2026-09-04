extends Node2D

@export var tile_size: int = 32
@export var level_bounds: Rect2 = Rect2(-50, -250, 2750, 900)
@export var fall_limit: float = 700.0

var finished: bool = false
var spawn_position: Vector2

@onready var player: CharacterBody2D = $Player
@onready var goal: Area2D = $Goal
@onready var hint_label: Label = $CanvasLayer/HintLabel
@onready var message_label: Label = $CanvasLayer/MessageLabel
@onready var dash_label: Label = $CanvasLayer/DashLabel


func _ready() -> void:
	spawn_position = player.position
	goal.body_entered.connect(_on_goal_entered)
	for hazard in get_tree().get_nodes_in_group("hazards"):
		hazard.body_entered.connect(_on_hazard_entered)
	for checkpoint in get_tree().get_nodes_in_group("checkpoints"):
		checkpoint.activated.connect(_on_checkpoint_activated)
	hint_label.text = "Fleches : bouger/grimper | ENTREE : sauter | X : dash"
	message_label.text = ""


func _draw() -> void:
	var start_col := int(floor(level_bounds.position.x / tile_size))
	var end_col := int(ceil((level_bounds.position.x + level_bounds.size.x) / tile_size))
	var start_row := int(floor(level_bounds.position.y / tile_size))
	var end_row := int(ceil((level_bounds.position.y + level_bounds.size.y) / tile_size))
	for y in range(start_row, end_row):
		for x in range(start_col, end_col):
			var shade: Color = Color(0.22, 0.24, 0.32) if (x + y) % 2 == 0 else Color(0.19, 0.21, 0.29)
			draw_rect(Rect2(x * tile_size, y * tile_size, tile_size, tile_size), shade)


func _process(_delta: float) -> void:
	if finished:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().change_scene_to_file("res://Main.tscn")
		return

	if player.position.y > fall_limit:
		_respawn_player()

	dash_label.text = "Dash : pret" if player.dashes_left > 0 else "Dash : recharge..."


func _respawn_player() -> void:
	player.respawn_at(spawn_position)


func _on_checkpoint_activated(pos: Vector2) -> void:
	spawn_position = pos


func _on_goal_entered(body: Node) -> void:
	if body == player and not finished:
		finished = true
		message_label.text = "TU AS ECHAPPE AU DONJON !\n\nAppuie sur ENTREE pour recommencer l'aventure"


func _on_hazard_entered(body: Node) -> void:
	if body == player:
		_respawn_player()
