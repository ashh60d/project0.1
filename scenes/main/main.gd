extends Node2D
class_name Main

@onready var player: Actor = $Player     # Player extiende Actor
@onready var hud: HUD = $HUD             # Asegurate de poner `class_name HUD` en hud.gd

func _ready() -> void:
	await get_tree().process_frame
	if not player.health_changed.is_connected(hud.set_health):
		player.health_changed.connect(hud.set_health)

	# Valor inicial (lo emite Combat en su _ready, pero lo seteamos igual por las dudas)
	hud.set_health(player.Combat.hp, player.Combat.max_hp)
