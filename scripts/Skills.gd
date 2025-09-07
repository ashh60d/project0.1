extends Node
class_name skills

enum Ability { DOUBLE_JUMP, DASH, PARRY }

var abilities: Dictionary[Ability, bool] = {}

func _ready() -> void:
	abilities.clear()

func has(ability: Ability) -> bool:
	return abilities.has(ability)

func add(ability: Ability) -> void:
	abilities[ability] = true
	print("Skill learned:", ability)

func remove(ability: Ability) -> void:
	if abilities.has(ability):
		abilities.erase(ability)
		print("Skill lost:", ability)
