extends CharacterBody2D

@export var max_hp: int = 3
@export var touch_damage: int = 1
@export var gravity: float = 1300.0
@export var kb_force: float = 220.0
@export var kb_up: float = 120.0

# ↓ NUEVO: fricción en suelo y aire, y duración del golpe
@export var ground_friction: float = 2000.0
@export var air_drag: float = 200.0
@export var hurt_time: float = 0.15

var hp: int
var _hurt_timer: float = 0.0

func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	$DamageArea.body_entered.connect(_on_damage_area_body_entered)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	# ↓ NUEVO: desaceleración horizontal para que no se deslice infinito
	var decel := ground_friction if is_on_floor() else air_drag
	velocity.x = move_toward(velocity.x, 0.0, decel * delta)

	_hurt_timer = maxf(_hurt_timer - delta, 0.0)  # (opcional, por si después usás “stun”)
	move_and_slide()

func _on_damage_area_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(touch_damage, global_position)

# Llamado por el Player al golpear
func take_damage(amount: int, from_pos: Vector2) -> void:
	hp = max(hp - amount, 0)
	_hurt_timer = hurt_time

	# Knockback con “saltito”
	var dir: float = 1.0 if global_position.x >= from_pos.x else -1.0
	velocity.x = dir * kb_force
	velocity.y = -kb_up

	if hp == 0:
		queue_free()
