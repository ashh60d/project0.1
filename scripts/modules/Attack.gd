extends Node
class_name Attack

@export var damage: int = 1
@export var windup: float = 0.06
@export var active_time: float = 0.08
@export var recovery: float = 0.12
@export var offset_x: float = 16.0

@onready var actor: CharacterBody2D = get_parent() as CharacterBody2D
@onready var defense: Node = actor.get_node_or_null("Defense")
@onready var dash: Node = actor.get_node_or_null("Dash")
@onready var combat: Node = actor.get_node_or_null("Combat")
@onready var pivot: Node2D = actor.get_node("AttackPivot") as Node2D
@onready var hitbox: Area2D = pivot.get_node("Hitbox") as Area2D

enum State { IDLE, WINDUP, ACTIVE, RECOVERY }
var _state: State = State.IDLE
var _t: float = 0.0
var _already: Dictionary = {}   # cuerpos ya golpeados durante esta ventana

func _ready() -> void:
	if hitbox:
		hitbox.monitoring = false
		var cb := Callable(self, "_on_hitbox_body_entered")
		if not hitbox.body_entered.is_connected(cb):
			hitbox.body_entered.connect(cb)

func tick(delta: float) -> void:
	# mantener hitbox delante del actor
	if pivot:
		pivot.position.x = offset_x * float(actor.facing)

	# --- estado externo que puede cancelar o impedir el ataque ---
	var is_stunned: bool = false
	if combat:
		is_stunned = combat.stun_timer > 0.0

	var is_dashing: bool = false
	if dash:
		is_dashing = dash.active

	var is_blocking: bool = false
	if defense:
		is_blocking = defense.is_blocking


	# Si algo “rompe” el ataque en curso, cancelar
	if _state != State.IDLE and (is_stunned or is_dashing or is_blocking):
		interrupt()
		return

	# Inicio de ataque
	if _state == State.IDLE and not is_stunned and not is_dashing and not is_blocking and Input.is_action_just_pressed("attack"):
		_state = State.WINDUP
		_t = windup
		if hitbox: hitbox.set_deferred("monitoring", false)
		_already.clear()

	if _state == State.IDLE:
		return

	_t -= delta
	match _state:
		State.WINDUP:
			if _t <= 0.0:
				_state = State.ACTIVE
				_t = active_time
				if hitbox: hitbox.set_deferred("monitoring", true)
				_already.clear()
		State.ACTIVE:
			if _t <= 0.0:
				_state = State.RECOVERY
				_t = recovery
				if hitbox: hitbox.set_deferred("monitoring", false)
		State.RECOVERY:
			if _t <= 0.0:
				_state = State.IDLE
				if hitbox: hitbox.set_deferred("monitoring", false)

func interrupt() -> void:
	_state = State.IDLE
	_t = 0.0
	_already.clear()
	if hitbox:
		hitbox.set_deferred("monitoring", false)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if _state != State.ACTIVE:
		return
	if body in _already:
		return
	_already[body] = true

	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage, actor.global_position)
