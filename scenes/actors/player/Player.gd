extends CharacterBody2D

signal health_changed(current: int, max: int)

@export var max_hp: int = 5
@export var invuln_time: float = 0.6
var hp: int = 0
var _invuln_timer: float = 0.0

# Knockback / stun
@export var knockback_force: float = 320.0
@export var knockback_upward: float = 220.0
@export var hurt_stun_time: float = 0.18
var _stun_timer: float = 0.0

# ===== Tunables =====
@export var speed: float = 200.0
@export var jump_force: float = 420.0
@export var gravity: float = 1300.0
@export var coyote_time: float = 0.12
@export var jump_buffer: float = 0.12
@export var cut_jump_factor: float = 0.5
@export var max_air_jumps: int = 1

# ===== Internos =====
var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0
var _air_jumps_left: int = 0
var _was_on_floor: bool = false

func _ready() -> void:
	if has_node("Camera2D"):
		$Camera2D.make_current()
	_reset_air_jumps()
	hp = max_hp   # (no emitimos aquí; Main inicializa el HUD una vez)

func _physics_process(delta: float) -> void:
	# --- Timers ---
	var on_floor_now := is_on_floor()
	if on_floor_now:
		_coyote_timer = coyote_time
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)

	_buffer_timer = max(_buffer_timer - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_buffer_timer = jump_buffer

	# tick de invulnerabilidad + stun
	_invuln_timer = max(_invuln_timer - delta, 0.0)
	_stun_timer = max(_stun_timer - delta, 0.0)

	# --- Gravedad ---
	if not on_floor_now:
		velocity.y += gravity * delta

	# --- Intento de salto: buffer + coyote + doble salto ---
	var want_jump := _buffer_timer > 0.0
	if want_jump and (_coyote_timer > 0.0 or on_floor_now):
		velocity.y = -jump_force
		_buffer_timer = 0.0
		_coyote_timer = 0.0
		_reset_air_jumps()
	elif want_jump and not on_floor_now and _air_jumps_left > 0:
		velocity.y = -jump_force
		_buffer_timer = 0.0
		_air_jumps_left -= 1

	# --- Salto variable ---
	if not Input.is_action_pressed("jump") and velocity.y < 0.0:
		velocity.y *= cut_jump_factor

	# --- Movimiento horizontal ---
	if _stun_timer > 0.0:
		# Mantener el knockback y frenarlo suavemente (no pisar velocity.x)
		var decel := 800.0  # probá 600–1200
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)
	else:
		var x := Input.get_axis("move_left", "move_right")
		velocity.x = x * speed

	move_and_slide()

	# Aterrizaje: recargar saltos aéreos
	if on_floor_now and not _was_on_floor:
		_reset_air_jumps()
	_was_on_floor = on_floor_now

func _reset_air_jumps() -> void:
	if Engine.has_singleton("Skills") or (typeof(Skills) == TYPE_OBJECT):
		_air_jumps_left = max_air_jumps if Skills.has(Skills.Ability.DOUBLE_JUMP) else 0
	else:
		_air_jumps_left = 0

# ===== Daño / Muerte =====
func take_damage(amount: int, from_pos: Vector2 = global_position) -> void:
	if _invuln_timer > 0.0:
		return

	hp = max(hp - amount, 0)
	_invuln_timer = invuln_time
	_stun_timer = hurt_stun_time

	# Knockback: empuja alejando del origen del golpe
	var dir: float = 1.0 if global_position.x >= from_pos.x else -1.0
	velocity.x = dir * knockback_force
	velocity.y = -knockback_upward

	health_changed.emit(hp, max_hp)
	_flash()
	if hp == 0:
		_die()

func _flash() -> void:
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1, 0.7, 0.7)
		await get_tree().create_timer(0.08).timeout
		$Sprite2D.modulate = Color(1, 1, 1)

func _die() -> void:
	# Respawn simple
	global_position.y = -100
	global_position.x = 0
	hp = max_hp
	health_changed.emit(hp, max_hp)
