extends Area2D

signal player_nearby_changed(nearby: bool)

@export var dialogue: PackedStringArray = [
	"Bonjour, aventurier !",
	"Prends garde aux monstres qui rodent dans les environs...",
	"Appuie sur ENTREE pres de moi pour me parler a nouveau."
]

var player_nearby: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _draw() -> void:
	var robe := Color(0.55, 0.25, 0.2)
	var skin := Color(0.94, 0.76, 0.6)
	var hair := Color(0.75, 0.75, 0.75)

	draw_circle(Vector2(0, 13), 9.0, Color(0, 0, 0, 0.2))
	draw_rect(Rect2(-9, -4, 18, 17), robe)
	draw_circle(Vector2(0, -10), 8.0, skin)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-8, -13), Vector2(8, -13), Vector2(6, -20), Vector2(-6, -20)]),
		hair
	)

	if player_nearby:
		draw_circle(Vector2(0, -32), 3.0, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(0, -32), 2.2, Color(1.0, 0.9, 0.2))


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		player_nearby = true
		player_nearby_changed.emit(true)
		queue_redraw()


func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		player_nearby = false
		player_nearby_changed.emit(false)
		queue_redraw()
