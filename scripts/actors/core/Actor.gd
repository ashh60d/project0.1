# res://scripts/actors/Actor.gd
extends CharacterBody2D
class_name Actor

signal health_changed(current: float, max: int)

# Dirección de cara compartida por los módulos (1 = derecha, -1 = izquierda)
var facing: int = 1

# Referencias tipadas a los módulos (deben existir como hijos con esos nombres)
@onready var Movement: Movement = $Movement
@onready var Jump: Jump = $Jump
@onready var Dash: Dash = $Dash
@onready var Defense: Defense = $Defense
@onready var Attack: Attack = $Attack
@onready var Combat: Combat = $Combat

func _physics_process(delta: float) -> void:
	# 1) Defensa: parry/block actualiza flags de bloqueo
	Defense.tick(delta)

	# 2) Dash: si está activo, consume el frame de movimiento y salimos
	#    (Dash.tick debe devolver true cuando “se llevó” el movimiento)
	if Dash.tick(delta):
		move_and_slide()
		return

	# 3) Movimiento + Salto (aplican a velocity.x / velocity.y)
	Movement.tick(delta)
	Jump.tick(delta)

	# 4) Ataque (activa/desactiva hitbox, aplica daño)
	Attack.tick(delta)

	# 5) Combat: timers (invuln, stun), muerte, etc.
	Combat.tick(delta)

	# 6) Aplicar física
	move_and_slide()

# API mínima que delega en Combat (para que otros puedan dañar al Actor)
func take_damage(amount: int, from_pos: Vector2 = global_position) -> void:
	Combat.take_damage(amount, from_pos)

# Llamado por Combat cuando corresponde (respawn simple)
func _die() -> void:
	global_position.y = -100
	Combat.reset_health()
