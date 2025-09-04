extends CharacterBody2D

signal health_changed(current: float, max: int)

@export var max_hp: int = 5
@export var invuln_time: float = 0.6
var hp: float = 0.0
var _invuln_timer: float = 0.0

var _facing: int = 1  # 1 = derecha, -1 = izquierda

# Knockback / stun
@export var knockback_force: float = 320.0
@export var knockback_upward: float = 220.0
@export var hurt_stun_time: float = 0.18
var _stun_timer: float = 0.0

# ===== Movement tunables =====
@export var speed: float = 200.0
@export var jump_force: float = 420.0
@export var gravity: float = 1300.0
@export var coyote_time: float = 0.12
@export var jump_buffer: float = 0.12
@export var cut_jump_factor: float = 0.5
@export var max_air_jumps: int = 1

# ===== Block / Parry =====
@export var parry_window: float = 0.12
@export var block_movespeed_factor: float = 0.35
@export var block_kb_scale: float = 0.3
var _is_blocking: bool = false
var _parry_timer: float = 0.0

# ===== Dash (hold-to-extend) =====
@export var dash_speed: float = 480.0
@export var dash_min_time: float = 0.06
@export var dash_max_time: float = 0.20
@export var dash_cooldown: float = 0.25
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cd: float = 0.0
var _dash_dir: float = 1.0

# ===== Attack (config) =====
@export var attack_damage: int = 1
@export var attack_windup: float = 0.06   # preparación
@export var attack_active: float = 0.08   # ventana que pega
@export var attack_recovery: float = 0.12 # salida
@export var attack_offset_x: float = 16.0 # distancia de la hitbox frente al player

# ===== Attack (estado) =====
enum AttackState { IDLE, WINDUP, ACTIVE, RECOVERY }
var _attack_state: AttackState = AttackState.IDLE
var _attack_timer: float = 0.0
var _already_hit := {}  # evita golpear dos veces el mismo body por swing

@onready var _attack_pivot: Node2D = $AttackPivot
@onready var _hitbox: Area2D = $AttackPivot/Hitbox

# ===== Internos =====
var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0
var _air_jumps_left: int = 0
var _was_on_floor: bool = false

func _ready() -> void:
	if has_node("Camera2D"):
		$Camera2D.make_current()
	_reset_air_jumps()
	hp = float(max_hp)  # HUD se inicializa desde Main
	if is_instance_valid(_hitbox):
		_hitbox.monitoring = false

func _physics_process(delta: float) -> void:
	# --- Timers base ---
	var on_floor_now := is_on_floor()
	if on_floor_now:
		_coyote_timer = coyote_time
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)

	_buffer_timer = max(_buffer_timer - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_buffer_timer = jump_buffer

	_invuln_timer = max(_invuln_timer - delta, 0.0)
	_stun_timer = max(_stun_timer - delta, 0.0)

	# --- Block / Parry input ---
	if Input.is_action_just_pressed("block"):
		_is_blocking = true
		_parry_timer = parry_window
	elif Input.is_action_just_released("block"):
		_is_blocking = false
	_parry_timer = max(_parry_timer - delta, 0.0)

	# --- Posicionar hitbox frente al player (si existe) ---
	if is_instance_valid(_attack_pivot):
		_attack_pivot.position.x = attack_offset_x * float(_facing)

	# --- Dash control ---
	_dash_cd = max(_dash_cd - delta, 0.0)
	if not _is_dashing and _stun_timer <= 0.0 and not _is_blocking and Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
		var x_in := Input.get_axis("move_left", "move_right")
		if x_in == 0.0:
			_dash_dir = float(_facing)   # usa última dirección conocida
		else:
			_dash_dir = 1.0 if x_in > 0.0 else -1.0
			_facing = int(_dash_dir)     # opcional: actualizar facing
		_is_dashing = true
		_dash_timer = 0.0

	if _is_dashing:
		_dash_timer += delta
		velocity.y = 0.0
		velocity.x = _dash_dir * dash_speed

		var stop_early := not Input.is_action_pressed("dash") and _dash_timer >= dash_min_time
		var stop_max := _dash_timer >= dash_max_time
		if stop_early or stop_max:
			_is_dashing = false
			_dash_cd = dash_cooldown

		move_and_slide()
		_was_on_floor = on_floor_now
		return

	# --- Input de ataque (no atacar si stuneado/dashing/bloqueando) ---
	if _attack_state == AttackState.IDLE and _stun_timer <= 0.0 and not _is_dashing and not _is_blocking and Input.is_action_just_pressed("attack"):
		_start_attack()

	# --- Gravedad (si no dashing) ---
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
		var decel := 800.0
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)
	else:
		var x := Input.get_axis("move_left", "move_right")
		if x != 0.0:
			_facing = 1 if x > 0.0 else -1
		var speed_mul := (block_movespeed_factor if _is_blocking else 1.0)
		velocity.x = x * speed * speed_mul

	# --- Timeline del ataque ---
	_update_attack(delta)

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

