extends CanvasLayer
@onready var label: Label = $Label

func set_health(current: int, max_hp: int) -> void:
	label.text = "HP: %d/%d" % [current, max_hp]
