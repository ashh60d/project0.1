extends Node

enum Ability { DOUBLE_JUMP, DASH, PARRY }

var abilities: = {}

func _ready() -> void:
	abilities.clear()

func has(ability: Ability) -> bool:
	return ability in abilities

func add(ability: Ability) -> void:
	abilities[ability] = true
	print("Skill learned:", ability)

func remove(ability: Ability) -> void:
	if ability in abilities:
		abilities.erase(ability)
		print("Skill lost:", ability)
