extends Node
class_name Dash

@export var dash_speed: float = 480.0
@export var dash_min_time: float = 0.06
@export var dash_max_time: float = 0.20
@export var dash_cooldown: float = 0.25

@onready var actor: CharacterBody2D = get_parent()
@onready var defense: Node = actor.get_node_or_null("Defense")
@onready var combat: Node = actor.get_node_or_null("Combat")

var active := false
var _timer := 0.0
var _cd := 0.0
var _dir := 1.0

func cancel() -> void:
	active = false

func tick(delta: float) -> bool:
	_cd = max(_cd - delta, 0.0)

	if not active and (combat == null or combat.stun_timer <= 0.0) and (defense == null or not defense.is_blocking) and Input.is_action_just_pressed("dash") and _cd <= 0.0:
		var x_in := Input.get_axis("move_left", "move_right")
		if is_equal_approx(x_in, 0.0):
			_dir = float(actor.facing)
		else:
			_dir = 1.0 if x_in > 0.0 else -1.0
			actor.facing = int(_dir)
		active = true
		_timer = 0.0

	if active:
		_timer += delta
		actor.velocity.y = 0.0
		actor.velocity.x = _dir * dash_speed

		var stop_early := (not Input.is_action_pressed("dash")) and _timer >= dash_min_time
		var stop_max := _timer >= dash_max_time
		if stop_early or stop_max:
			active = false
			_cd = dash_cooldown
		return true

	return false
