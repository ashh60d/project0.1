# res://scripts/actors/Player.gd
extends Actor
class_name Player

@onready var cam: Camera2D = $Camera2D

func _ready() -> void:
	add_to_group("player")
	if cam:
		cam.make_current()
