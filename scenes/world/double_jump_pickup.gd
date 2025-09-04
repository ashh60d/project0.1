extends Area2D
func _ready() -> void:
	body_entered.connect(_on_enter)
func _on_enter(body: Node) -> void:
	if body.name == "Player":
		Skills.add(Skills.Ability.DOUBLE_JUMP)
		queue_free()
