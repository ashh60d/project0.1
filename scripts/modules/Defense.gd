extends Node
class_name Defense

@export var parry_window: float = 0.12
@export var block_movespeed_factor: float = 0.35
@export var block_kb_scale: float = 0.3

var is_blocking := false
var _parry_timer := 0.0

func in_parry_window() -> bool:
	return is_blocking and _parry_timer > 0.0

func tick(delta: float) -> void:
	if Input.is_action_just_pressed("block"):
		is_blocking = true
		_parry_timer = parry_window
	elif Input.is_action_just_released("block"):
		is_blocking = false
	_parry_timer = max(_parry_timer - delta, 0.0)