# ===== Ataque =====
func _start_attack() -> void:
	_attack_state = AttackState.WINDUP
	_attack_timer = attack_windup
	if is_instance_valid(_hitbox):
		_hitbox.set_deferred("monitoring", false)
	_already_hit.clear()

func _update_attack(delta: float) -> void:
	if _attack_state == AttackState.IDLE:
		return

	_attack_timer -= delta

	match _attack_state:
		AttackState.WINDUP:
			if _attack_timer <= 0.0:
				_attack_state = AttackState.ACTIVE
				_attack_timer = attack_active
				if is_instance_valid(_hitbox):
					_hitbox.set_deferred("monitoring", true)
				_already_hit.clear()

		AttackState.ACTIVE:
			if _attack_timer <= 0.0:
				_attack_state = AttackState.RECOVERY
				_attack_timer = attack_recovery
				if is_instance_valid(_hitbox):
					_hitbox.set_deferred("monitoring", false)

		AttackState.RECOVERY:
			if _attack_timer <= 0.0:
				_attack_state = AttackState.IDLE
				if is_instance_valid(_hitbox):
					_hitbox.set_deferred("monitoring", false)

# Señal: Hitbox.body_entered
func _on_hitbox_body_entered(body: Node2D) -> void:
	# Solo durante ACTIVE y evitar múltiple hit al mismo cuerpo
	if _attack_state != AttackState.ACTIVE:
		return
	if body in _already_hit:
		return
	_already_hit[body] = true

	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(attack_damage, global_position)

# ===== Daño / Muerte =====
func take_damage(amount: int, from_pos: Vector2 = global_position) -> void:
	_is_dashing = false
	if _invuln_timer > 0.0:
		return

	# Parry
	if _is_blocking and _parry_timer > 0.0:
		_invuln_timer = 0.2
		_stun_timer = 0.0
		_flash()
		health_changed.emit(hp, max_hp)
		return

	# Block
	if _is_blocking:
		var dmg: float = amount * 0.5
		hp = max(hp - dmg, 0.0)
		_invuln_timer = invuln_time
		_stun_timer = hurt_stun_time * 0.5

		var dir: float = 1.0 if global_position.x >= from_pos.x else -1.0
		velocity.x = dir * knockback_force * block_kb_scale
		velocity.y = -knockback_upward * block_kb_scale

		health_changed.emit(hp, max_hp)
		_flash()
		if hp <= 0.0:
			_die()
		return

	# Daño normal
	hp = max(hp - float(amount), 0.0)
	_invuln_timer = invuln_time
	_stun_timer = hurt_stun_time

	var dir2: float = 1.0 if global_position.x >= from_pos.x else -1.0
	velocity.x = dir2 * knockback_force
	velocity.y = -knockback_upward

	health_changed.emit(hp, max_hp)
	_flash()
	if hp <= 0.0:
		_die()

func _flash() -> void:
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1, 0.7, 0.7)
		await get_tree().create_timer(0.08).timeout
		$Sprite2D.modulate = Color(1, 1, 1)

func _die() -> void:
	global_position.y = -100
	hp = float(max_hp)
	health_changed.emit(hp, max_hp)
