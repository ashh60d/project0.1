extends CanvasLayer
class_name HUD

@onready var label: Label = $Label as Label

func set_health(current: float, max_hp: int) -> void:
	if not label:
		return
	label.text = "HP: %s/%d" % [("%.1f" % current), max_hp]
