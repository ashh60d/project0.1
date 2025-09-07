extends Node
class_name Jump

@export var jump_force: float = 420.0
@export var gravity: float = 1300.0
@export var coyote_time: float = 0.12
@export var jump_buffer: float = 0.12
@export var cut_jump_factor: float = 0.5
@export var max_air_jumps: int = 1

@onready var actor: CharacterBody2D = get_parent()
@onready var dash: Node = actor.get_node_or_null("Dash")

var _coyote := 0.0
var _buffer := 0.0
var _air_left := 0
var _was_on_floor := false

func _ready() -> void:
	_recharge_air_jumps()  # ← ahora respeta si NO tenés la habilidad

func tick(delta: float) -> void:
	var on_floor := actor.is_on_floor()

	_coyote = coyote_time if on_floor else max(_coyote - delta, 0.0)
	_buffer = max(_buffer - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_buffer = jump_buffer

	if not on_floor and not (dash and dash.active):
		actor.velocity.y += gravity * delta

	var want := _buffer > 0.0

	# Salto desde suelo (recarga saltos aéreos según Skills)
	if want and (_coyote > 0.0 or on_floor) and not (dash and dash.active):
		actor.velocity.y = -jump_force
		_buffer = 0.0
		_coyote = 0.0
		_recharge_air_jumps()
	# Salto aéreo (solo si tenés la habilidad y quedan)
	elif want and not on_floor and _air_left > 0 and not (dash and dash.active):
		actor.velocity.y = -jump_force
		_buffer = 0.0
		_air_left -= 1

	# Salto variable
	if not Input.is_action_pressed("jump") and actor.velocity.y < 0.0:
		actor.velocity.y *= cut_jump_factor

	# Al aterrizar, recargar según Skills
	if on_floor and not _was_on_floor:
		_recharge_air_jumps()
	_was_on_floor = on_floor


# === Helpers ===
func _has_double_jump() -> bool:
	# Asume que "Skills" es un Autoload. Si no existiera, devuelve false.
	return (typeof(Skills) == TYPE_OBJECT
		and Skills.has(Skills.Ability.DOUBLE_JUMP))

func _recharge_air_jumps() -> void:
	_air_left = (max_air_jumps if _has_double_jump() else 0)
