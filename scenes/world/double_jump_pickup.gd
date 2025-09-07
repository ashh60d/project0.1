extends Area2D
class_name DoubleJumpPickup

@export var ability: Skills.Ability = Skills.Ability.DOUBLE_JUMP
@export var one_shot: bool = true

func _ready() -> void:
	body_entered.connect(_on_enter)

func _on_enter(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# Evitar duplicados y ser prolijos al otorgar
	if not Skills.has(ability):
		Skills.add(ability)

	if one_shot:
		# Desactivar por si hay varios cuerpos entrando este frame
		set_deferred("monitoring", false)
		queue_free()
