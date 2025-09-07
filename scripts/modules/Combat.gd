extends Node
class_name Combat

@export var max_hp: int = 5
@export var invuln_time: float = 0.6
@export var hurt_stun_time: float = 0.18
@export var knockback_force: float = 320.0
@export var knockback_upward: float = 220.0

@onready var actor: CharacterBody2D = get_parent()
@onready var defense = actor.get_node_or_null("Defense")
@onready var dash = actor.get_node_or_null("Dash")

var hp: float
var invuln_timer := 0.0
var stun_timer := 0.0

func _ready() -> void:
	hp = float(max_hp)
	if actor.has_signal("health_changed"):
		actor.emit_signal("health_changed", hp, max_hp)

func tick(delta: float) -> void:
	invuln_timer = max(invuln_timer - delta, 0.0)
	stun_timer = max(stun_timer - delta, 0.0)

func take_damage(amount: int, from_pos: Vector2 = actor.global_position) -> void:
	if dash: dash.cancel()
	if invuln_timer > 0.0:
		return

	# Parry
	if defense and defense.in_parry_window():
		invuln_timer = 0.2
		stun_timer = 0.0
		if actor.has_signal("health_changed"):
			actor.emit_signal("health_changed", hp, max_hp)
		return

	# Block
	if defense and defense.is_blocking:
		var dmg: float = amount * 0.5
		hp = max(hp - dmg, 0.0)
		invuln_timer = invuln_time
		stun_timer = hurt_stun_time * 0.5
		var dir: float = 1.0 if actor.global_position.x >= from_pos.x else -1.0
		actor.velocity.x = dir * knockback_force * defense.block_kb_scale
		actor.velocity.y = -knockback_upward * defense.block_kb_scale
		if actor.has_signal("health_changed"):
			actor.emit_signal("health_changed", hp, max_hp)
		if hp <= 0.0:
			actor.call_deferred("_die")
		return

	# Daño normal
	hp = max(hp - float(amount), 0.0)
	invuln_timer = invuln_time
	stun_timer = hurt_stun_time
	var dir2: float = 1.0 if actor.global_position.x >= from_pos.x else -1.0
	actor.velocity.x = dir2 * knockback_force
	actor.velocity.y = -knockback_upward
	if actor.has_signal("health_changed"):
		actor.emit_signal("health_changed", hp, max_hp)
	if hp <= 0.0:
		actor.call_deferred("_die")

func reset_health() -> void:
	hp = float(max_hp)
	invuln_timer = 0.0
	stun_timer = 0.0
	if actor.has_signal("health_changed"):
		actor.emit_signal("health_changed", hp, max_hp)
