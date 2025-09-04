extends CanvasLayer
@onready var label: Label = $Label

func set_health(current: float, max_hp: int) -> void:
	label.text = "HP: %.1f/%d" % [current, max_hp]
