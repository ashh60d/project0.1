extends Node
class_name Movement

@export var speed: float = 200.0

@onready var actor: CharacterBody2D = get_parent()
@onready var defense: Node = actor.get_node_or_null("Defense")
@onready var combat: Node = actor.get_node_or_null("Combat")

func tick(delta: float) -> void:
	var x := Input.get_axis("move_left", "move_right")
	if combat and combat.stun_timer > 0.0:
		var decel := 800.0
		actor.velocity.x = move_toward(actor.velocity.x, 0.0, decel * delta)
		return

	if x != 0.0:
		actor.facing = 1 if x > 0.0 else -1

	var mul := 1.0
	if defense and defense.is_blocking:
		mul = defense.block_movespeed_factor

	actor.velocity.x = x * speed * mul
