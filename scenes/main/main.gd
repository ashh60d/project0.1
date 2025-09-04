extends Node2D

func _ready() -> void:
	await get_tree().process_frame   # asegura que el HUD ya inicializó su Label
	$Player.health_changed.connect($HUD.set_health)
	$HUD.set_health($Player.hp, $Player.max_hp)
